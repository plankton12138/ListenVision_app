const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

/**
 * better-sqlite3 数据库配置
 *
 * 知识点说明：
 * - better-sqlite3: 同步 API 的 SQLite 原生绑定
 * - 优势: 高性能、自动持久化、事务支持
 * - API: 同步调用，直接返回结果
 */

// 数据库文件路径
const dataDir = path.join(__dirname, '../data');
const dbPath = path.join(dataDir, 'listenvision.db');

// 确保 data 目录存在
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

/**
 * 创建数据库实例
 * - verbose: 启用 SQL 执行日志（开发环境）
 * - fileMustExist: false（不存在则创建）
 */
const db = new Database(dbPath, { verbose: console.log });

// 启用外键约束
db.pragma('foreign_keys = ON');

// 性能优化设置
db.pragma('journal_mode = WAL');  // Write-Ahead Logging，提高并发性能
db.pragma('synchronous = NORMAL'); // 平衡性能和安全

/**
 * 创建数据库表结构
 */
const createTables = () => {
  // 创建用户表
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

  // 创建收藏表
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

  // 创建索引
  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_favorites_username ON favorites(username);
    CREATE INDEX IF NOT EXISTS idx_favorites_url ON favorites(url);
  `);

  console.log('✅ 数据库表初始化完成');
};

createTables();

/**
 * 数据库连接池（兼容原 API）
 *
 * better-sqlite3 不需要连接池，但为了保持代码兼容性，
 * 提供与原 MySQL API 类似的接口
 */
class PoolAdapter {
  constructor(database) {
    this.db = database;
  }

  /**
   * 执行 SQL 查询（兼容 MySQL API）
   * @param {string} sql - SQL 语句
   * @param {Array} params - 参数数组
   * @returns {Array} [rows, fields] - SELECT 返回 [rows, []]，其他返回 [{insertId}]
   */
  execute(sql, params = []) {
    const isSelect = sql.trim().toUpperCase().startsWith('SELECT');

    if (isSelect) {
      // SELECT 查询
      const stmt = this.db.prepare(sql);
      const rows = stmt.all(...params);
      return [rows, []];
    } else {
      // INSERT/UPDATE/DELETE
      const stmt = this.db.prepare(sql);
      const result = stmt.run(...params);
      return [{ insertId: result.lastInsertRowid }];
    }
  }

  /**
   * 获取连接（兼容性方法）
   */
  async getConnection() {
    return this;
  }

  /**
   * 关闭数据库
   */
  close() {
    this.db.close();
  }
}

const pool = new PoolAdapter(db);

/**
 * 优雅退出
 */
process.on('exit', () => {
  pool.close();
});

process.on('SIGINT', () => {
  pool.close();
  process.exit(0);
});

process.on('SIGTERM', () => {
  pool.close();
  process.exit(0);
});

/**
 * 导出数据库连接池
 *
 * 使用方式（兼容原 API）：
 * const pool = require('../config/database');
 * const [results] = await pool.execute(sql, params);
 *
 * 推荐的新方式（更简洁）：
 * const db = require('../config/database').getDb();
 * const row = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
 */
module.exports = {
  /**
   * 获取数据库连接池（兼容原 API）
   */
  getPool: () => pool,

  /**
   * 直接执行 SQL（兼容原 API）
   */
  execute: (sql, params) => pool.execute(sql, params),

  /**
   * 获取连接（兼容原 API）
   */
  getConnection: () => pool.getConnection(),

  /**
   * 关闭连接
   */
  close: () => pool.close(),

  /**
   * 获取原生数据库实例（推荐使用）
   *
   * 新代码推荐用法：
   * const db = require('../config/database').getDb();
   * const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
   */
  getDb: () => db
};
