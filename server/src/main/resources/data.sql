-- Initial data for poker_roguelike.db
-- Using OR IGNORE to support repeated execution

INSERT OR IGNORE INTO game_config (config_key, config_value) VALUES
('round_thresholds', '[[300,800,1500],[1500,3000,5000],[3500,6000,10000]]'),
('coin_rewards', '[[30,50,80],[50,80,120],[80,120,180]]'),
('max_revives', '3'),
('score_tolerance', '1'),
('shop_slot_count', '5'),
('refresh_cost_formula', '{"base":5,"increment":5}');

INSERT OR IGNORE INTO reward_tier (min_score, max_score, reward_name, reward_type, stock_limit) VALUES
(0,     999,   '参与奖',     'digital', -1),
(1000,  2999,  '雪碧',       'drink',   5000),
(3000,  5999,  '奶茶',       'drink',   3000),
(6000,  9999,  '奶茶升级券', 'coupon',  1000),
(10000, -1,    '稀有奖品',   'rare',    100);

INSERT OR IGNORE INTO item_config (item_id, config_data) VALUES
('joker_wealthy', '{"display_name":"暴富小丑","description":"暴击率+10%,暴击倍率+0.5","price":30,"rarity":0,"item_type":0,"shop_weights":[30,25,20,15,10,5],"upgrade_costs":[40,80],"effect_class":"JokerWealthy","level_params":[{"crit_rate_add":0.10,"crit_mult_add":0.5},{"crit_rate_add":0.18,"crit_mult_add":1.0},{"crit_rate_add":0.25,"crit_mult_add":1.5}]}'),
('joker_chain', '{"display_name":"连锁小丑","description":"连续同牌型倍率提升","price":40,"rarity":0,"item_type":0,"shop_weights":[25,25,25,20,15,10],"upgrade_costs":[50,100],"effect_class":"JokerChain","level_params":[{"chain_mult":0.15},{"chain_mult":0.25},{"chain_mult":0.40}]}'),
('joker_boom', '{"display_name":"爆炸小丑","description":"低概率战斗分额外x10","price":50,"rarity":0,"item_type":0,"shop_weights":[15,12,15,18,15,10],"upgrade_costs":[60,120],"effect_class":"JokerBoom","level_params":[{"boom_prob":0.03,"boom_mult":10.0},{"boom_prob":0.05,"boom_mult":15.0},{"boom_prob":0.08,"boom_mult":20.0}]}'),
('lucky_spark', '{"display_name":"幸运火花","description":"暴击率+20%","price":8,"rarity":0,"item_type":1,"shop_weights":[35,35,35,30,25,20],"effect_class":"LuckySpark","level_params":[{"crit_rate_add":0.20}]}'),
('double_potion', '{"display_name":"双倍药水","description":"倍率x2","price":12,"rarity":0,"item_type":1,"shop_weights":[25,25,25,20,15,10],"effect_class":"DoublePotion","level_params":[{"mult_multiplier":2.0}]}'),
('extra_play', '{"display_name":"额外出牌券","description":"出牌次数+1","price":10,"rarity":0,"item_type":1,"shop_weights":[30,30,30,25,20,15],"effect_class":"ExtraPlayTicket","level_params":[{"extra_plays":1}]}'),
('refresh_ticket', '{"display_name":"刷新券","description":"下次商店刷新免费","price":5,"rarity":0,"item_type":1,"shop_weights":[40,40,40,35,30,25],"effect_class":"RefreshTicket","level_params":[]}');

-- Dual currency config
INSERT OR IGNORE INTO game_config (config_key, config_value) VALUES
('entry_cost', '10'),
('exchange_divisor', '100'),
('initial_gold_coins', '100');
