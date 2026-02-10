const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');
const { logger } = require('../utils/logger');

// 数据库文件路径
const dataDir = path.join(__dirname, '../data');
const dbPath = path.join(dataDir, 'listenvision.db');

// 确保 data 目录存在
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// 创建数据库实例（verbose 用于开发环境 SQL 日志）
// 使用 logger.debug 记录 SQL 执行日志
const db = new Database(dbPath, {
  verbose: process.env.NODE_ENV === 'development'
    ? (msg) => logger.debug('SQLite: ' + msg)
    : undefined
});

// 启用外键约束
db.pragma('foreign_keys = ON');

// 性能优化：WAL 模式提高并发，NORMAL 平衡性能和安全
db.pragma('journal_mode = WAL');
db.pragma('synchronous = NORMAL');

// 初始化数据库表结构
const createTables = () => {
  // 用户表
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      email_verified INTEGER DEFAULT 0,
      reset_code TEXT,
      code_expire TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // 待验证注册表（注册邮箱验证）
  db.exec(`
    CREATE TABLE IF NOT EXISTS pending_registrations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      verify_code TEXT NOT NULL,
      code_expire TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // B站账号绑定表
  db.exec(`
    CREATE TABLE IF NOT EXISTS bilibili_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      bili_user_id TEXT,
      bili_username TEXT,
      cookie_encrypted TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      expires_at TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 音频元数据缓存表
  db.exec(`
    CREATE TABLE IF NOT EXISTS audio_metadata_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT UNIQUE NOT NULL,
      title TEXT,
      artist TEXT,
      duration INTEGER,
      cover_url TEXT,
      audio_url TEXT,
      cid INTEGER,
      metadata TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // 音频内容缓存表（存储转换后的音频数据）
  db.exec(`
    CREATE TABLE IF NOT EXISTS audio_content_cache (
      bvid TEXT PRIMARY KEY,
      data BLOB NOT NULL,
      content_type TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // 搜索历史表
  db.exec(`
    CREATE TABLE IF NOT EXISTS search_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      keyword TEXT NOT NULL,
      result_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // ========== Phase 2: 歌单系统 ==========

  // 歌单表
  db.exec(`
    CREATE TABLE IF NOT EXISTS playlists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      cover_url TEXT,
      type TEXT DEFAULT 'user',
      system_type TEXT,
      is_public INTEGER DEFAULT 0,
      play_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 歌单项表
  db.exec(`
    CREATE TABLE IF NOT EXISTS playlist_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playlist_id INTEGER NOT NULL,
      bvid TEXT NOT NULL,
      title TEXT,
      artist TEXT,
      duration INTEGER,
      cover_url TEXT,
      position INTEGER NOT NULL DEFAULT 0,
      added_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
      UNIQUE(playlist_id, bvid)
    )
  `);

  // 播放历史表
  // Phase 2 遗留问题: 添加 audio_type 和 local_path 支持本地音频记录
  db.exec(`
    CREATE TABLE IF NOT EXISTS play_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      bvid TEXT,
      local_path TEXT,
      audio_type TEXT DEFAULT 'online' CHECK(audio_type IN ('online', 'local')),
      title TEXT,
      artist TEXT,
      duration INTEGER,
      cover_url TEXT,
      played_at TEXT DEFAULT (datetime('now')),
      progress INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 为已有表添加新字段（ALTER TABLE 仅在字段不存在时执行）
  // SQLite 不支持 IF EXISTS for ALTER TABLE，需要捕获错误
  try {
    db.exec(`ALTER TABLE play_history ADD COLUMN audio_type TEXT DEFAULT 'online'`);
  } catch (e) {
    // 字段已存在，忽略错误
  }
  try {
    db.exec(`ALTER TABLE play_history ADD COLUMN local_path TEXT`);
  } catch (e) {
    // 字段已存在，忽略错误
  }

  // ========== Phase 3: 搜索优化与推荐 ==========

  // FTS5 全文搜索虚拟表
  // 使用 unicode61 分词器（SQLite 内置，支持中文）
  db.exec(`
    CREATE VIRTUAL TABLE IF NOT EXISTS audio_metadata_cache_fts USING fts5(
      title,
      artist,
      content='audio_metadata_cache',
      tokenize='unicode61'
    )
  `);

  // FTS 同步触发器
  db.exec(`
    CREATE TRIGGER IF NOT EXISTS fts_insert AFTER INSERT ON audio_metadata_cache BEGIN
      INSERT INTO audio_metadata_cache_fts(rowid, title, artist) VALUES (NEW.id, NEW.title, NEW.artist);
    END;

    CREATE TRIGGER IF NOT EXISTS fts_delete AFTER DELETE ON audio_metadata_cache BEGIN
      INSERT INTO audio_metadata_cache_fts(audio_metadata_cache_fts, rowid, title, artist) VALUES ('delete', OLD.id, OLD.title, OLD.artist);
    END;

    CREATE TRIGGER IF NOT EXISTS fts_update AFTER UPDATE ON audio_metadata_cache BEGIN
      INSERT INTO audio_metadata_cache_fts(audio_metadata_cache_fts, rowid, title, artist) VALUES ('delete', OLD.id, OLD.title, OLD.artist);
      INSERT INTO audio_metadata_cache_fts(rowid, title, artist) VALUES (NEW.id, NEW.title, NEW.artist);
    END;
  `);

  // 搜索统计表
  db.exec(`
    CREATE TABLE IF NOT EXISTS search_stats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT NOT NULL UNIQUE,
      search_count INTEGER DEFAULT 1,
      last_searched TEXT DEFAULT (datetime('now'))
    )
  `);

  // 用户行为日志表
  db.exec(`
    CREATE TABLE IF NOT EXISTS user_behavior_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      bvid TEXT NOT NULL,
      action TEXT CHECK(action IN ('play', 'like', 'skip', 'share')),
      timestamp TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 创建索引加速查询
  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_bilibili_accounts_user_id ON bilibili_accounts(user_id);
    CREATE INDEX IF NOT EXISTS idx_bilibili_accounts_is_active ON bilibili_accounts(user_id, is_active);
    CREATE INDEX IF NOT EXISTS idx_audio_metadata_bvid ON audio_metadata_cache(bvid);
    CREATE INDEX IF NOT EXISTS idx_search_history_user_id ON search_history(user_id);
    CREATE INDEX IF NOT EXISTS idx_audio_content_cache_bvid ON audio_content_cache(bvid);
    CREATE INDEX IF NOT EXISTS idx_audio_content_cache_created ON audio_content_cache(created_at);
    CREATE INDEX IF NOT EXISTS idx_search_history_keyword ON search_history(user_id, keyword);
    -- Phase 2: 歌单系统索引
    CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON playlists(user_id);
    CREATE INDEX IF NOT EXISTS idx_playlists_type ON playlists(user_id, type);
    CREATE INDEX IF NOT EXISTS idx_playlists_system_type ON playlists(user_id, system_type);
    CREATE INDEX IF NOT EXISTS idx_playlist_items_playlist_id ON playlist_items(playlist_id);
    CREATE INDEX IF NOT EXISTS idx_playlist_items_position ON playlist_items(playlist_id, position);
    CREATE INDEX IF NOT EXISTS idx_play_history_user_id ON play_history(user_id);
    CREATE INDEX IF NOT EXISTS idx_play_history_played_at ON play_history(user_id, played_at);
    CREATE INDEX IF NOT EXISTS idx_play_history_identifier ON play_history(user_id, bvid, local_path);
    -- Phase 3: 搜索与推荐索引
    CREATE INDEX IF NOT EXISTS idx_search_stats_keyword ON search_stats(keyword);
    CREATE INDEX IF NOT EXISTS idx_search_stats_count ON search_stats(search_count);
    CREATE INDEX IF NOT EXISTS idx_user_behavior_logs_user_action ON user_behavior_logs(user_id, action, timestamp);
    CREATE INDEX IF NOT EXISTS idx_user_behavior_logs_bvid ON user_behavior_logs(bvid);
  `);

  logger.info('Database tables initialized successfully');
};

// 迁移：为 playlist_items 表添加 local_path 字段
// 支持本地音频的文件路径存储
const migratePlaylistItems = () => {
  try {
    const tableInfo = db.pragma('table_info(playlist_items)');
    const localPathColumn = tableInfo.find(col => col.name === 'local_path');

    if (!localPathColumn) {
      logger.info('Adding local_path column to playlist_items table...');

      try {
        db.exec(`ALTER TABLE playlist_items ADD COLUMN local_path TEXT`);
        logger.info('playlist_items.local_path column added successfully');
      } catch (e) {
        // 字段已存在，忽略错误
        logger.debug('playlist_items.local_path column already exists or error:', e.message);
      }
    } else {
      logger.info('playlist_items table already has local_path column');
    }
  } catch (e) {
    logger.error('playlist_items table migration failed:', e.message);
  }
};

// 迁移：修复 play_history 表的 bvid 字段约束
// 使其支持本地音频（bvid 可为 NULL）
const migratePlayHistory = () => {
  try {
    // 检查表是否存在
    const tableInfo = db.pragma('table_info(play_history)');

    // 找到 bvid 列的定义
    const bvidColumn = tableInfo.find(col => col.name === 'bvid');

    if (bvidColumn && bvidColumn.notnull === 1) {
      logger.info('Detected old play_history table, starting migration...');

      // SQLite 不支持直接修改列约束，需要重建表
      db.exec(`
        -- 开始事务
        BEGIN TRANSACTION;

        -- 1. 创建新表（bvid 可为 NULL）
        CREATE TABLE play_history_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          bvid TEXT,
          local_path TEXT,
          audio_type TEXT DEFAULT 'online',
          title TEXT,
          artist TEXT,
          duration INTEGER,
          cover_url TEXT,
          played_at TEXT DEFAULT (datetime('now')),
          progress INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );

        -- 2. 复制数据（处理可能的 NULL 或非法 audio_type 值）
        INSERT INTO play_history_new (id, user_id, bvid, local_path, audio_type, title, artist, duration, cover_url, played_at, progress)
          SELECT
            id,
            user_id,
            bvid,
            COALESCE(local_path, '') as local_path,
            CASE
              WHEN audio_type IS NULL THEN 'online'
              WHEN audio_type NOT IN ('online', 'local') THEN 'online'
              ELSE audio_type
            END as audio_type,
            title,
            artist,
            duration,
            cover_url,
            played_at,
            progress
          FROM play_history;

        -- 3. 删除旧表
        DROP TABLE play_history;

        -- 4. 重命名新表
        ALTER TABLE play_history_new RENAME TO play_history;

        -- 5. 重建索引
        CREATE INDEX IF NOT EXISTS idx_play_history_user_id ON play_history(user_id);
        CREATE INDEX IF NOT EXISTS idx_play_history_played_at ON play_history(user_id, played_at);
        CREATE INDEX IF NOT EXISTS idx_play_history_identifier ON play_history(user_id, bvid, local_path);

        COMMIT;
      `);

      logger.info('play_history table migration completed (bvid is now nullable)');
    } else {
      logger.info('play_history table is already up to date');
    }
  } catch (e) {
    logger.error('play_history table migration failed:', e.message);
    // 不中断程序启动，因为新表创建时已经正确
  }
};

// 迁移：为 bilibili_accounts 表添加 refresh_token_encrypted 字段
// 用于 Cookie 自动刷新机制
const migrateBilibiliAccountsRefreshToken = () => {
  try {
    const tableInfo = db.pragma('table_info(bilibili_accounts)');
    const refreshTokenColumn = tableInfo.find(col => col.name === 'refresh_token_encrypted');

    if (!refreshTokenColumn) {
      logger.info('Adding refresh_token_encrypted column to bilibili_accounts table...');

      try {
        db.exec(`ALTER TABLE bilibili_accounts ADD COLUMN refresh_token_encrypted TEXT`);
        logger.info('bilibili_accounts.refresh_token_encrypted column added successfully');
      } catch (e) {
        logger.debug('bilibili_accounts.refresh_token_encrypted column already exists or error:', e.message);
      }
    } else {
      logger.info('bilibili_accounts table already has refresh_token_encrypted column');
    }
  } catch (e) {
    logger.error('bilibili_accounts table migration failed:', e.message);
  }
};

// 迁移：为 users 表添加 email_verified 字段
const migrateUsersEmailVerified = () => {
  try {
    const tableInfo = db.pragma('table_info(users)');
    const emailVerifiedColumn = tableInfo.find(col => col.name === 'email_verified');

    if (!emailVerifiedColumn) {
      logger.info('Adding email_verified column to users table...');

      try {
        db.exec(`ALTER TABLE users ADD COLUMN email_verified INTEGER DEFAULT 1`);
        logger.info('users.email_verified column added successfully (default 1 for existing users)');
      } catch (e) {
        logger.debug('users.email_verified column already exists or error:', e.message);
      }
    } else {
      logger.info('users table already has email_verified column');
    }
  } catch (e) {
    logger.error('users table migration failed:', e.message);
  }
};

// 先创建表，再执行迁移
createTables();
migratePlaylistItems();
migratePlayHistory();
migrateBilibiliAccountsRefreshToken();
migrateUsersEmailVerified();

// 优雅退出处理（由 index.js 统一管理）
const closeDatabase = () => {
  db.close();
  logger.info('Database connection closed');
};

module.exports = db;
