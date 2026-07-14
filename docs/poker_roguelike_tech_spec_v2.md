# 西游扑克 Roguelike 游戏——后端技术方案（Demo 版）

> 版本：v2.0 | 日期：2026-07-07 | 状态：Demo 阶段 | 定位：后端接口开发
>
> **v2.0 变更说明**：基于 v1.1 进行西游记主题本土化改造。核心玩法不变（3轮×3回合、扑克出牌算分、商店+法宝、排行榜），但将小丑牌/道具体系替换为西游记法宝/仙丹体系，小盲/大盲/Boss 替换为小兵/精英怪/大妖关卡，过关分数改为怪物血条、得分改为伤害。新增大妖技能系统（如黄风怪的风沙走石遮挡手牌）。

---

## 第0章 架构总览

### 0.1 系统架构图

```mermaid
graph TB
    subgraph 用户侧
        Client[Client<br/>游戏客户端]
    end

    subgraph 服务端
        Gateway[API Gateway<br/>JWT鉴权 / 限流]
        subgraph Spring Boot 3
            GameAPI[GameController<br/>出牌提交 / 局管理]
            ShopAPI[ShopController<br/>仙铺查询 / 购买]
            RankAPI[RankController<br/>全服榜 / 好友榜]
            RewardAPI[RewardController<br/>奖品兑换]
            AdCallback[AdCallbackController<br/>广告S2S回调]
        end
        subgraph 游戏逻辑
            HandEval[HandEvaluator<br/>牌型识别]
            ScoreCalc[DamageCalculator<br/>伤害计算]
            ScoreVerify[ScoreVerifyService<br/>反作弊校验]
            BossSkill[BossSkillEngine<br/>大妖技能引擎]
        end
        subgraph 存储
            SQLite[(SQLite<br/>单文件数据库<br/>局记录/出牌日志/奖品)]
            InMem[In-Memory Cache<br/>ConcurrentHashMap/AtomicInteger<br/>排行榜/库存/Token缓存]
        end
    end

    Client -- HTTPS --> Gateway
    GameAPI --> HandEval
    GameAPI --> ScoreCalc
    GameAPI --> ScoreVerify
    GameAPI --> BossSkill
    ScoreVerify --> SQLite
    GameAPI --> InMem
    ShopAPI --> InMem
    RankAPI --> InMem
    RewardAPI --> SQLite
    RewardAPI --> InMem
    AdCallback --> SQLite
```

### 0.2 技术选型总表

| 层 | 技术 | 版本 | 说明 |
|---|---|---|---|
| 游戏引擎 | Godot | 4.3+ | GL Compatibility 模式，Web Export（前端独立开发） |
| 前后端通信 | HTTP REST | - | JSON 请求/响应，前后端解耦 |
| 后端框架 | Spring Boot | 3.2.x | Java 17+ |
| ORM | MyBatis-Plus | 3.5.7 | 单表 CRUD 自动化 |
| 关系库 | **SQLite** | 3.x | 单文件嵌入式数据库，Demo 阶段零运维 |
| 缓存 | **In-Memory** | - | ConcurrentHashMap / AtomicInteger 替代 Redis |
| 鉴权 | JWT | jjwt 0.12 | 无状态 Token，客户端注入 |

> **Demo 简化说明**：生产环境应使用 MySQL + Redis，Demo 阶段用 SQLite + 内存缓存降低运维成本。切换时仅需改数据源配置和缓存实现，接口层无需变动。
>
> **SQLite 并发约束**：SQLite 单进程写入串行，WAL 模式下支持并发读。Demo 阶段为单机单进程部署，写串行可接受。`SQLiteConfig` 初始化时配置 `PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;` 以启用 WAL 和 5s 写锁等待。适用并发用户约 ~50，超出此范围建议升级 MySQL。

### 0.3 数据流概览

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    
    C->>S: POST /api/game/start (Token)
    S->>S: 创建 session (SQLite) + 生成 rngSeed
    S-->>C: {sessionId, rngSeed, roundConfig, bossSkills}
    
    loop 每次出牌
        C->>C: 本地算伤害（即时反馈）
        C->>S: POST /api/game/submit_play (牌面+法宝+快照)
        S->>S: 服务端重算校验
        S->>S: 写出牌日志 (SQLite)
        S-->>C: {verifiedDamage, totalDamage}
    end
    
    C->>S: POST /api/game/submit_result
    S->>S: 更新排行榜 (In-Memory) + 奖品判定 (SQLite)
    S-->>C: {totalDamage, rank, rewardTier}
