const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

// 数据库文件路径
const dataDir = path.join(__dirname, '../data');
const dbPath = path.join(dataDir, 'listenvision.db');

// 确保 data 目录存在
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// 创建数据库实例（verbose 用于开发环境 SQL 日志）
const db = new Database(dbPath, { verbose: console.log });

// 启用外键约束
db.pragma('foreign_keys = ON');

// 性能优化：WAL 模式提高并发，NORMAL 平衡性能和安全
db.pragma('journal_mode = WAL');
db.pragma('synchronous = NORMAL');

// 初始化数据库表结构
const createTables = () => {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      reset_code TEXT,
      code_expire TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      title TEXT NOT NULL,
      username TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
    )
  `);

  // 创建索引加速查询
  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_favorites_username ON favorites(username);
    CREATE INDEX IF NOT EXISTS idx_favorites_url ON favorites(url);
  `);

  console.log('✅ 数据库表初始化完成');
};

createTables();

// 优雅退出处理
const gracefulShutdown = () => {
  db.close();
  console.log('数据库连接已关闭');
};

process.on('exit', gracefulShutdown);
process.on('SIGINT', () => {
  gracefulShutdown();
  process.exit(0);
});
process.on('SIGTERM', () => {
  gracefulShutdown();
  process.exit(0);
});

module.exports = db;
