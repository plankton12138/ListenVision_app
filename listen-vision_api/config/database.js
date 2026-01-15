const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

/**
 * SQLite 数据库配置 (使用 sql.js)
 *
 * 知识点说明：
 * - sql.js: 纯 JavaScript 的 SQLite，通过 Emscripten 编译
 * - 优势: 无需原生编译，跨平台兼容
 * - 劣势: 性能略低于原生版本，但足够项目使用
 * - 数据存储: 内存数据库 + 文件持久化
 */

// 数据库文件路径
const dataDir = path.join(__dirname, '../data');
const dbPath = path.join(dataDir, 'listenvision.db');

// 确保 data 目录存在
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// 全局数据库实例
let db = null;
let SQL = null;

/**
 * 初始化数据库
 */
const initDatabase = async () => {
  // 初始化 sql.js
  SQL = await initSqlJs();

  // 尝试加载现有数据库，或创建新的
  if (fs.existsSync(dbPath)) {
    const buffer = fs.readFileSync(dbPath);
    db = new SQL.Database(buffer);
    console.log('✅ 加载现有数据库');
  } else {
    db = new SQL.Database();
    console.log('✅ 创建新数据库');
  }

  // 创建表结构
  createTables();

  return db;
};

/**
 * 创建数据库表结构
 */
const createTables = () => {
  // 启用外键约束
  db.run('PRAGMA foreign_keys = ON');

  // 创建用户表
  db.run(`
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
  db.run(`
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
  db.run('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)');
  db.run('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)');
  db.run('CREATE INDEX IF NOT EXISTS idx_favorites_username ON favorites(username)');
  db.run('CREATE INDEX IF NOT EXISTS idx_favorites_url ON favorites(url)');

  console.log('✅ 数据库表初始化完成');
};

/**
 * 保存数据库到文件
 */
const saveDatabase = () => {
  const data = db.export();
  const buffer = Buffer.from(data);
  fs.writeFileSync(dbPath, buffer);
};

/**
 * SQL 语法适配器：MySQL → SQLite
 */
const adaptSQL = (sql) => {
  // MySQL NOW() → SQLite datetime('now')
  return sql.replace(/\bNOW\(\)/gi, "datetime('now')");
};

/**
 * 适配层：提供类似 mysql2 的 Promise API
 */
class ConnectionAdapter {
  constructor(database) {
    this.db = database;
  }

  /**
   * 执行 SQL 查询
   */
  execute(sql, params = []) {
    return new Promise((resolve, reject) => {
      try {
        sql = adaptSQL(sql);
        const isSelect = sql.trim().toUpperCase().startsWith('SELECT');

        if (isSelect) {
          const stmt = this.db.prepare(sql);
          const result = stmt.all(...params);
          resolve([result, []]);
        } else {
          const stmt = this.db.prepare(sql);
          stmt.run(...params);
          // sql.js 不直接返回 insertId，需要额外查询
          const insertId = this.db.exec('SELECT last_insert_rowid() as id')[0]?.values[0][0];
          resolve([{ insertId }]);
        }
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * 释放连接（兼容性方法）
   */
  release() {
    // sql.js 不需要释放连接
  }
}

/**
 * 连接池适配器
 */
class PoolAdapter {
  constructor(database) {
    this.db = database;
  }

  async getConnection() {
    return new ConnectionAdapter(this.db);
  }

  async execute(sql, params = []) {
    const conn = new ConnectionAdapter(this.db);
    const result = await conn.execute(sql, params);
    // 每次写操作后保存到文件
    if (!sql.trim().toUpperCase().startsWith('SELECT')) {
      saveDatabase();
    }
    return result;
  }

  close() {
    saveDatabase();
    this.db.close();
  }
}

// 初始化并导出
let pool = null;

initDatabase().then((database) => {
  pool = new PoolAdapter(database);
  console.log('✅ SQLite 数据库连接成功');
  console.log(`📁 数据库位置: ${dbPath}`);

  // 定期保存（每30秒）
  setInterval(() => {
    if (db) saveDatabase();
  }, 30000);

}).catch((error) => {
  console.error('❌ 数据库初始化失败:', error.message);
  process.exit(1);
});

// 优雅退出
process.on('exit', () => {
  if (pool) pool.close();
});

process.on('SIGINT', () => {
  if (pool) pool.close();
  process.exit(0);
});

process.on('SIGTERM', () => {
  if (pool) pool.close();
  process.exit(0);
});

/**
 * 导出一个 Promise，等待数据库初始化完成
 */
module.exports = {
  getPool: async () => {
    while (!pool) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    return pool;
  },
  // 兼容旧的同步导出方式（会等待初始化）
  then: function(onFulfilled, onRejected) {
    return initDatabase().then((db) => {
      const adapter = new PoolAdapter(db);
      pool = adapter;
      return onFulfilled ? onFulfilled(adapter) : adapter;
    }, onRejected);
  }
};

// 为了向后兼容，同时支持同步 require
module.exports = new Proxy({}, {
  get(target, prop) {
    return function(...args) {
      return initDatabase().then((db) => {
        const adapter = new PoolAdapter(db);
        pool = adapter;
        return adapter[prop](...args);
      });
    };
  }
});
