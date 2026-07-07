# Review Report — 模块1：伤害计算系统改造

> 审查时间：2026-07-07 | 审查范围：docs/migration_plan_v3.1.md 第2章 + 现有代码

## 🟠 P1 问题（需修复）

### P1-1: PlaySnapshotDTO 缺少 chips 字段
- **现状**: `PlaySnapshotDTO` 只有 `handRank/baseScore/mult/isCrit/critMult/specialMult`
- **问题**: 双维度系统中客户端需上报 `chips` 值给服务端验证，但DTO缺少此字段
- **建议**: 增加 `int chips` 和 `double baseMult` 字段

### P1-2: ScoreResult 缺少 chips 字段
- **现状**: `ScoreResult` 只有 `score/isCrit/mult`
- **问题**: 双维度验证需要chips值对比，且前端UI展示需要显示chips×mult分解
- **建议**: 增加 `int chips` 和 `double baseMult` 字段

### P1-3: GameService.submitPlay() 验证逻辑需同步改
- **现状**: 只验证 `handRank` 和 `claimed` 分数
- **问题**: 双维度下验证逻辑需改为：1)验证handRank; 2)验证chips(含手牌面值); 3)验证最终score
- **建议**: 增加 chips 验证，且 Card 需传入 getChipValue()

### P1-4: HandEvaluator 缺少 cards 传递
- **现状**: 前端 HandEvaluator.evaluate(cards) 只返回 `rank/base_score/hand_name`
- **问题**: 新公式中 `chips = baseChips + cardChipValues`，需要把cards信息传入ScoreCalculator
- **建议**: HandResult 增加 `cards` 引用，或 ScoreCalculator 单独接收 played_cards 参数

### P1-5: ItemModifier 缺少链式状态接口
- **现状**: `applyMult(double, int, Random)` — 无状态传递
- **问题**: 紫金铃(连锁)需要知道"连续同牌型次数"，火眼金睛需要知道"指定花色"，这些状态在服务端ItemModifier中无法表达
- **建议**: 增加 `HandContext` 参数传递牌局上下文（consecutive count, designated suit等）

## 🟢 P2 建议（可选改进）

### P2-1: 考虑 HandResult 增加返回 cards 引用
- 方便后续火眼金睛等法宝遍历手牌计算 chip_add
- 可避免 ScoreCalculator 重复传入 cards

### P2-2: 考虑统一前端的 snapshot 字段名
- 现有: `base_score` → 建议改为 `base_chips` 保持一致性
- 前端和后端 DTO 字段名需完全对齐

### P2-3: play_log 表可增加 chips/mult 列
- 方便后期分析Build分布和伤害来源
- 但非必须，snapshot JSON 中已含信息

## ⚪ P3 讨论

### P3-1: ItemModifier 链式状态的多种实现方式
- 方案A: 增加 HandContext 参数（推荐，最灵活）
- 方案B: 每个 Modifier 持有自身状态（类似前端JokerChain的_consecutive）
- 方案C: 纯数据驱动，从 handResult 推断

### P3-2: 迁移策略：是否需要版本兼容
- 如果有线上用户，需考虑旧session的baseScore与新baseChips的兼容
- 当前看是全新项目，可无需兼容层

## ✅ 确认正确的设计点

1. **chips×mult 双维度架构** — 与 Balatro 一致，是核心爽感来源
2. **牌面值映射** (A=11, 2-10=点数, JQK=10) — 与v3.1文档完全一致
3. **HandRank 双字段** (baseChips + baseMult) — 数据模型正确
4. **暴击倍率 ×2.0** — 替代旧 ×1.5，符合v3.1设计
5. **计算顺序**: chips叠加 → mult叠加 → 暴击判定 → specialMult — 乘法叠加逻辑正确
6. **ItemModifier 增加 applyChipAdd()** — 接口扩展方向正确
