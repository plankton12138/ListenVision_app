-- 添加 refresh_token 字段到 bilibili_accounts 表
-- 用于 Cookie 自动刷新机制

-- 添加 refresh_token_encrypted 列
ALTER TABLE bilibili_accounts ADD COLUMN refresh_token_encrypted TEXT;

-- 添加索引以加速查询
CREATE INDEX IF NOT EXISTS idx_bilibili_accounts_active ON bilibili_accounts(is_active, expires_at);
