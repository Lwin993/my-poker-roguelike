-- poker_roguelike.db Schema (SQLite 3.x)
-- Using IF NOT EXISTS to support spring.sql.init.mode=always

CREATE TABLE IF NOT EXISTS game_session (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          TEXT    NOT NULL,
    start_time       TEXT    NOT NULL,
    end_time         TEXT,
    total_score      INTEGER NOT NULL DEFAULT 0,
    status           INTEGER NOT NULL DEFAULT 0,
    rng_seed         INTEGER NOT NULL,
    revive_count     INTEGER NOT NULL DEFAULT 0,
    game_coins       INTEGER NOT NULL DEFAULT 0,
    joker_states     TEXT,
    owned_consumables TEXT,
    created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_session_user_id ON game_session(user_id);
CREATE INDEX IF NOT EXISTS idx_session_score   ON game_session(total_score DESC);
CREATE INDEX IF NOT EXISTS idx_session_created ON game_session(created_at);

CREATE TABLE IF NOT EXISTS play_log (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id   INTEGER NOT NULL,
    round_idx    INTEGER NOT NULL,
    blind_idx    INTEGER NOT NULL,
    play_idx     INTEGER NOT NULL,
    cards_json   TEXT    NOT NULL,
    consumables  TEXT,
    score        INTEGER NOT NULL,
    is_crit      INTEGER NOT NULL DEFAULT 0,
    snapshot     TEXT    NOT NULL,
    server_score INTEGER,
    diff         INTEGER,
    created_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_play_log_session ON play_log(session_id);

CREATE TABLE IF NOT EXISTS ad_callback_log (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    trans_id        TEXT NOT NULL UNIQUE,
    callback_token  TEXT NOT NULL,
    user_id         TEXT NOT NULL,
    session_id      INTEGER NOT NULL,
    ad_type         TEXT NOT NULL,
    scene           TEXT NOT NULL,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_ad_token ON ad_callback_log(callback_token);
CREATE INDEX IF NOT EXISTS idx_ad_user_session ON ad_callback_log(user_id, session_id);

CREATE TABLE IF NOT EXISTS reward_tier (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    min_score    INTEGER NOT NULL,
    max_score    INTEGER NOT NULL,
    reward_name  TEXT    NOT NULL,
    reward_type  TEXT    NOT NULL,
    stock_limit  INTEGER NOT NULL DEFAULT -1,
    stock_used   INTEGER NOT NULL DEFAULT 0,
    is_active    INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_reward_score_range ON reward_tier(min_score, max_score);

CREATE TABLE IF NOT EXISTS reward_claim (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      TEXT    NOT NULL,
    session_id   INTEGER NOT NULL,
    tier_id      INTEGER NOT NULL,
    status       INTEGER NOT NULL DEFAULT 0,
    fail_reason  TEXT,
    created_at   TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE(user_id, session_id)
);

CREATE TABLE IF NOT EXISTS game_config (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    config_key   TEXT NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    version      INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS item_config (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id      TEXT NOT NULL UNIQUE,
    config_data  TEXT NOT NULL,
    version      INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS user_wallet (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      TEXT    NOT NULL UNIQUE,
    gold_coins   INTEGER NOT NULL DEFAULT 0,
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