```

### 0.4 西游记主题术语映射

| 原术语 | 新术语 | 说明 |
|--------|--------|------|
| 小盲（Small Blind） | 小兵（Minion） | 每轮第1回合，巡山小妖 |
| 大盲（Big Blind） | 精英怪（Elite） | 每轮第2回合，精英妖怪 |
| Boss | 大妖（Boss Demon） | 每轮第3回合，如白骨精、黄风怪等 |
| 小丑牌（Joker） | 法宝（Artifact） | 如芭蕉扇、紫金铃、人参果等 |
| 冲分道具（Consumable） | 仙丹/法术（Elixir） | 如九转还丹、定风丹、分身术等 |
| 游戏积分（Game Coins） | 灵石（Spirit Stones） | 局内货币，购买法宝/仙丹 |
| 通过分数（Threshold） | 怪物血条（HP Bar） | 需造成的伤害总量 |
| 得分（Score） | 伤害（Damage） | 每次出牌造成的伤害值 |
| 商店（Shop） | 仙铺（Fairy Shop） | 出售法宝和仙丹 |
| 暴击（Critical） | 神通（Divine Strike） | 概率触发高额伤害 |
| 复活（Revive） | 还魂（Resurrection） | 观看广告/邀请好友还魂续命 |

---

## 第1章 前端（Godot）—— 本文档不涉及

> **说明**：本版本聚焦后端接口开发，前端（Godot 4 + GDScript）由独立团队负责。
>
> 前端相关设计参见 v1.0 版本文档。以下为前端与后端的关键**协议约定**，后端开发需据此实现接口：
>
> | 约定项 | 说明 |
> |--------|------|
> | 通信方式 | HTTP REST (JSON)，后续可升级 WebSocket |
> | 鉴权 | Bearer JWT Token，请求头 `Authorization` |
> | 牌数据序列化 | `{"r": 1, "s": 0}` → r=rank(1-13), s=suit(0-3) |
> | 法宝 ID 对齐 | 前后端使用同一套 `item_id` 字符串（如 `artifact_bjs` 芭蕉扇） |
> | 伤害快照 | 前端提交 `snapshot` 字段，后端独立校验 |
>
> 详细的接口协议见第2章。

---

## 第2章 前后端通信协议

### 2.1 HTTP 请求通用规范

| Header | 值 | 说明 |
|--------|---|------|
| `Authorization` | `Bearer {JWT}` | 鉴权 Token |
| `Content-Type` | `application/json` | 请求体格式 |
| `X-Request-Id` | UUID | 请求追踪，防重放 |
| `X-Client-Version` | `1.0.0` | 客户端版本号 |

### 2.2 接口定义

#### 2.2.1 POST /api/game/start

**请求**：
```json
{ "client_version": "1.0.0" }
```

**响应**：
```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "session_id": 10001,
        "rng_seed": 739251846293,
        "round_config": {
            "hp_bars": [[300,800,1500],[1500,3000,5000],[3500,6000,10000]],
            "spirit_stone_rewards": [[30,50,80],[50,80,120],[80,120,180]],
            "max_resurrections": 3,
            "boss_skills": [
                {
                    "round": 0,
                    "boss_id": "demon_baigujing",
                    "boss_name": "白骨精",
                    "skill_id": "illusion",
                    "skill_name": "白骨幻术",
                    "skill_desc": "随机将2张手牌变为幻影牌（不可选），每回合重置"
                },
                {
                    "round": 1,
                    "boss_id": "demon_huangfeng",
                    "boss_name": "黄风怪",
                    "skill_id": "sandstorm",
                    "skill_name": "风沙走石",
                    "skill_desc": "随机遮挡3张手牌，需消耗换牌次数翻开"
                },
                {
                    "round": 2,
                    "boss_id": "demon_honghaier",
                    "boss_name": "红孩儿",
                    "skill_id": "samadhi_fire",
                    "skill_name": "三昧真火",
                    "skill_desc": "每回合随机指定2种牌型，只有该牌型可打出伤害，其余牌型伤害归零",
                    "skill_params": {"valid_hand_count": 2, "valid_hands": [4, 6]}
                }
            ]
        },
        "item_config": {
            "items": [
                {
                    "id": "artifact_bjs",
                    "display_name": "芭蕉扇",
                    "description": "每次出牌掀起罡风，固定增加倍率",
                    "price": 30,
                    "rarity": 0,
                    "item_type": 0,
                    "shop_weights": [30,25,20,15,10,5],
                    "upgrade_costs": [40,80],
                    "effect_class": "BaJiaoShan",
                    "level_params": [
                        {"mult_add":4},
                        {"mult_add":7},
                        {"mult_add":11}
                    ]
                }
            ]
        },
        "reward_config": [
            {"min_damage":0,"max_damage":999,"reward_name":"参与奖","reward_type":"digital"},
            {"min_damage":1000,"max_damage":2999,"reward_name":"雪碧","reward_type":"drink"},
            {"min_damage":3000,"max_damage":5999,"reward_name":"奶茶","reward_type":"drink"},
            {"min_damage":6000,"max_damage":9999,"reward_name":"奶茶升级券","reward_type":"coupon"},
            {"min_damage":10000,"max_damage":-1,"reward_name":"稀有奖品","reward_type":"rare"}
        ]
    }
}
```

> **大妖技能说明**：
> - `boss_skills` 数组长度=3，对应3轮的大妖关卡
> - 前端在每轮第3回合（大妖关）激活对应技能效果
> - 技能效果由前端本地执行（遮挡手牌、幻影牌等），后端不参与技能判定
> - `skill_id` 是前端分发技能效果的 key，具体实现由前端负责
> - 当前3个技能设计：
>   - **白骨幻术（illusion）**：白骨精施展幻术，随机2张手牌变为幻影牌（灰色、不可选中出牌），每回合重新随机
>   - **风沙走石（sandstorm）**：黄风怪刮起风沙，随机遮挡3张手牌（背面朝上），需消耗1次换牌操作才能翻开
>   - **三昧真火（samadhi_fire）**：红孩儿释放三昧真火，每回合随机指定2种牌型，只有该牌型可打出伤害，其余牌型伤害归零

#### 2.2.2 POST /api/game/submit_play

**请求**：
```json
{
    "session_id": 10001,
    "round": 0,
    "stage": 1,
    "play_idx": 2,
    "cards": [{"r":1,"s":0},{"r":10,"s":1},{"r":11,"s":2},{"r":12,"s":3},{"r":13,"s":0}],
    "elixirs": ["elixir_luck_spark","elixir_double"],
    "snapshot": {
        "hand_rank": 4,
        "base_damage": 450,
        "mult": 2.0,
        "is_divine": true,
        "divine_mult": 2.5,
        "special_mult": 1.0
    },
    "claimed": 2250
}
```

> 字段变更说明：`blind` → `stage`（0=小兵 1=精英怪 2=大妖），`consumables` → `elixirs`，`is_crit` → `is_divine`，`crit_mult` → `divine_mult`

**响应**：
```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "verified_damage": 2250,
        "total_damage": 4300,
        "is_divine": true
    }
}
```

#### 2.2.3 POST /api/game/submit_result

> 说明：每次出牌已通过 `submit_play` 实时上报并持久化到 `play_log` 表，`submit_result` 只需 `session_id` 即可，服务端从 DB 聚合计算最终伤害。

**请求**：
```json
{
    "session_id": 10001
}
```

**响应**：
```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "total_damage": 8500,
        "global_rank": 1234,
        "friend_rank": 5,
        "reward_tier": {"min_damage":6000,"max_damage":9999,"reward_name":"奶茶升级券","reward_type":"coupon"},
        "achievements": ["神通大师"]
    }
}
```

#### 2.2.4 POST /api/game/revive → POST /api/game/resurrect

**请求**：
```json
{
    "session_id": 10001,
    "resurrect_type": 0,
    "ad_token": "ad_cb_abc123def456"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `resurrect_type` | int | 0=观看广告 1=拉好友 |
| `ad_token` | String | resurrect_type=0 时必填 |
| `friend_uid` | String | resurrect_type=1 时必填 |

#### 2.2.5 GET /api/shop/list

| 参数 | 类型 | 说明 |
|------|------|------|
| `session_id` | long | 当前局 ID |
| `shop_node` | int | 仙铺节点 0-5 |
| `refresh_count` | int | 当前已刷新次数 |

#### 2.2.6 POST /api/shop/buy

```json
{
    "session_id": 10001,
    "shop_node": 0,
    "item_id": "artifact_bjs",
    "slot_index": 0
}
```

#### 2.2.7 GET /api/rank/global

| 参数 | 类型 | 说明 |
|------|------|------|
| `page` | int | 页码，从 1 开始 |
| `size` | int | 每页条数，默认 20 |

#### 2.2.8 GET /api/rank/friends

同全服榜格式，增加 `is_self` 字段。

#### 2.2.9 POST /api/reward/claim

```json
{ "session_id": 10001 }
```

#### 2.2.10 GET /api/health

健康检查接口，无需鉴权。

**响应**：
```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "status": "UP",
        "db": "OK",
        "cache_entries": 42
    }
}
```

#### 2.2.11 POST /api/ad/callback（广告平台→服务端 S2S）

```json
{
    "callback_token": "ad_cb_abc123def456",
    "user_id": "u_001",
    "ad_type": "rewarded_video",
    "scene": "resurrect",
    "trans_id": "tx_789",
    "timestamp": 1782834000,
    "sign": "hmac_sha256_signature"
}
```

### 2.3 数据结构约定

| 概念 | Java 字段 | JSON 协议字段 | 说明 |
|------|-----------|--------------|------|
| 法宝/仙丹 ID | `ItemDTO.id` | `id` | 完全一致，如 `artifact_bjs` |
| 道具类型 | `ItemDTO.itemType` | `item_type` | 0=法宝 1=仙丹 |
| 稀有度 | `ItemDTO.rarity` | `rarity` | 0=普通 1=稀有 |
| 商店权重 | `ItemDTO.shopWeights` | `shop_weights` | 6节点权重数组 |
| 效果类名 | `ItemDTO.effectClass` | `effect_class` | Java 反射加载 |
| 牌数据 | `CardDTO(rank, suit)` | `{"r":1,"s":0}` | r→rank(1-13)，s→suit(0-3) |
| 法宝状态 | `ArtifactStateDTO(id, level)` | `{id, level}` | 完全一致 |
| 关卡阶段 | `stage` | `stage` | 0=小兵 1=精英怪 2=大妖 |
| 大妖技能 | `BossSkillDTO` | `boss_skills[]` | 每轮一个大妖技能配置 |

### 2.4 错误码体系

| 错误码 | 常量名 | 说明 |
|--------|--------|------|
| 0 | SUCCESS | 成功 |
| 400 | PARAM_INVALID | 参数校验失败 |
| 401 | UNAUTHORIZED | Token 无效或过期 |
| 403 | FORBIDDEN | 无权限 |
| 1001 | SESSION_NOT_FOUND | 局记录不存在 |
| 1002 | SESSION_EXPIRED | 局已结束或超时 |
| 1003 | SESSION_USER_MISMATCH | 局不属于当前用户 |
| 1004 | RESURRECTION_LIMIT_EXCEEDED | 还魂次数耗尽 |
| 1005 | AD_TOKEN_INVALID | 广告回调 token 无效 |
| 1006 | AD_TOKEN_EXPIRED | 广告 token 已过期（5分钟） |
| 1007 | AD_TOKEN_USED | 广告 token 已被消费 |
| 1008 | FRIEND_UID_INVALID | 好友 UID 无效 |
| 2001 | DAMAGE_CHEAT_DETECTED | 伤害校验不通过 |
| 2002 | HAND_RANK_MISMATCH | 牌型不匹配 |
| 3001 | SPIRIT_STONES_INSUFFICIENT | 灵石不足 |
| 3002 | ITEM_NOT_AVAILABLE | 法宝/仙丹不可购买 |
| 3003 | ARTIFACT_ALREADY_OWNED | 法宝已拥有 |
| 4001 | REWARD_OUT_OF_STOCK | 奖品库存不足 |
| 4002 | REWARD_ALREADY_CLAIMED | 奖品已领取 |
| 4003 | REWARD_TIER_NOT_MATCHED | 伤害未达任何奖品档位 |
| 5001 | CONFIG_LOAD_FAILED | 远程配置加载失败 |
| 5002 | GOLD_INSUFFICIENT | 外部金币不足 |
| 9999 | INTERNAL_ERROR | 未知内部错误 |

---

## 第3章 后端详细设计

### 3.1 项目结构

```
poker-roguelike-server/
├── pom.xml
└── src/main/java/com/kuaishou/poker/
    ├── PokerApplication.java
    ├── controller/
    │   ├── GameController.java          # 局管理 / 出牌提交 / 结果提交
    │   ├── ShopController.java         # 仙铺查询 / 购买
    │   ├── RankController.java         # 全服榜 / 好友榜
    │   ├── RewardController.java       # 奖品兑换
    │   ├── WalletController.java       # 金币钱包
    │   └── AdCallbackController.java   # 广告 S2S 回调
    ├── service/
    │   ├── GameService.java           # 局生命周期管理
    │   ├── ScoreVerifyService.java     # 伤害校验（反作弊）
    │   ├── ShopService.java           # 仙铺逻辑
    │   ├── RankService.java           # 排行榜逻辑
    │   ├── RewardService.java         # 奖品逻辑
    │   ├── WalletService.java          # 金币钱包逻辑
    │   └── AdCallbackService.java      # 广告回调逻辑
    ├── domain/
    │   ├── entity/                    # 数据库实体
    │   │   ├── GameSession.java
    │   │   ├── PlayLog.java
    │   │   ├── RewardTier.java
    │   │   ├── RewardClaim.java
    │   │   ├── AdCallbackLog.java
    │   │   ├── UserWallet.java
    │   │   ├── GameConfig.java
    │   │   └── BossSkillConfig.java
    │   ├── dto/                        # 请求/响应 DTO
    │   │   ├── SubmitPlayRequest.java
    │   │   ├── StartGameResponse.java
    │   │   ├── ApiResult.java
    │   │   ├── ItemDTO.java
    │   │   ├── BossSkillDTO.java
    │   │   └── RankEntry.java
    │   └── enums/                      # 枚举常量
    │       ├── HandRank.java
    │       ├── SessionStatus.java
    │       ├── StageType.java           # MINION/ELITE/BOSS_DEMON
    │       ├── ResurrectType.java
    │       └── ErrorCode.java
    ├── game/                           # 纯游戏逻辑（无外部依赖）
    │   ├── HandEvaluator.java          # 牌型识别
    │   ├── DamageCalculator.java      # 伤害计算（原 ScoreCalculator）
    │   ├── model/
    │   │   ├── Card.java
    │   │   ├── HandResult.java
    │   │   ├── DamageResult.java       # 原 ScoreResult
    │   │   ├── PlaySnapshot.java
    │   │   └── ItemModifier.java
    │   └── registry/
    │       └── ItemModifierRegistry.java
    ├── mapper/                         # MyBatis-Plus Mapper
    │   ├── GameSessionMapper.java
    │   ├── PlayLogMapper.java
    │   ├── UserWalletMapper.java
    │   ├── BossSkillConfigMapper.java
    │   └── AdCallbackLogMapper.java
    ├── infrastructure/                # 基础设施层
    │   ├── cache/                      # 内存缓存（Demo 替代 Redis）
    │   │   ├── InMemoryLeaderboard.java
    │   │   ├── InMemoryTokenStore.java
    │   │   └── InMemoryStockStore.java
    │   └── anti_cheat/
    │       └── ScoreAuditLogger.java
    └── config/
        ├── SQLiteConfig.java          # SQLite 数据源配置（WAL + busy_timeout）
        ├── SecurityConfig.java        # JWT 安全配置
        └── GlobalExceptionHandler.java
```

> **分层说明**：
> - `controller` — 接口层，只做参数校验和调用 Service
> - `service` — 业务层，编排逻辑，不直接操作 DB
> - `mapper` — 数据访问层，MyBatis-Plus 自动化单表 CRUD
> - `game` — 纯游戏逻辑层，零外部依赖，方便单元测试
> - `infrastructure/cache` — 缓存层，接口抽象，Demo 用内存实现，生产可切换 Redis

### 3.2 牌型识别（Java，与 GDScript 算法一致）

```java
// game/HandEvaluator.java
public class HandEvaluator {

    public enum HandRank {
        HIGH_CARD(0, 50),
        ONE_PAIR(1, 100),
        TWO_PAIR(2, 180),
        THREE_OF_KIND(3, 300),
        STRAIGHT(4, 450),
        FLUSH(5, 600),
        FULL_HOUSE(6, 900),
        FOUR_OF_KIND(7, 1500),
        STRAIGHT_FLUSH(8, 2500);

        public final int code;
        public final int baseDamage;  // 原baseScore，语义改为基础伤害
        HandRank(int code, int baseDamage) { this.code = code; this.baseDamage = baseDamage; }
    }

    public static HandResult evaluate(List<Card> cards) {
        if (cards.size() != 5) throw new IllegalArgumentException("必须选 5 张牌");

        int[] ranks = cards.stream().mapToInt(Card::getRank).sorted().toArray();
        int[] suits = cards.stream().mapToInt(Card::getSuit).toArray();
        boolean flush = isFlush(suits);
        boolean straight = isStraight(ranks);
        int[] counts = countRanks(ranks);

        HandRank rank;
        if      (flush && straight)                                        rank = HandRank.STRAIGHT_FLUSH;
        else if (hasCount(counts, 4))                                      rank = HandRank.FOUR_OF_KIND;
        else if (hasCount(counts, 3) && hasCount(counts, 2))              rank = HandRank.FULL_HOUSE;
        else if (flush)                                                   rank = HandRank.FLUSH;
        else if (straight)                                                rank = HandRank.STRAIGHT;
        else if (hasCount(counts, 3))                                     rank = HandRank.THREE_OF_KIND;
        else if (countOf(counts, 2) == 2)                                 rank = HandRank.TWO_PAIR;
        else if (countOf(counts, 2) == 1)                                 rank = HandRank.ONE_PAIR;
        else                                                              rank = HandRank.HIGH_CARD;

        return HandResult.builder().handRank(rank).baseDamage(rank.baseDamage).build();
    }

    private static boolean isFlush(int[] suits) {
        return Arrays.stream(suits).allMatch(s -> s == suits[0]);
    }

    private static boolean isStraight(int[] sorted) {
        if (Arrays.equals(sorted, new int[]{1, 2, 3, 4, 5})) return true;
        if (Arrays.equals(sorted, new int[]{1, 10, 11, 12, 13})) return true;
        for (int i = 1; i < sorted.length; i++) {
            if (sorted[i] - sorted[i - 1] != 1) return false;
        }
        return true;
    }

    private static int[] countRanks(int[] ranks) {
        Map<Integer, Long> map = Arrays.stream(ranks).boxed()
                .collect(Collectors.groupingBy(r -> r, Collectors.counting()));
        return map.values().stream().mapToInt(Long::intValue).sorted().toArray();
    }

    private static boolean hasCount(int[] counts, int target) {
        return Arrays.stream(counts).anyMatch(c -> c == target);
    }

    private static long countOf(int[] counts, int target) {
        return Arrays.stream(counts).filter(c -> c == target).count();
    }
}
```

### 3.3 伤害计算与校验

```java
// game/DamageCalculator.java  (纯逻辑，零外部依赖)
public class DamageCalculator {

    /**
     * 计算出牌伤害
     * @param handResult  牌型识别结果
     * @param artifacts   当前拥有的法宝列表
     * @param elixirs     本次使用的仙丹ID列表
     * @param rngSeed     本次出牌的RNG子种子
     */
    public static DamageResult calculate(
            HandResult handResult,
            List<ArtifactState> artifacts,
            List<String> elixirs,
            long rngSeed) {

        Random rng = new Random(rngSeed);

        // 1. 基础伤害 = 牌型基础伤害 × 牌型倍率
        double mult = 1.0;
        int baseDamage = handResult.getBaseDamage();

        // 2. 法宝修饰
        for (ArtifactState artifact : artifacts) {
            ItemModifier mod = ItemModifierRegistry.getModifier(artifact.getId());
            if (mod != null) {
                mult = mod.applyMult(mult, artifact.getLevel(), rng);
                baseDamage = mod.applyScoreAdd(baseDamage, artifact.getLevel());
            }
        }

        // 3. 仙丹修饰
        for (String elixirId : elixirs) {
            ItemModifier mod = ItemModifierRegistry.getModifier(elixirId);
            if (mod != null) {
                mult = mod.applyMult(mult, 0, rng);
            }
        }

        // 4. 神通判定（基于 RNG）——原暴击
        double divineRate = 0.05;  // 基础5%
        double divineMult = 1.5;   // 基础1.5倍
        for (ArtifactState artifact : artifacts) {
            ItemModifier mod = ItemModifierRegistry.getModifier(artifact.getId());
            if (mod != null) {
                divineRate += mod.getCritRateAdd(artifact.getLevel());
                divineMult += mod.getCritMultAdd(artifact.getLevel());
            }
        }
        boolean isDivine = rng.nextDouble() < divineRate;
        if (isDivine) {
            mult *= divineMult;
        }

        // 5. 最终伤害 = 基础伤害 × 总倍率，取整
        int damage = (int) Math.round(baseDamage * mult);

        return DamageResult.builder()
                .damage(damage)
                .isDivine(isDivine)
                .mult(mult)
                .build();
    }
}
```

```java
// service/ScoreVerifyService.java
@Service
@Slf44
@RequiredArgsConstructor
public class ScoreVerifyService {

    private final GameSessionMapper sessionMapper;
    private final ScoreAuditLogger auditLogger;
    private static final int TOLERANCE = 1;

    public VerifyResult verify(SubmitPlayRequest req) {
        GameSession session = sessionMapper.selectById(req.getSessionId());
        if (session == null || !session.getUserId().equals(req.getUserId())) {
            throw new BizException(ErrorCode.SESSION_NOT_FOUND);
        }

        // 1. 服务端独立计算牌型
        HandResult handResult = HandEvaluator.evaluate(req.getCards());
        if (handResult.getHandRank().code != req.getSnapshot().getHandRank()) {
            auditLogger.logCheat(req, "hand_rank_mismatch",
                    handResult.getHandRank().code, req.getSnapshot().getHandRank());
            throw new BizException(ErrorCode.HAND_RANK_MISMATCH);
        }

        // 2. 重建法宝状态
        List<ArtifactState> artifacts = buildArtifactStates(session.getArtifactStatesJson());

        // 3. 计算 RNG 种子
        long rngSeed = computeRngSeed(
            session.getRngSeed(), req.getRound(), req.getStage(), req.getPlayIdx()
        );

        // 4. 服务端重算伤害
        DamageResult serverResult = DamageCalculator.calculate(
            handResult, artifacts, req.getElixirs(), rngSeed
        );

        // 5. 比对
        int diff = Math.abs(serverResult.getDamage() - req.getClaimed());
        if (diff > TOLERANCE) {
            auditLogger.logCheat(req, "damage_mismatch",
                    serverResult.getDamage(), req.getClaimed());
            log.warn("Damage mismatch uid={} claimed={} server={} diff={}",
                    req.getUserId(), req.getClaimed(), serverResult.getDamage(), diff);
        }

        return VerifyResult.builder()
                .verifiedDamage(serverResult.getDamage())
                .isDivine(serverResult.isDivine())
                .diff(diff)
                .build();
    }

    // 每次出牌用不同子种子，防客户端预测神通
    private long computeRngSeed(long baseSeed, int round, int stage, int playIdx) {
        return baseSeed ^ ((long) round << 16 | (long) stage << 8 | (long) playIdx);
    }
}
```

### 3.4 大妖技能系统

> **设计理念**：大妖技能是前端本地执行的效果，后端只负责在 `/api/game/start` 下发技能配置。技能不影响伤害计算公式，只影响前端手牌交互（遮挡、幻影等）。这样设计的好处：
> - 后端逻辑简单，不需要感知手牌状态
> - 前端可以灵活设计技能视觉效果
> - 新增大妖只需加配置，无需改后端代码

#### 大妖技能配置表

```java
// domain/entity/BossSkillConfig.java
@Data
@TableName("boss_skill_config")
public class BossSkillConfig {
    @TableId(type = IdType.AUTO)
    private Integer id;
    private Integer round;          // 轮次 0-2
    private String bossId;          // 大妖ID，如 demon_baigujing
    private String bossName;        // 大妖名称，如 白骨精
    private String skillId;         // 技能ID，前端分发key
    private String skillName;       // 技能名称
    private String skillDesc;       // 技能描述
    private String skillParams;     // 技能参数JSON，如 {"illusion_count":2}
    private Integer isActive;       // 是否启用
}
```

#### 大妖技能设计详解

| 轮次 | 大妖 | 技能ID | 技能名 | 效果 | 参数 | 设计灵感 |
|------|------|--------|--------|------|------|----------|
| 第1轮 | 白骨精 | `illusion` | 白骨幻术 | 随机将 N 张手牌变为幻影牌（不可选中出牌），每回合重置 | `{"illusion_count": 2}` | 原著白骨精善变幻术，三戏唐三藏 |
| 第2轮 | 黄风怪 | `sandstorm` | 风沙走石 | 随机遮挡 N 张手牌（背面朝上），需消耗换牌次数翻开 | `{"hidden_count": 3}` | 原著黄风怪刮三昧神风，遮天蔽日 |
| 第3轮 | 红孩儿 | `samadhi_fire` | 三昧真火 | 每回合随机指定2种牌型，只有该牌型可打出伤害，其余牌型伤害归零 | `{"valid_hand_count": 2}` | 原著红孩儿吐三昧真火，唯观音净瓶水可克 |

> **扩展预留**：后续可加入更多大妖：
> - 蜘蛛精——盘丝洞丝网：限制每回合最多出3张牌（需凑够5张需额外换牌）
> - 银角大王——紫金葫芦：随机封印1个法宝1回合（效果不生效）

### 3.5 广告回调服务（Demo 简化版）

> **Demo 简化**：不接入真实广告 SDK，广告 Token 用内存 ConcurrentHashMap 存储。前端调用 `resurrect` 接口时直接通过，无需真实广告回调。

```java
// infrastructure/cache/InMemoryTokenStore.java
@Component
public class InMemoryTokenStore {

    private static final long TOKEN_TTL_SECONDS = 300;  // 5分钟
    private final ConcurrentHashMap<String, TokenEntry> tokenStore = new ConcurrentHashMap<>();

    /** 预生成广告回调 Token */
    public String generateAdToken(String userId, Long sessionId) {
        String token = "ad_cb_" + UUID.randomUUID().toString().replace("-", "");
        tokenStore.put(token, new TokenEntry(userId, sessionId,
                System.currentTimeMillis() + TOKEN_TTL_SECONDS * 1000));
        return token;
    }

    /** 验证并消费 Token（防重放） */
    public TokenEntry consumeToken(String callbackToken) {
        TokenEntry entry = tokenStore.remove(callbackToken);
        if (entry == null) return null;
        if (System.currentTimeMillis() > entry.expireAt) return null;
        return entry;
    }

    /** 还魂时校验 Token 是否已被消费 */
    public boolean isAdTokenConsumed(String callbackToken) {
        return !tokenStore.containsKey(callbackToken);
    }

    /** 定时清理过期 Token */
    @Scheduled(fixedRate = 60_000)
    public void cleanupExpired() {
        long now = System.currentTimeMillis();
        tokenStore.entrySet().removeIf(e -> e.getValue().expireAt < now);
    }

    public record TokenEntry(String userId, Long sessionId, long expireAt) {}
}
```

### 3.6 仙铺服务

```java
// service/ShopService.java
@Service
@RequiredArgsConstructor
public class ShopService {

    private final GameSessionMapper sessionMapper;
    private final ItemModifierRegistry itemRegistry;

    // Demo: 仙铺状态用内存缓存替代 Redis
    private final ConcurrentHashMap<String, CachedShop> shopCache = new ConcurrentHashMap<>();
    private static final int SHOP_SLOTS = 5;
    private static final long SHOP_CACHE_TTL_MS = 30 * 60_000;  // 30分钟

    public ShopListResponse list(Long sessionId, int shopNode, int refreshCount) {
        String key = sessionId + ":" + shopNode;
        CachedShop cached = shopCache.get(key);

        List<ItemDTO> items;
        if (cached != null && !cached.isExpired() && refreshCount == 0) {
            items = cached.items;
        } else {
            items = generateShopItems(shopNode);
            shopCache.put(key, new CachedShop(items, System.currentTimeMillis() + SHOP_CACHE_TTL_MS));
        }

        return ShopListResponse.builder()
                .items(items)
                .refreshCost(calculateRefreshCost(refreshCount))
                .hasFreeRefresh(refreshCount == 0)
                .build();
    }

    @Transactional
    public BuyItemResponse buy(String userId, Long sessionId, int shopNode, String itemId) {
        GameSession session = sessionMapper.selectById(sessionId);
        ItemDTO itemConfig = itemRegistry.getConfig(itemId);

        if (itemConfig.getItemType() == 0 && isArtifactOwned(session, itemId)) {
            throw new BizException(ErrorCode.ARTIFACT_ALREADY_OWNED);
        }

        if (session.getGameCoins() < itemConfig.getPrice()) {
            throw new BizException(ErrorCode.SPIRIT_STONES_INSUFFICIENT);
        }
        sessionMapper.deductCoins(sessionId, itemConfig.getPrice());

        if (itemConfig.getItemType() == 0) {
            sessionMapper.addArtifact(sessionId, itemId);
        }

        return BuyItemResponse.builder()
                .remainingSpiritStones(session.getGameCoins() - itemConfig.getPrice())
                .ownedItemId(itemId)
                .build();
    }

    // ... generateShopItems / weightedPick / calculateRefreshCost 同 v1.0

    /** 定时清理过期仙铺缓存 */
    @Scheduled(fixedRate = 5 * 60_000)
    public void cleanupExpiredShopCache() {
        long now = System.currentTimeMillis();
        shopCache.entrySet().removeIf(e -> e.getValue().expireAt < now);
    }

    private record CachedShop(List<ItemDTO> items, long expireAt) {
        boolean isExpired() { return System.currentTimeMillis() > expireAt; }
    }
}
```

### 3.7 排行榜服务（内存版，启动时从 SQLite 重建）

> **设计要点**：排行榜是 `game_session` 表的**派生数据**（每个用户的最高伤害），SQLite 是 source of truth，内存是加速缓存。服务重启时从 DB 重建，数据不丢失。

```java
// infrastructure/cache/InMemoryLeaderboard.java
@Component
@RequiredArgsConstructor
public class InMemoryLeaderboard {

    private final GameSessionMapper sessionMapper;

    private final ConcurrentHashMap<String, Long> damageMap = new ConcurrentHashMap<>();

    /** 启动时从 SQLite 重建排行榜（防重启丢失） */
    @PostConstruct
    public void init() {
        List<GameSession> topSessions = sessionMapper.selectList(
            new QueryWrapper<GameSession>()
                .select("user_id", "MAX(total_score) as total_score")
                .eq("status", 1)
                .groupBy("user_id")
        );
        topSessions.forEach(s -> damageMap.put(s.getUserId(), s.getTotalScore()));
    }

    /** 提交伤害，只保留最高伤害 */
    public void submitDamage(String userId, long damage) {
        damageMap.merge(userId, damage, Math::max);
    }

    /** 全服排行榜（分页） */
    public List<RankEntry> getGlobalTop(int page, int size) {
        int start = (page - 1) * size;
        List<Map.Entry<String, Long>> sorted = damageMap.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .skip(start)
                .limit(size)
                .collect(Collectors.toList());
        return IntStream.range(0, sorted.size())
                .mapToObj(i -> RankEntry.builder()
                        .userId(sorted.get(i).getKey())
                        .score(sorted.get(i).getValue())
                        .rank(start + i + 1)
                        .build())
                .collect(Collectors.toList());
    }

    /** 获取个人排名 */
    public long getMyGlobalRank(String userId) {
        Long myDamage = damageMap.get(userId);
        if (myDamage == null) return -1L;
        return damageMap.values().stream()
                .filter(s -> s > myDamage)
                .count() + 1;
    }

    /** 好友榜（Demo 简化：无好友体系，返回全服前 N） */
    public List<RankEntry> getFriendsRank(String userId, int size) {
        return getGlobalTop(1, size);
    }
}
```

### 3.8 奖品服务

```java
// service/RewardService.java
@Service
@Slf44
@RequiredArgsConstructor
public class RewardService {

    private final GameSessionMapper sessionMapper;
    private final RewardTierMapper tierMapper;
    private final RewardClaimMapper claimMapper;
    private final InMemoryStockStore stockStore;

    public RewardTier matchTier(long damage) {
        return tierMapper.selectByDamage(damage);
    }

    @Transactional
    public ClaimResult claim(String userId, Long sessionId) {
        // 1. 防重复
        RewardClaim existing = claimMapper.selectByUserAndSession(userId, sessionId);
        if (existing != null) return ClaimResult.alreadyClaimed(existing);

        GameSession session = sessionMapper.selectById(sessionId);
        RewardTier tier = matchTier(session.getTotalScore());
        if (tier == null) return ClaimResult.noReward();

        // 2. 内存原子库存扣减
        if (tier.getStockLimit() != -1) {
            if (!stockStore.decrementIfPositive(tier.getId())) {
                return ClaimResult.outOfStock();
            }
        }

        // 3. 写领取记录（唯一键防并发重复）
        RewardClaim claim = RewardClaim.builder()
                .userId(userId).sessionId(sessionId).tierId(tier.getId())
                .status(ClaimStatus.PENDING.getCode()).build();
        try {
            claimMapper.insert(claim);
        } catch (DuplicateKeyException e) {
            if (tier.getStockLimit() != -1)
                stockStore.increment(tier.getId());
            return ClaimResult.alreadyClaimed(null);
        }

        tierMapper.incrementStockUsed(tier.getId());
        return ClaimResult.success(tier);
    }
}
```

---

## 第4章 数据库设计

### 4.1 完整 Schema（SQLite 适配版）

> **SQLite 适配说明**：
> - `BIGINT` → `INTEGER`（SQLite 统一整数类型）
> - `TINYINT` → `INTEGER`（同上）
> - `JSON` → `TEXT`（SQLite 无原生 JSON 类型，存 JSON 字符串，MyBatis-Plus 自动序列化）
> - `DATETIME` → `TEXT`（SQLite 存 ISO-8601 字符串）
> - `ENGINE=InnoDB` → 移除（SQLite 无存储引擎概念）
> - `INDEX` → `CREATE INDEX` 独立语句（SQLite 不支持内联索引）
> - `ON UPDATE CURRENT_TIMESTAMP` → 移除（应用层负责更新时间戳）

```sql
-- ============================================
-- poker_roguelike.db  (SQLite 3.x)
-- 西游扑克 Roguelike——西游记主题版
-- 启动时自动创建于项目根目录
-- 使用 IF NOT EXISTS / OR IGNORE 防重复初始化
-- ============================================

-- 游戏局记录
CREATE TABLE IF NOT EXISTS game_session (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          TEXT    NOT NULL,
    start_time       TEXT    NOT NULL,
    end_time         TEXT,
    total_score      INTEGER NOT NULL DEFAULT 0,  -- 语义=总伤害
    status           INTEGER NOT NULL DEFAULT 0,  -- 0进行中 1完成 2放弃
    rng_seed         INTEGER NOT NULL,
    resurrect_count  INTEGER NOT NULL DEFAULT 0,   -- 还魂次数
    game_coins       INTEGER NOT NULL DEFAULT 0,  -- 灵石
    artifact_states  TEXT,                          -- 法宝状态 JSON字符串
    owned_elixirs    TEXT,                          -- 仙丹列表 JSON字符串
    created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_session_user_id ON game_session(user_id);
CREATE INDEX idx_session_score   ON game_session(total_score DESC);
CREATE INDEX idx_session_created ON game_session(created_at);

-- 出牌明细日志
CREATE TABLE IF NOT EXISTS play_log (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id   INTEGER NOT NULL,
    round_idx    INTEGER NOT NULL,  -- 轮次 0-2
    stage_idx    INTEGER NOT NULL,  -- 关卡 0=小兵 1=精英怪 2=大妖
    play_idx     INTEGER NOT NULL,  -- 第几次出牌 0-3
    cards_json   TEXT    NOT NULL,  -- 5张牌 JSON
    elixirs      TEXT,              -- 使用的仙丹ID列表 JSON
    damage       INTEGER NOT NULL,  -- 伤害值
    is_divine    INTEGER NOT NULL DEFAULT 0,  -- 0=否 1=神通
    snapshot     TEXT    NOT NULL,  -- 客户端快照 JSON
    server_damage INTEGER,         -- 服务端重算伤害
    diff         INTEGER,           -- 客户端与服务端差值
    created_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_play_log_session ON play_log(session_id);

-- 广告回调日志
CREATE TABLE IF NOT EXISTS ad_callback_log (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    trans_id        TEXT NOT NULL UNIQUE,  -- 幂等：同一交易只处理一次
    callback_token  TEXT NOT NULL,
    user_id         TEXT NOT NULL,
    session_id      INTEGER NOT NULL,
    ad_type         TEXT NOT NULL,
    scene           TEXT NOT NULL,         -- resurrect
    created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_ad_token ON ad_callback_log(callback_token);
CREATE INDEX idx_ad_user_session ON ad_callback_log(user_id, session_id);

-- 大妖技能配置
CREATE TABLE IF NOT EXISTS boss_skill_config (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    round_idx    INTEGER NOT NULL,  -- 轮次 0-2
    boss_id      TEXT    NOT NULL, -- 大妖ID，如 demon_baigujing
    boss_name    TEXT    NOT NULL, -- 大妖名称，如 白骨精
    skill_id     TEXT    NOT NULL, -- 技能ID，前端分发key
    skill_name   TEXT    NOT NULL, -- 技能名称
    skill_desc   TEXT    NOT NULL, -- 技能描述
    skill_params TEXT,             -- 技能参数JSON
    is_active    INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_boss_skill_round ON boss_skill_config(round_idx);

-- 奖品档位配置
CREATE TABLE IF NOT EXISTS reward_tier (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    min_damage   INTEGER NOT NULL,      -- 最低伤害
    max_damage   INTEGER NOT NULL,      -- 最高伤害，-1表示无上限
    reward_name  TEXT    NOT NULL,
    reward_type  TEXT    NOT NULL,       -- drink/coupon/digital/rare
    stock_limit  INTEGER NOT NULL DEFAULT -1,  -- -1不限库存
    stock_used   INTEGER NOT NULL DEFAULT 0,
    is_active    INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_reward_damage_range ON reward_tier(min_damage, max_damage);

-- 奖品领取记录
CREATE TABLE IF NOT EXISTS reward_claim (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      TEXT    NOT NULL,
    session_id   INTEGER NOT NULL,
    tier_id      INTEGER NOT NULL,
    status       INTEGER NOT NULL DEFAULT 0,  -- 0待发放 1已发放 2失败
    fail_reason  TEXT,
    created_at   TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE(user_id, session_id)
);

-- 游戏配置（热更新）
CREATE TABLE IF NOT EXISTS game_config (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    config_key   TEXT NOT NULL UNIQUE,
    config_value TEXT NOT NULL,  -- JSON字符串
    version      INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- 道具配置（热更新）——法宝和仙丹
CREATE TABLE IF NOT EXISTS item_config (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id      TEXT NOT NULL UNIQUE,
    config_data  TEXT NOT NULL,  -- JSON字符串
    version      INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- 用户钱包
CREATE TABLE IF NOT EXISTS user_wallet (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      TEXT    NOT NULL UNIQUE,
    gold_coins   INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
```

### 4.2 初始配置数据

```sql
-- 门槛与灵石奖励配置（原 coin_rewards / round_thresholds）
INSERT OR IGNORE INTO game_config (config_key, config_value) VALUES
('hp_bars', '[[300,800,1500],[1500,3000,5000],[3500,6000,10000]]'),
('spirit_stone_rewards', '[[30,50,80],[50,80,120],[80,120,180]]'),
('max_resurrections', '3'),
('damage_tolerance', '1'),
('shop_slot_count', '5'),
('refresh_cost_formula', '{"base":5,"increment":5}'),
('entry_cost', '10'),
('exchange_divisor', '100'),
('initial_gold_coins', '100');

-- 大妖技能配置
INSERT OR IGNORE INTO boss_skill_config (round_idx, boss_id, boss_name, skill_id, skill_name, skill_desc, skill_params) VALUES
(0, 'demon_baigujing', '白骨精', 'illusion', '白骨幻术', '随机将2张手牌变为幻影牌（不可选中出牌），每回合重置', '{"illusion_count": 2}'),
(1, 'demon_huangfeng', '黄风怪', 'sandstorm', '风沙走石', '随机遮挡3张手牌，需消耗换牌次数翻开', '{"hidden_count": 3}'),
(2, 'demon_honghaier', '红孩儿', 'samadhi_fire', '三昧真火', '每回合随机指定2种牌型，只有该牌型可打出伤害，其余牌型伤害归零', '{"valid_hand_count": 2}');

-- 奖品档位（基于伤害）
INSERT OR IGNORE INTO reward_tier (min_damage, max_damage, reward_name, reward_type, stock_limit) VALUES
(0,     999,   '参与奖',     'digital', -1),
(1000,  2999,  '雪碧',       'drink',   5000),
(3000,  5999,  '奶茶',       'drink',   3000),
(6000,  9999,  '奶茶升级券', 'coupon',  1000),
(10000, -1,    '稀有奖品',   'rare',    100);

-- 法宝配置（原小丑牌）
INSERT OR IGNORE INTO item_config (item_id, config_data) VALUES
('artifact_bjs', '{
    "display_name":"芭蕉扇","description":"每次出牌掀起罡风，固定增加倍率",
    "price":30,"rarity":0,"item_type":0,
    "shop_weights":[30,25,20,15,10,5],
    "upgrade_costs":[40,80],
    "effect_class":"BaJiaoShan",
    "level_params":[
        {"mult_add":4},
        {"mult_add":7},
        {"mult_add":11}
    ]
}'),
('artifact_zjl', '{
    "display_name":"紫金铃","description":"连续同牌型倍率提升",
    "price":40,"rarity":0,"item_type":0,
    "shop_weights":[25,25,25,20,15,10],
    "upgrade_costs":[50,100],
    "effect_class":"ArtifactZJL",
    "level_params":[
        {"chain_mult":0.15},
        {"chain_mult":0.25},
        {"chain_mult":0.40}
    ]
}'),
('artifact_rsg', '{
    "display_name":"人参果","description":"低概率触发极高特殊倍率",
    "price":50,"rarity":0,"item_type":0,
    "shop_weights":[15,12,15,18,15,10],
    "upgrade_costs":[60,120],
    "effect_class":"RenShenGuo",
    "level_params":[
        {"boom_prob":0.03,"boom_mult":10.0},
        {"boom_prob":0.05,"boom_mult":15.0},
        {"boom_prob":0.08,"boom_mult":20.0}
    ]
}');

-- 仙丹配置（原冲分道具）
INSERT OR IGNORE INTO item_config (item_id, config_data) VALUES
('elixir_luck_spark', '{
    "display_name":"九转金丹","description":"神通率+20%",
    "price":8,"rarity":0,"item_type":1,
    "shop_weights":[30,25,20,15,5,5],
    "effect_class":"ElixirLuckSpark",
    "level_params":[{"divine_rate_add":0.20}]
}'),
('elixir_double', '{
    "display_name":"分身术","description":"倍率×2",
    "price":12,"rarity":0,"item_type":1,
    "shop_weights":[20,20,20,20,15,5],
    "effect_class":"ElixirDouble",
    "level_params":[{"mult_multiplier":2.0}]
}'),
('elixir_boss_burst', '{
    "display_name":"降妖符","description":"大妖关卡倍率×3",
    "price":15,"rarity":0,"item_type":1,
    "shop_weights":[15,15,20,20,20,10],
    "effect_class":"ElixirBossBurst",
    "level_params":[{"boss_mult":3.0}]
}'),
('elixir_extra_play', '{
    "display_name":"定身术","description":"出牌次数+1",
    "price":10,"rarity":0,"item_type":1,
    "shop_weights":[20,20,20,20,15,5],
    "effect_class":"ElixirExtraPlay",
    "level_params":[{"extra_plays":1}]
}'),
('elixir_extra_discard', '{
    "display_name":"千里眼","description":"换牌次数+1",
    "price":8,"rarity":0,"item_type":1,
    "shop_weights":[25,25,20,15,10,5],
    "effect_class":"ElixirExtraDiscard",
    "level_params":[{"extra_discards":1}]
}'),
('elixir_refresh', '{
    "display_name":"仙铺刷新券","description":"下次仙铺刷新免费",
    "price":5,"rarity":0,"item_type":1,
    "shop_weights":[30,25,20,15,5,5],
    "effect_class":"ElixirRefresh",
    "level_params":[{"free_refresh":1}]
}'),
('elixir_lucky_compass', '{
    "display_name":"照妖镜","description":"稀有法宝出现概率×10",
    "price":15,"rarity":0,"item_type":1,
    "shop_weights":[10,10,15,20,25,20],
    "effect_class":"ElixirLuckyCompass",
    "level_params":[{"rare_prob_mult":10.0}]
}'),
('elixir_divine_storm', '{
    "display_name":"五连神通","description":"整回合神通率100%",
    "price":30,"rarity":1,"item_type":1,
    "shop_weights":[5,5,10,15,25,40],
    "effect_class":"ElixirDivineStorm",
    "level_params":[{"divine_rate_override":1.0}]
}'),
('elixir_windbreaker', '{
    "display_name":"定风丹","description":"免疫大妖技能1回合",
    "price":20,"rarity":1,"item_type":1,
    "shop_weights":[5,5,10,15,25,40],
    "effect_class":"ElixirWindbreaker",
    "level_params":[{"boss_skill_immune":1}]
}');
```

> **法宝/仙丹设计灵感来源**：
>
> | 法宝/仙丹 | 原著灵感 | 设计思路 |
> |-----------|----------|----------|
> | 芭蕉扇 | 铁扇公主的宝扇，可扇出罡风、熄灭火焰山烈火 | 固定倍率=每次出牌都有罡风助势 |
> | 紫金铃 | 太上老君的紫金铃铛，摇动出火/烟/沙 | 连锁同牌型=铃声回荡不断 |
> | 人参果 | 五庄观人参果，三千年一熟 | 低概率大伤害=稀世仙果爆发惊人 |
> | 九转金丹 | 太上老君炼制的仙丹 | 增加神通率=服用后功力大增 |
> | 分身术 | 孙悟空拔毫毛变分身 | 倍率翻倍=分身一起攻击 |
> | 降妖符 | 道家降妖之术 | 大妖关卡倍率×3=专门克制大妖 |
> | 定身术 | 孙悟空定身法 | 出牌次数+1=时间凝固多打一次 |
> | 千里眼 | 天庭千里眼 | 换牌次数+1=看得远、换得多 |
> | 定风丹 | 灵吉菩萨赠悟空定风丹 | 免疫大妖技能=原著中克制黄风怪三昧神风 |

---

## 第5章 关键业务流程

### 5.1 出牌流程

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant DB as SQLite

    C->>S: POST /api/game/submit_play (牌面+法宝+仙丹+快照)
    S->>S: HandEvaluator.evaluate(cards)
    S->>S: DamageCalculator.calculate(...)
    S->>S: diff = |serverDamage - claimed|
    alt diff ≤ 1
        S-->>C: {verifiedDamage, totalDamage}
    else diff > 1
        S-->>C: {verifiedDamage=服务端伤害, totalDamage}
        S->>S: 写审计日志 (ScoreAuditLogger)
    end
    S->>DB: INSERT play_log
```

### 5.2 仙铺购买流程

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant DB as SQLite

    C->>S: GET /api/shop/list?session_id&shop_node&refresh_count=0
    S->>S: 生成商品池（权重+保底）
    S-->>C: {items, refresh_cost=0}

    alt 玩家刷新
        C->>S: GET /api/shop/list?refresh_count=1
        S-->>C: {新商品列表}
    end

    alt 玩家购买
        C->>S: POST /api/shop/buy
        S->>DB: 校验灵石 → 扣减 → 记录
        S-->>C: {remaining_spirit_stones, owned_item_id}
    end
```

### 5.3 还魂流程（Demo 简化）

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant Mem as In-Memory TokenStore

    C->>S: POST /api/game/resurrect_prepare
    S->>Mem: generateAdToken()
    S-->>C: {ad_callback_token}

    Note over C,S: Demo 简化：直接调用 resurrect，无需真实广告回调

    C->>S: POST /api/game/resurrect {ad_token}
    S->>Mem: consumeToken() → 验证通过
    S->>S: resurrect_count++
    S-->>C: {resurrect_count}
```

### 5.4 大妖关卡流程

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    Note over C: 进入第 N 轮第 3 回合（大妖关）
    C->>C: 激活 boss_skills[N] 技能效果
    C->>C: 白骨精：幻影牌遮挡2张手牌
    C->>C: 黄风怪：风沙遮挡3张手牌
    C->>C: 红孩儿：三昧真火指定牌型，只有指定牌型可打出伤害

    loop 每次出牌
        C->>C: 在技能限制下选牌出牌
        C->>C: 本地计算伤害 → 扣减大妖血条
        C->>S: POST /api/game/submit_play
        S-->>C: {verifiedDamage}
    end

    alt 大妖血条归零
        C->>C: 通关！进入下一轮
    else 出牌耗尽未击破
        C->>C: 可选择还魂或结束
    end
```

### 5.5 奖品兑换流程

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server
    participant DB as SQLite
    participant Mem as In-Memory StockStore

    C->>S: POST /api/game/submit_result
    S->>S: 最终伤害校验
    S->>Mem: submitDamage → 更新排行榜
    S-->>C: {totalDamage, rank, rewardTier}

    alt 玩家点击兑换
        C->>S: POST /api/reward/claim
        S->>DB: 查唯一键 → 未领取
        S->>Mem: decrementIfPositive()
        alt 库存充足
            S->>DB: INSERT reward_claim
            S-->>C: {tier, claim_status}
        else 库存不足
            S-->>C: code=4001 OUT_OF_STOCK
        end
    end
end
```

---

## 第6章 配置与热更新

### 6.1 热更新架构（Demo 简化）

所有数值配置存放在 `game_config`、`item_config`、`boss_skill_config` SQLite 表中，随 `/api/game/start` 一起下发客户端。

```mermaid
flowchart LR
    Admin[运营后台] -->|修改配置| SQLite[(game_config / item_config / boss_skill_config)]
    SQLite -->|/api/game/start 下发| Client[Client]
    SQLite -->|启动时加载| InMem[In-Memory Cache]
```

### 6.2 配置加载流程（Server 端）

```java
// service/ConfigService.java (简化版)
@Service
@RequiredArgsConstructor
public class ConfigService {

    private final GameConfigMapper configMapper;
    private final ItemConfigMapper itemConfigMapper;
    private final BossSkillConfigMapper bossSkillConfigMapper;

    private final ConcurrentHashMap<String, String> configCache = new ConcurrentHashMap<>();
    private List<ItemDTO> cachedItems = List.of();
    private List<BossSkillDTO> cachedBossSkills = List.of();

    @PostConstruct
    public void init() {
        reload();
    }

    public void reload() {
        configMapper.selectList(null).forEach(
            c -> configCache.put(c.getConfigKey(), c.getConfigValue())
        );
        cachedItems = itemConfigMapper.selectList(null).stream()
            .map(this::toItemDTO)
            .collect(Collectors.toList());
        cachedBossSkills = bossSkillConfigMapper.selectList(
            new QueryWrapper<BossSkillConfig>().eq("is_active", 1)
        ).stream()
            .map(this::toBossSkillDTO)
            .collect(Collectors.toList());
    }

    public String getConfig(String key) {
        return configCache.get(key);
    }

    public List<ItemDTO> getAllItems() {
        return cachedItems;
    }

    public List<BossSkillDTO> getActiveBossSkills() {
        return cachedBossSkills;
    }
}
```

### 6.3 配置更新规范

| 配置项 | 表 | 热更新 | 说明 |
|--------|---|--------|------|
| 血条数值 | game_config | ✅ | 改 DB 即生效，下次 /start 下发 |
| 灵石奖励 | game_config | ✅ | 同上 |
| 法宝/仙丹价格/权重 | item_config | ✅ | 同上 |
| 法宝/仙丹效果数值 | item_config | ✅ | 同上 |
| 大妖技能 | boss_skill_config | ✅ | 改 DB 即生效 |
| 奖品档位 | reward_tier | ✅ | 直接改 DB |
| 最大还魂次数 | game_config | ✅ | 同上 |
| 错误码 | 代码 | ❌ | 需发版 |

---

## 第7章 部署与运维

### 7.1 Demo 部署（单 Jar + SQLite 文件）

```bash
# 1. 构建
mvn clean package -DskipTests

# 2. 运行（SQLite 数据库文件自动创建）
java -jar target/poker-roguelike-server-1.0.jar

# 3. 验证
curl http://localhost:8080/api/health
```

**产物结构**：
```
poker-roguelike-server-1.0.jar   # 可执行 jar（内嵌 Tomcat）
poker_roguelike.db               # SQLite 数据库文件（首次运行自动创建）
```

### 7.2 关键配置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `server.port` | 8080 | 服务端口 |
| `spring.datasource.url` | `jdbc:sqlite:poker_roguelike.db` | SQLite 文件路径 |
| `jwt.secret` | - | JWT 签名密钥 |
| `jwt.expiration` | 86400000 | Token 有效期（毫秒） |

### 7.3 SQLite 配置（WAL + busy_timeout）

```java
// config/SQLiteConfig.java
@Configuration
public class SQLiteConfig {

    @Bean
    public DataSource dataSource(@Value("${spring.datasource.url}") String url) {
        SQLiteDataSource ds = new SQLiteDataSource();
        ds.setUrl(url);
        return ds;
    }

    @Bean
    public CommandLineRunner initSQLite(JdbcTemplate jdbc) {
        return args -> {
            jdbc.execute("PRAGMA journal_mode=WAL");       // 启用 WAL 模式（并发读）
            jdbc.execute("PRAGMA busy_timeout=5000");       // 写锁等待 5s
            jdbc.execute("PRAGMA synchronous=NORMAL");      // 平衡性能与安全
            log.info("SQLite initialized: WAL mode, busy_timeout=5000ms");
        };
    }
}
```

### 7.4 SQLite 数据初始化

首次启动时，应用自动执行 `schema.sql`（建表）和 `data.sql`（初始数据）。

```yaml
# application.yml
spring:
  sql:
    init:
      mode: always
      schema-locations: classpath:schema.sql
      data-locations: classpath:data.sql
```

### 7.5 后续升级路径

| 组件 | Demo | 生产 | 升级改动 |
|------|------|------|----------|
| 关系库 | SQLite 文件 | MySQL 8.0 | 改 datasource 配置 + 调整 SQL 类型 |
| 缓存 | ConcurrentHashMap | Redis 7 | 实现 Cache 接口的 Redis 版本 |
| 部署 | 单 Jar | Docker Compose | 加 docker-compose.yml |
| 前端 | 前端独立开发 | Godot Web Export | Nginx 静态资源 + COOP/COEP |

---

## 第8章 开发流程规范

> 本章定义后端开发的标准流程，确保每个模块从设计到交付都有质量保障。

### 8.1 总体开发流程

```mermaid
flowchart TD
    A[编写模块技术文档] --> B[SubAgent Review 技术文档]
    B -->|有问题| C[修复文档问题]
    C --> B
    B -->|通过| D[进入功能开发]
    D --> E[SubAgent Review 代码]
    E -->|有问题| F[修复代码问题]
    F --> E
    E -->|通过| G[编写测试用例]
    G --> H[运行测试]
    H -->|不通过| I[修复测试问题]
    I --> H
    H -->|通过| J[模块完成 ✅]
```

### 8.2 开发流程详解

#### 阶段 1：技术文档编写

每个模块在开发前**必须**先编写技术文档，文档内容包括：

| 要素 | 说明 |
|------|------|
| 模块目标 | 该模块要解决什么问题 |
| 接口设计 | API 路径、请求/响应格式 |
| 数据模型 | 涉及的实体、DTO、枚举 |
| 核心逻辑 | 关键算法、业务规则 |
| 依赖关系 | 依赖哪些其他模块/服务 |
| 异常处理 | 错误码、异常场景 |
| 测试策略 | 关键测试场景 |

文档存放在 `server/docs/modules/` 目录下，命名规范：`{模块名}_design.md`

#### 阶段 2：技术文档 Review

使用 SubAgent 对技术文档进行 Review，关注点：

- [ ] 接口设计是否符合 REST 规范
- [ ] 数据模型是否与 Schema 对齐
- [ ] 业务逻辑是否有遗漏边界场景
- [ ] 错误处理是否完整
- [ ] 是否考虑并发安全
- [ ] 与其他模块的依赖是否清晰

**Review 不通过** → 修复文档 → 重新 Review
**Review 通过** → 进入阶段 3

#### 阶段 3：功能开发

根据通过 Review 的技术文档进行编码，遵循分层架构：

```
Controller → Service → Mapper / Infrastructure
   ↓            ↓            ↓
 参数校验    业务编排      数据访问
```

开发规范：
- Controller 层不做业务逻辑，只做参数校验和调用 Service
- Service 层是业务核心，事务管理在此层
- Mapper 层只做数据访问，不写业务 SQL
- `game/` 包下保持零外部依赖，方便单元测试

#### 阶段 4：代码 Review

功能开发完成后，使用 SubAgent 对代码进行 Review，关注点：

- [ ] 代码是否符合分层架构规范
- [ ] 是否有空指针/资源泄漏风险
- [ ] 异常处理是否与文档一致
- [ ] 是否有硬编码的魔法值
- [ ] 命名是否清晰、符合 Java 规范
- [ ] 是否缺少必要的日志
- [ ] 并发场景是否安全

**Review 不通过** → 修复代码 → 重新 Review
**Review 通过** → 进入阶段 5

#### 阶段 5：测试用例编写与执行

每个模块**必须**有对应的测试用例，分为两层：

| 测试层 | 范围 | 框架 |
|--------|------|------|
| 单元测试 | Service / Game 逻辑 | JUnit 5 + Mockito |
| 集成测试 | Controller → DB 全链路 | Spring Boot Test + H2 |

测试用例要求：
- 核心业务逻辑覆盖率 ≥ 80%
- 每个错误码至少一个测试场景
- 边界场景（空输入、超限、并发）必须有覆盖

测试命名规范：`should_{期望行为}_when_{条件}`
示例：`should_throwHandRankMismatch_when_clientSnapshotNotMatchServer`

### 8.3 模块开发顺序

| 优先级 | 模块 | 说明 |
|--------|------|------|
| P0 | 项目骨架 | Spring Boot + SQLite + MyBatis-Plus 基础配置 |
| P0 | 游戏逻辑层 | `game/` 包：HandEvaluator + DamageCalculator（纯逻辑，零依赖） |
| P1 | GameService | 局管理 + 出牌提交 + 结果提交 |
| P1 | ScoreVerifyService | 伤害校验 |
| P1 | BossSkillConfig | 大妖技能配置下发 |
| P2 | ShopService | 仙铺列表 + 购买 |
| P2 | RankService | 排行榜（In-Memory） |
| P2 | RewardService | 奖品匹配 + 兑换 |
| P3 | AdCallbackService | 广告回调（Demo 简化） |
| P3 | ConfigService | 配置加载 |

### 8.4 文档与代码对应关系

| 技术文档 | 代码模块 | 测试文件 |
|----------|----------|----------|
| `game_service_design.md` | `controller/GameController.java` + `service/GameService.java` | `GameServiceTest.java` |
| `score_verify_design.md` | `service/ScoreVerifyService.java` | `ScoreVerifyServiceTest.java` |
| `boss_skill_design.md` | `domain/BossSkillConfig.java` + `service/ConfigService.java` | `BossSkillConfigTest.java` |
| `shop_service_design.md` | `controller/ShopController.java` + `service/ShopService.java` | `ShopServiceTest.java` |
| `rank_service_design.md` | `controller/RankController.java` + `service/RankService.java` | `RankServiceTest.java` |
| `reward_service_design.md` | `controller/RewardController.java` + `service/RewardService.java` | `RewardServiceTest.java` |
| `game_logic_design.md` | `game/HandEvaluator.java` + `game/DamageCalculator.java` | `HandEvaluatorTest.java` + `DamageCalculatorTest.java` |

---

## 附录

### A. 大妖血条设计推导

| 牌型 | 基础伤害 | 单次出牌期望伤害（无法宝）|
|------|----------|--------------------------|
| 高牌 | 50 | ~50 |
| 一对 | 100 | ~100 |
| 两对 | 180 | ~180 |
| 三条 | 300 | ~300 |
| 顺子 | 450 | ~450 |
| 同花 | 600 | ~600 |

推导逻辑：每回合4次出牌，假设平均每次约150伤害。

| 轮次 | 小兵 | 精英怪 | 大妖 |
|------|------|--------|------|
| 第1轮 | 300 | 800 | 1,500 |
| 第2轮 | 1,500 | 3,000 | 5,000 |
| 第3轮 | 3,500 | 6,000 | 10,000 |

### B. 法宝升级数值总表

| 法宝 | Level 1 | Level 2 | Level 3 | 升级价1→2 | 升级价2→3 |
|------|---------|---------|---------|-----------|-----------|
| 芭蕉扇 | +4倍率 | +7倍率 | +11倍率 | 40 | 80 |
| 紫金铃 | 连续同牌型每次+0.15倍率 | 连续同牌型每次+0.25倍率 | 连续同牌型每次+0.40倍率 | 50 | 100 |
| 人参果 | 3%概率×10 | 5%概率×15 | 8%概率×20 | 60 | 120 |

### C. 仙丹价格总表

| 仙丹 | 效果 | 价格 | 稀有度 | 原著灵感 |
|------|------|------|--------|----------|
| 九转金丹 | 神通率+20% | 8 | 普通 | 太上老君炼丹术 |
| 神通药水 | 神通倍率+1.0 | 10 | 普通 | 天庭仙丹 |
| 分身术 | 倍率×2 | 12 | 普通 | 悟空毫毛分身 |
| 降妖符 | 大妖关卡倍率×3 | 15 | 普通 | 道家降妖术 |
| 狂战药水 | 当回合倍率+50% | 12 | 普通 | 妖王狂化之力 |
| 定身术 | 出牌次数+1 | 10 | 普通 | 悟空定身法 |
| 终局符 | 大妖出牌次数+1 | 15 | 普通 | 仙人赠符 |
| 千里眼 | 换牌次数+1 | 8 | 普通 | 天庭千里眼 |
| 仙铺刷新券 | 下次仙铺刷新免费 | 5 | 普通 | 仙人赠送 |
| 照妖镜 | 稀有法宝出现概率×10 | 15 | 普通 | 二郎神照妖镜 |
| 五连神通 | 整回合神通率100% | 30 | 稀有 | 齐天大圣全力 |
| 余牌加持 | 剩余手牌最高点数加倍率 | 25 | 稀有 | 后发制人 |
| 定风丹 | 免疫大妖技能1回合 | 20 | 稀有 | 灵吉菩萨赠丹 |

### D. 灵石发放总表

| 轮次 | 小兵 | 精英怪 | 大妖 |
|------|------|--------|------|
| 第1轮 | 30 | 50 | 80 |
| 第2轮 | 50 | 80 | 120 |
| 第3轮 | 80 | 120 | 180 |

### E. 大妖血条总表

| 轮次 | 小兵 | 精英怪 | 大妖 |
|------|------|--------|------|
| 第1轮 | 300 | 800 | 1,500 |
| 第2轮 | 1,500 | 3,000 | 5,000 |
| 第3轮 | 3,500 | 6,000 | 10,000 |

### F. 大妖技能总表

| 轮次 | 大妖 | 技能 | 效果 | 克制手段 |
|------|------|------|------|----------|
| 第1轮 | 白骨精 | 白骨幻术 | 随机2张手牌变幻影牌（不可出） | 无直接克制，需策略性换牌 |
| 第2轮 | 黄风怪 | 风沙走石 | 随机遮挡3张手牌 | 定风丹（免疫技能1回合） |
| 第3轮 | 红孩儿 | 三昧真火 | 每回合随机指定2种牌型，只有该牌型可打出伤害，其余伤害归零 | 千里眼（多换牌凑指定牌型） |

> **设计说明**：每个大妖技能都有对应的克制仙丹，鼓励玩家在仙铺中寻找策略道具，增加玩法深度。

---

> 文档结束。后续版本迭代在此基础补充。
>
> **v2.0 变更记录**：
> - 主题：小丑牌 Roguelike → 西游扑克 Roguelike（西游记本土化）
> - 术语：小盲/大盲/Boss → 小兵/精英怪/大妖，小丑牌 → 法宝，冲分道具 → 仙丹
> - 语义：得分 → 伤害，通过分数 → 怪物血条，暴击 → 神通，复活 → 还魂
> - 新增：大妖技能系统（白骨幻术、风沙走石、三昧真火）
> - 新增：定风丹——克制大妖技能的稀有仙丹
> - 新增：boss_skill_config 表及配置下发
> - 数据：所有道具重新按西游记设定命名和设计效果
> - 核心：玩法不变——3轮×3回合，扑克出牌算分，商店+法宝，排行榜
