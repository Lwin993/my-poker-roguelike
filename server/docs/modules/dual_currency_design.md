# 双货币系统技术方案（外部金币 + 游戏代币）

> 版本：v1.0 | 日期：2026-07-06 | 状态：待 Review | 模块：货币系统

---

## 1. 模块目标

引入双货币体系，让游戏有"入场成本"和"收益回报"的经济循环：

- **外部金币（gold_coins）**：持久货币，跨对局持有，用于支付入场费
- **游戏代币（game_coins）**：局内货币，每局从 0 开始，通关盲注获得，局内买道具/刷新消耗
- **兑换**：对局结束时，按 `total_score × 兑换率` 自动兑换外部金币，无需玩家手动操作

---

## 2. 数据模型

### 2.1 新增表：`user_wallet`

```sql
CREATE TABLE IF NOT EXISTS user_wallet (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      TEXT NOT NULL UNIQUE,
    gold_coins   INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);
```

> 设计说明：独立钱包表而非在 user 表加字段，因为 Demo 阶段没有 user 表，这是第一个用户相关表。后续加用户体系时可以合并。

### 2.2 新增配置项（`game_config` 表）

| config_key | 默认值 | 说明 |
|---|---|---|
| `entry_cost` | `10` | 一局游戏的入场费（外部金币） |
| `exchange_divisor` | `100` | 总分兑换除数（gold_earned = total_score / exchange_divisor，整数除法，避免浮点误差） |
| `initial_gold_coins` | `100` | 新用户初始外部金币 |

### 2.3 `game_session` 表变更

无结构变更。`game_coins` 字段已经是"游戏代币"，含义不变。

---

## 3. 接口设计

### 3.1 `POST /api/game/start`（修改）

**新增逻辑**：扣除外部金币作为入场费

```
前置检查：
  1. 查 user_wallet 拿 gold_coins
  2. 若 gold_coins < entry_cost → 返回错误码 5002(GOLD_INSUFFICIENT)
  3. 扣减 entry_cost
  4. 若该用户首次出现（wallet 不存在）→ 自动创建 + 赠送 initial_gold_coins
```

**响应新增字段**：

```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "session_id": 10001,
        "gold_coins": 90,          // ← 新增：扣完入场费后的外部金币余额
        "entry_cost": 10,          // ← 新增：本次扣的入场费
        "round_config": { ... },
        "item_config": { ... },
        "reward_config": [ ... ]
    }
}
```

**错误场景**：

| 错误码 | 常量 | 说明 |
|---|---|---|
| 5002 | GOLD_INSUFFICIENT | 外部金币不足，无法开始游戏 |

### 3.2 `POST /api/game/submit_result`（修改）

**新增逻辑**：结算时自动兑换外部金币

```
1. 现有逻辑不变：标记 session COMPLETED，更新排行榜
2. 新增：计算 gold_earned = total_score × score_exchange_rate（取整）
3. 新增：user_wallet.gold_coins += gold_earned
4. 新增：若 gold_earned > 0，返回 gold_earned 和 gold_coins 余额
```

**响应新增字段**：

```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "total_score": 8500,
        "gold_earned": 85,          // ← 新增：8500 × 0.01 = 85 外部金币
        "gold_coins": 175,          // ← 新增：兑换后外部金币余额
        "global_rank": 1234,
        "reward_tier": { ... }
    }
}
```

### 3.3 `GET /api/wallet/balance`（新增）

查询当前用户的外部金币余额。用于前端主界面展示。

**请求**：

```
GET /api/wallet/balance
Authorization: Bearer {token}
```

**响应**：

```json
{
    "code": 0,
    "msg": "ok",
    "data": {
        "gold_coins": 90
    }
}
```

---

## 4. 核心逻辑

### 4.1 WalletService

