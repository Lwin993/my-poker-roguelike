-- Initial data for poker_roguelike.db
-- Using OR IGNORE to support repeated execution
-- v3.1: Updated thresholds, coin_rewards, and reward_tier for new HP curve

INSERT OR REPLACE INTO game_config (config_key, config_value) VALUES
('round_thresholds', '[[300,600,1500],[1000,2500,6000],[3500,8000,15000]]'),
('coin_rewards', '[[50,80,130],[80,130,200],[130,200,300]]'),
('max_revives', '3'),
('score_tolerance', '1'),
('shop_slot_count', '5'),
('refresh_cost_formula', '{"base":5,"increment":5}');

-- v3.1: 奖品档位适配新伤害曲线
INSERT OR REPLACE INTO reward_tier (min_score, max_score, reward_name, reward_type, stock_limit) VALUES
(0,     999,   '参与奖',     'digital', -1),
(1000,  4999,  '雪碧',       'drink',   5000),
(5000,  14999, '奶茶',       'drink',   3000),
(15000, 39999, '奶茶升级券', 'coupon',  1000),
(40000, -1,    '稀有奖品',   'rare',    100);

-- v3.1: 4大法宝 + 道具配置
DELETE FROM item_config WHERE item_id IN ('remain_boost', 'extra_play');

INSERT OR REPLACE INTO item_config (item_id, config_data) VALUES
('artifact_jgb', '{"display_name":"金箍棒","description":"固定增加倍率，稳定增伤","price":35,"rarity":0,"item_type":0,"shop_weights":[30,28,25,22,18,15,12,9,6],"upgrade_costs":[40,80],"effect_class":"JinGuBang","level_params":[{"mult_add":4},{"mult_add":7},{"mult_add":11}]}'),
('artifact_zjl', '{"display_name":"紫金铃","description":"连续打出同牌型，倍率逐次递增","price":45,"rarity":0,"item_type":0,"shop_weights":[22,24,25,24,22,20,18,15,12],"upgrade_costs":[50,100],"effect_class":"ZiJinLing","level_params":[{"mult_per_stack":4},{"mult_per_stack":6},{"mult_per_stack":9}]}'),
('artifact_rsg', '{"display_name":"人参果","description":"低概率触发极高特殊倍率","price":55,"rarity":0,"item_type":0,"shop_weights":[10,12,14,16,18,18,16,14,12],"upgrade_costs":[60,120],"effect_class":"RenShenGuo","level_params":[{"boom_prob":0.05,"boom_mult":10},{"boom_prob":0.08,"boom_mult":15},{"boom_prob":0.12,"boom_mult":25}]}'),
('artifact_hyjj', '{"display_name":"火眼金睛","description":"每战随机花色，匹配牌增加伤害","price":40,"rarity":0,"item_type":0,"shop_weights":[22,22,22,20,18,16,14,12,10],"upgrade_costs":[45,90],"effect_class":"HuoYanJinJing","level_params":[{"chip_per_suit":4},{"chip_per_suit":7},{"chip_per_suit":12}]}'),
('nine_elixir', '{"display_name":"九转金丹","description":"当次出牌伤害+25","price":8,"rarity":0,"item_type":1,"shop_weights":[32,32,30,28,25,22,20,18,15],"effect_class":"NineElixir","level_params":[{"chip_add":25}]}'),
('boss_burst', '{"display_name":"斩妖剑","description":"大妖战当次出牌倍率×3","price":15,"rarity":0,"item_type":1,"shop_weights":[12,15,22,12,15,22,12,15,25],"effect_class":"BossBurst","level_params":[{"mult_factor":3.0}]}'),
('clone_spell', '{"display_name":"分身术","description":"当次出牌倍率+4","price":12,"rarity":0,"item_type":1,"shop_weights":[18,20,20,20,20,18,18,16,15],"effect_class":"CloneSpell","level_params":[{"mult_add":4.0}]}'),
('double_potion', '{"display_name":"狂战药水","description":"当前战斗所有出牌倍率+3","price":15,"rarity":0,"item_type":1,"shop_weights":[18,20,20,20,18,18,16,14,12],"effect_class":"FrenzyPotion","level_params":[{"mult_add":3}]}'),
('crit_potion', '{"display_name":"暴击药水","description":"当次出牌暴击倍率+2.0","price":10,"rarity":0,"item_type":1,"shop_weights":[20,20,20,20,18,16,15,14,12],"effect_class":"CritPotion","level_params":[{"crit_mult_add":2.0}]}'),
('freeze_spell', '{"display_name":"定身术","description":"立即增加1次出牌机会","price":10,"rarity":0,"item_type":1,"shop_weights":[24,24,22,20,18,16,14,12,10],"effect_class":"FreezeSpell","level_params":[{"extra_plays":1}]}'),
('far_sight', '{"display_name":"千里眼","description":"立即增加2次换牌机会","price":8,"rarity":0,"item_type":1,"shop_weights":[24,24,22,20,18,16,14,12,10],"effect_class":"FarSight","level_params":[{"extra_discards":2}]}'),
('final_play_ticket', '{"display_name":"终局符","description":"大妖战立即增加1次出牌机会","price":18,"rarity":0,"item_type":1,"shop_weights":[5,8,18,5,8,20,5,8,22],"effect_class":"FinalPlayTicket","level_params":[{"extra_plays":1}]}'),
('refresh_ticket', '{"display_name":"仙铺刷新券","description":"下次仙铺刷新免费","price":5,"rarity":0,"item_type":1,"shop_weights":[30,28,26,24,22,20,18,16,14],"effect_class":"RefreshTicket","level_params":[]}'),
('mirror_reveal', '{"display_name":"照妖镜","description":"白骨精战破除幻术，持续整场战斗","price":20,"rarity":1,"item_type":1,"shop_weights":[16,12,8,5,4,3,2,2,2],"effect_class":"MirrorReveal","level_params":[]}'),
('wind_calmer', '{"display_name":"定风丹","description":"黄风怪战免疫遮挡，持续整场战斗","price":20,"rarity":1,"item_type":1,"shop_weights":[3,5,6,16,12,8,5,4,3],"effect_class":"WindCalmer","level_params":[]}'),
('holy_dew', '{"display_name":"净瓶甘露","description":"红孩儿战熄灭真火，持续整场战斗","price":20,"rarity":1,"item_type":1,"shop_weights":[2,2,3,3,5,6,16,12,10],"effect_class":"HolyDew","level_params":[]}'),
('quint_crit', '{"display_name":"五连暴击","description":"当前战斗暴击率提升至50%","price":30,"rarity":1,"item_type":1,"shop_weights":[6,7,8,9,10,11,12,12,10],"effect_class":"QuintCrit","level_params":[{"crit_rate_add":0.45}]}'),
('cloud_step', '{"display_name":"筋斗云","description":"当前战斗手牌上限8→9张","price":25,"rarity":1,"item_type":1,"shop_weights":[7,8,9,10,10,10,10,9,8],"effect_class":"CloudStep","level_params":[{"hand_size_add":1}]}'),
('seventy_two', '{"display_name":"七十二变","description":"随机复制1个法宝Lv1效果，永久生效","price":35,"rarity":1,"item_type":1,"shop_weights":[4,5,6,7,8,9,10,10,8],"effect_class":"SeventyTwo","level_params":[]}');

-- Dual currency config
INSERT OR IGNORE INTO game_config (config_key, config_value) VALUES
('entry_cost', '10'),
('exchange_divisor', '100'),
('initial_gold_coins', '100');
