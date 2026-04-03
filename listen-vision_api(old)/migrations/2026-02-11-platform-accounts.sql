-- 创建统一平台账号表
-- 支持多平台绑定（bilibili, netease 等）

CREATE TABLE IF NOT EXISTS platform_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  platform TEXT NOT NULL,
  platform_user_id TEXT,
  platform_username TEXT,
  cookie_encrypted TEXT,
  token_encrypted TEXT,
  refresh_token_encrypted TEXT,
  is_active INTEGER DEFAULT 1,
  expires_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, platform)
);

CREATE INDEX IF NOT EXISTS idx_platform_accounts_user_id ON platform_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_platform_accounts_platform ON platform_accounts(user_id, platform);
CREATE INDEX IF NOT EXISTS idx_platform_accounts_active ON platform_accounts(is_active, expires_at);

INSERT OR IGNORE INTO platform_accounts (user_id, platform, platform_user_id, platform_username, cookie_encrypted, refresh_token_encrypted, is_active, expires_at, created_at, updated_at)
SELECT user_id, 'bilibili', bili_user_id, bili_username, cookie_encrypted, refresh_token_encrypted, is_active, expires_at, created_at, updated_at
FROM bilibili_accounts;