```java
@Service
@RequiredArgsConstructor
public class WalletService {

    private final UserWalletMapper walletMapper;
    private final ConfigService configService;

    /** 获取余额，不存在则创建并赠送初始金币 */
    @Transactional
    public int getOrCreateBalance(String userId) {
        UserWallet wallet = walletMapper.selectByUserId(userId);
        if (wallet != null) return wallet.getGoldCoins();
        // 新用户：创建钱包 + 赠送初始金币
        int initial = configService.getIntConfig("initial_gold_coins", 100);
        UserWallet newWallet = UserWallet.builder()
                .userId(userId)
                .goldCoins(initial)
                .build();
        walletMapper.insert(newWallet);
        return initial;
    }

    /** 扣减入场费，返回扣减后余额（纯SQL乐观锁，无Java前置检查） */
    @Transactional
    public int deductEntryCost(String userId) {
        int entryCost = configService.getIntConfig("entry_cost", 10);
        // 首次出现：赠送初始金币
        UserWallet wallet = walletMapper.selectByUserId(userId);
        if (wallet == null) {
            int initial = configService.getIntConfig("initial_gold_coins", 100);
            wallet = UserWallet.builder()
                    .userId(userId)
                    .goldCoins(initial)
                    .build();
            walletMapper.insert(wallet);
        }
        // SQL乐观锁扣减：AND gold_coins >= #{amount}，返回0行表示余额不足
        int rows = walletMapper.deductGoldCoins(userId, entryCost);
        if (rows == 0) {
            throw new BizException(ErrorCode.GOLD_INSUFFICIENT);
        }
        return walletMapper.selectByUserId(userId).getGoldCoins();
    }

    /** 兑换：total_score / exchange_divisor → 外部金币（整数除法） */
    @Transactional
    public ExchangeResult exchangeScore(String userId, long totalScore) {
        int divisor = configService.getIntConfig("exchange_divisor", 100);
        int goldEarned = (int) (totalScore / Math.max(1, divisor));
        if (goldEarned > 0) {
            walletMapper.addGoldCoins(userId, goldEarned);
        }
        int balance = walletMapper.selectByUserId(userId).getGoldCoins();
        return new ExchangeResult(goldEarned, balance);
    }

    @Data
    @AllArgsConstructor
    public static class ExchangeResult {
        private int goldEarned;
        private int goldCoinsBalance;
    }
}
```

### 4.2 UserWalletMapper

```java
@Mapper
public interface UserWalletMapper extends BaseMapper<UserWallet> {

    @Select("SELECT * FROM user_wallet WHERE user_id = #{userId}")
    UserWallet selectByUserId(@Param("userId") String userId);

    @Update("UPDATE user_wallet SET gold_coins = gold_coins - #{amount}, updated_at = datetime('now') WHERE user_id = #{userId} AND gold_coins >= #{amount}")
    int deductGoldCoins(@Param("userId") String userId, @Param("amount") int amount);

    @Update("UPDATE user_wallet SET gold_coins = gold_coins + #{amount}, updated_at = datetime('now') WHERE user_id = #{userId}")
    int addGoldCoins(@Param("userId") String userId, @Param("amount") int amount);
}
```

> `deductGoldCoins` 使用 `AND gold_coins >= #{amount}` 做乐观锁，防止并发扣减为负。

---

## 5. 前端设计

### 5.1 新增变量

`GameAPI.gd` 新增：
```gdscript
var gold_coins: int = 0  # 外部金币（持久化）
```

`RoundManager.gd` — 无需新增变量，`game_coins` 已存在且含义不变（局内代币）。

### 5.2 `GameAPI.gd` 新增接口

```gdscript
# GET /api/wallet/balance
func get_wallet_balance() -> void:
    _http_get("/api/wallet/balance", func(response: Dictionary):
        var data = response.get("data", {})
        gold_coins = int(data.get("gold_coins", 0))
        wallet_balance_loaded.emit(gold_coins)
    )

signal wallet_balance_loaded(balance: int)
```

### 5.3 `GameAPI.gd` 修改 `start_game()`

```gdscript
func start_game():
    _http_post("/api/game/start", {}, func(response: Dictionary):
        var data = response.get("data", {})
        session_id = int(data.get("session_id", 0))
        gold_coins = int(data.get("gold_coins", 0))  # ← 新增：同步外部金币
        ConfigLoader.load_from_server(data)
        game_started.emit(data)
    )
```

### 5.4 `GameAPI.gd` 修改 `submit_result()`

```gdscript
func submit_result():
    _http_post("/api/game/submit_result", {"session_id": session_id}, func(response: Dictionary):
        var data = response.get("data", {})
        gold_coins = int(data.get("gold_coins", 0))  # ← 新增：同步外部金币
        result_submitted.emit(data)
    )
```

### 5.5 主界面 `MainUI.gd` 修改

**展示外部金币**：主菜单显示当前外部金币余额。

```
进入主菜单时：
  1. GameAPI.get_wallet_balance() → 获取余额
  2. 显示 "💰 外部金币: XX" 标签
  3. 开始按钮：余额 ≥ 入场费 → 可点击；余额 < 入场费 → 灰色 + 提示"金币不足"
```

**开始游戏前检查**：
```
_on_start_pressed():
  if gold_coins < entry_cost:
      显示提示 "外部金币不足，需要 {entry_cost} 金币"
      return
  GameAPI.start_game()
```

### 5.6 结算界面 `ResultUI.gd` 修改

**展示兑换信息**：

```
_on_result_received(data):
  现有展示不变（总分、排名、奖品）
  新增：
    gold_earned_label.text = "💰 兑换 +%d 外部金币" % data.get("gold_earned", 0)
    gold_balance_label.text = "余额: %d" % data.get("gold_coins", 0)
```

