-- Initial data for poker_roguelike.db
-- Using OR IGNORE to support repeated execution
-- v3.1: Updated thresholds, coin_rewards, and reward_tier for new HP curve

INSERT OR IGNORE INTO game_config (config_key, config_value) VALUES
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
INSERT OR REPLACE INTO item_config (item_id, config_data) VALUES
('artifact_jgb', '{"display_name":"金箍棒","description":"+倍率(稳定增伤)","price":35,"rarity":0,"item_type":0,"shop_weights":[30,25,20,15,10,5],"upgrade_costs":[40,80],"effect_class":"JinGuBang","level_params":[{"mult_add":4},{"mult_add":7},{"mult_add":11}]}'),
('artifact_zjl', '{"display_name":"紫金铃","description":"连锁+倍率(连续同牌型递增)","price":45,"rarity":0,"item_type":0,"shop_weights":[25,25,25,20,15,10],"upgrade_costs":[50,100],"effect_class":"ZiJinLing","level_params":[{"mult_per_stack":4},{"mult_per_stack":6},{"mult_per_stack":9}]}'),
('artifact_rsg', '{"display_name":"人参果","description":"低概率×极高倍率","price":55,"rarity":0,"item_type":0,"shop_weights":[15,12,15,18,15,10],"upgrade_costs":[60,120],"effect_class":"RenShenGuo","level_params":[{"boom_prob":0.05,"boom_mult":10},{"boom_prob":0.08,"boom_mult":15},{"boom_prob":0.12,"boom_mult":25}]}'),
('artifact_hyjj', '{"display_name":"火眼金睛","description":"+伤害/指定花色每张牌","price":40,"rarity":0,"item_type":0,"shop_weights":[20,20,20,18,15,10],"upgrade_costs":[45,90],"effect_class":"HuoYanJinJing","level_params":[{"chip_per_suit":4},{"chip_per_suit":7},{"chip_per_suit":12}]}'),
-- 保留旧道具(将在Module 5更新)
('double_potion', '{"display_name":"狂战药水","description":"回合倍率+3","price":10,"rarity":0,"item_type":1,"shop_weights":[25,25,25,20,15,10],"effect_class":"FrenzyPotion","level_params":[{"mult_add":3}]}'),
('boss_burst', '{"display_name":"斩妖剑","description":"大妖回合倍率×3","price":15,"rarity":0,"item_type":1,"shop_weights":[15,15,15,18,15,10],"effect_class":"BossBurst","level_params":[{"mult_factor":3.0}]}'),
('extra_play', '{"display_name":"终局符","description":"出牌次数+1","price":10,"rarity":0,"item_type":1,"shop_weights":[30,30,30,25,20,15],"effect_class":"ExtraPlayTicket","level_params":[{"extra_plays":1}]}'),
('refresh_ticket', '{"display_name":"刷新券","description":"下次商店刷新免费","price":5,"rarity":0,"item_type":1,"shop_weights":[40,40,40,35,30,25],"effect_class":"RefreshTicket","level_params":[]}'),
-- v3.1: 新增道具
('crit_potion', '{"display_name":"暴击药水","description":"暴击倍率+2.0","price":10,"rarity":0,"item_type":1,"shop_weights":[20,20,20,18,15,10],"effect_class":"CritPotion","level_params":[{"crit_mult_add":2.0}]}'),
('nine_elixir', '{"display_name":"九转金丹","description":"本回合伤害+25","price":8,"rarity":0,"item_type":1,"shop_weights":[30,30,30,25,20,15],"effect_class":"NineElixir","level_params":[{"chip_add":25}]}'),
('far_sight', '{"display_name":"千里眼","description":"换牌+2","price":8,"rarity":0,"item_type":1,"shop_weights":[25,25,25,20,15,10],"effect_class":"FarSight","level_params":[{"extra_discards":2}]}'),
('freeze_spell', '{"display_name":"定身术","description":"出牌+1","price":10,"rarity":0,"item_type":1,"shop_weights":[25,25,25,20,15,10],"effect_class":"FreezeSpell","level_params":[{"extra_plays":1}]}'),
('cloud_step', '{"display_name":"筋斗云","description":"手牌上限+1(回合持续)","price":25,"rarity":1,"item_type":1,"shop_weights":[10,10,10,12,15,10],"effect_class":"CloudStep","level_params":[{"hand_size_add":1}]}'),
('clone_spell', '{"display_name":"分身术","description":"倍率×2","price":12,"rarity":0,"item_type":1,"shop_weights":[15,15,15,18,15,10],"effect_class":"CloneSpell","level_params":[{"mult_factor":2.0}]}'),
('remain_boost', '{"display_name":"余牌加持","description":"剩余手牌最高点数加倍率","price":25,"rarity":1,"item_type":1,"shop_weights":[10,10,10,12,15,10],"effect_class":"RemainBoost","level_params":[]}'),
('quint_crit', '{"display_name":"五连暴击","description":"整回合暴击率50%","price":30,"rarity":1,"item_type":1,"shop_weights":[8,8,8,10,12,10],"effect_class":"QuintCrit","level_params":[{"crit_rate_add":0.45}]}'),
('mirror_reveal', '{"display_name":"照妖镜","description":"破除白骨幻术1回合","price":15,"rarity":0,"item_type":1,"shop_weights":[15,10,5,5,5,5],"effect_class":"MirrorReveal","level_params":[]}'),
('wind_calmer', '{"display_name":"定风丹","description":"免疫风沙遮挡1回合","price":15,"rarity":0,"item_type":1,"shop_weights":[5,15,10,5,5,5],"effect_class":"WindCalmer","level_params":[]}'),
('holy_dew', '{"display_name":"净瓶甘露","description":"熄灭三昧真火1回合","price":15,"rarity":0,"item_type":1,"shop_weights":[5,5,15,10,5,5],"effect_class":"HolyDew","level_params":[]}');

-- Dual currency config
INSERT OR IGNORE INTO game_config (config_key, config_value) VALUES
('entry_cost', '10'),
('exchange_divisor', '100'),
('initial_gold_coins', '100');