### 5.7 本地存档 `GameState.gd` 修改

```gdscript
# save_state 新增
"gold_coins": GameAPI.gold_coins,

# _restore_from_dict 新增
GameAPI.gold_coins = state.get("gold_coins", 100)  # 默认100
```

---

## 6. 依赖关系

| 本模块依赖 | 说明 |
|---|---|
| ConfigService | 读取 entry_cost / score_exchange_rate / initial_gold_coins |
| ErrorCode 枚举 | 新增 GOLD_INSUFFICIENT(5002) |
| game/ 包 | 无依赖（纯逻辑不涉及货币） |

| 被依赖 | 说明 |
|---|---|
| GameController.start | 调用 WalletService.deductEntryCost |
| GameController.submitResult | 调用 WalletService.exchangeScore |
| WalletController.balance | 调用 WalletService.getOrCreateBalance |

---

## 7. 异常处理

| 场景 | 错误码 | 处理 |
|---|---|---|
| 外部金币不足，无法开始 | 5002 | 返回错误，前端提示"金币不足" |
| 钱包并发扣减 | — | `deductGoldCoins` SQL 乐观锁，返回 0 行时重抛 GOLD_INSUFFICIENT |
| 兑换时钱包不存在 | — | `getOrCreateBalance` 自动创建，不会报错 |
| 服务重启 | — | wallet 数据在 SQLite 持久化，不丢失 |

---

## 8. 测试策略

### 后端单元测试

| 测试 | 场景 |
|---|---|
| WalletServiceTest | 新用户自动创建 + 赠送初始金币 |
| WalletServiceTest | 正常扣减入场费 |
| WalletServiceTest | 余额不足拒绝扣减 |
| WalletServiceTest | 总分兑换外部金币（rate=0.01，score=8500 → 85） |
| WalletServiceTest | 兑换 0 分不加减金币 |
| WalletServiceTest | 并发扣减乐观锁 |
| GameControllerTest | start 余额不足返回 5002 |
| GameControllerTest | submit_result 返回 gold_earned + gold_coins |
| WalletControllerTest | balance 接口返回正确余额 |

### 前端验证

| 场景 | 验证 |
|---|---|
| 主菜单显示金币 | 启动时调 get_wallet_balance，展示余额 |
| 金币不足无法开始 | 按钮灰色 + 提示 |
| 扣入场费 | start_game 后 gold_coins 减少 |
| 结算兑换 | result_submitted 回调展示 gold_earned |
| 再来一局 | 扣币正常，金币不足则灰按钮 |
| 本地存档 | 关闭重开游戏，外部金币恢复 |

---

## 9. 改动文件清单

### 后端

| 文件 | 操作 | 说明 |
|---|---|---|
| `schema.sql` | 修改 | 新增 user_wallet 表 |
| `data.sql` | 修改 | 新增 3 条 game_config |
| `UserWallet.java` | 新增 | Entity |
| `UserWalletMapper.java` | 新增 | Mapper + selectByUserId / deductGoldCoins / addGoldCoins |
| `WalletService.java` | 新增 | 钱包业务逻辑 |
| `WalletController.java` | 新增 | GET /api/wallet/balance |
| `ErrorCode.java` | 修改 | 新增 GOLD_INSUFFICIENT(5002) |
| `GameController.java` | 修改 | start 调 deductEntryCost，submitResult 调 exchangeScore |
| `GameService.java` | 无变更 | 不涉及货币 |
| `ConfigService.java` | 修改 | 新增 getDoubleConfig() |

### 前端

| 文件 | 操作 | 说明 |
|---|---|---|
| `GameAPI.gd` | 修改 | 新增 gold_coins 变量 + get_wallet_balance() + 修改 start_game/submit_result 回调 |
| `MainUI.gd` | 修改 | 主菜单展示外部金币 + 金币不足检查 |
| `ResultUI.gd` | 修改 | 结算页展示兑换金币和余额 |
| `GameState.gd` | 修改 | 存档/读档新增 gold_coins |

---

## 10. 数值推导

以默认配置 `entry_cost=10, exchange_rate=0.01, initial_gold_coins=100` 为例：

| 场景 | 总分 | 兑换金币 | 净收益 | 累计金币 |
|---|---|---|---|---|
| 刚注册 | — | — | — | 100 |
| 第1局打很差 | 500 | 5 | -5 | 95 |
| 第1局打一般 | 3000 | 30 | +20 | 120 |
| 第1局打很好 | 8000 | 80 | +70 | 170 |
| 一直打很差连续10局 | 500×10 | 5×10 | -50 | 50（还够打5局） |
| 通关Boss | 10000+ | 100+ | +90+ | 190+ |

**结论**：默认配置下，打得好稳赚，打得差也够打很多局（100 初始币 = 10 局保底），不会太快弹尽粮绝。
