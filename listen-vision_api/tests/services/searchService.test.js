// Mock 数据库模块 - 必须在 require searchService 之前定义
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');

  // 创建内存数据库用于测试
  const db = new Database(':memory:');

  // 创建测试表结构
  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      reset_code TEXT,
      code_expire TEXT,
      email_verified INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // Phase 3.1: 搜索统计表 (全局)
  db.exec(`
    CREATE TABLE search_stats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT NOT NULL UNIQUE,
      search_count INTEGER DEFAULT 1,
      last_searched TEXT DEFAULT (datetime('now'))
    )
  `);

  // Phase 3.1: 用户搜索历史表
  db.exec(`
    CREATE TABLE search_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      keyword TEXT NOT NULL,
      result_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // Phase 4: FTS5 全文搜索表
  db.exec(`
    CREATE VIRTUAL TABLE IF NOT EXISTS audio_metadata_cache_fts USING fts5(
      title,
      author,
      bvid UNINDEXED
    );

    CREATE TABLE IF NOT EXISTS audio_metadata_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT NOT NULL UNIQUE,
      title TEXT,
      artist TEXT,
      cover_url TEXT,
      duration INTEGER,
      audio_url TEXT,
      cid INTEGER,
      metadata TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS audio_content_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT NOT NULL UNIQUE,
      data BLOB,
      content_type TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    );
  `);

  // 依赖表：bilibili_accounts (由 bilibiliService 需要)
  db.exec(`
    CREATE TABLE IF NOT EXISTS bilibili_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      bili_user_id TEXT,
      bili_username TEXT,
      cookie_encrypted TEXT,
      refresh_token_encrypted TEXT,
      is_active INTEGER DEFAULT 1,
      expires_at TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 平台账号表
  db.exec(`
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
    )
  `);

  // Phase 3.1: 用户行为日志表
  db.exec(`
    CREATE TABLE user_behavior_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      bvid TEXT NOT NULL,
      action TEXT NOT NULL,
      timestamp TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 启用外键约束
  db.pragma('foreign_keys = ON');

  return db;
});

// 获取 mock 的数据库实例
const db = require('../../config/database');

// 导入 searchService（FTS5 功能将在实际运行时测试）
const searchService = require('../../services/searchService');

describe('搜索服务测试 (Phase 3.1) - 非FTS5功能', () => {
  let testUserId;

  beforeEach(() => {
    // 清空表
    db.exec('DELETE FROM search_stats');
    db.exec('DELETE FROM user_behavior_logs');
    db.exec('DELETE FROM users');

    // 创建测试用户
    const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'test@example.com', 'hashedpassword');
    testUserId = info.lastInsertRowid;
  });

  describe('getSearchSuggestions()', () => {
    beforeEach(() => {
      // 插入搜索历史
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\', \'-1 day\'))')
        .run('流行音乐', 5);
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\'))')
        .run('测试音乐', 3);
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\'))')
        .run('摇滚', 2);
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\'))')
        .run('流行歌曲', 4);
    });

    test('根据前缀返回搜索建议', () => {
      const suggestions = searchService.getSearchSuggestions('流行'); // 不需要 userId

      expect(suggestions.length).toBeGreaterThan(0);
      expect(suggestions.every(s => s.startsWith('流行'))).toBe(true);
    });

    test('按搜索次数排序建议', () => {
      const suggestions = searchService.getSearchSuggestions('流行');

      // 验证建议按搜索次数降序排序
      expect(suggestions[0]).toBe('流行音乐'); // 搜索次数最多
      expect(suggestions[1]).toBe('流行歌曲');
    });

    test('无匹配建议返回空数组', () => {
      const suggestions = searchService.getSearchSuggestions('不存在的');

      expect(suggestions).toEqual([]);
    });

    test('空前缀返回空数组', () => {
      const suggestions = searchService.getSearchSuggestions('');

      expect(suggestions).toEqual([]);
    });
  });

  describe('getTrendingKeywords()', () => {
    beforeEach(() => {
      // 插入热门关键词（最近7天）
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\', \'-1 day\'))')
        .run('热门1', 10);
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\'))')
        .run('热门2', 8);
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\', \'-2 days\'))')
        .run('热门3', 6);
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\', \'-8 days\'))')
        .run('旧热门', 20); // 超过7天
    });

    test('返回最近7天的热门关键词', () => {
      const trending = searchService.getTrendingKeywords();

      expect(trending.length).toBeGreaterThan(0);
      expect(trending.every(k => k !== '旧热门')).toBe(true); // 旧热门不应包含
    });

    test('按搜索次数降序排序', () => {
      const trending = searchService.getTrendingKeywords();

      expect(trending[0].keyword).toBe('热门1'); // 搜索次数最多
      expect(trending[1].keyword).toBe('热门2');
    });

    test('限制返回前10个关键词', () => {
      // 插入超过10个关键词
      for (let i = 4; i <= 15; i++) {
        db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\'))')
          .run(`热门${i}`, i);
      }

      const trending = searchService.getTrendingKeywords();

      expect(trending.length).toBeLessThanOrEqual(10);
    });

    test('无搜索历史返回空数组', () => {
      db.exec('DELETE FROM search_stats');
      const trending = searchService.getTrendingKeywords();

      expect(trending).toEqual([]);
    });
  });

  describe('getSearchHistory()', () => {
    beforeEach(() => {
      // 插入搜索历史
      db.prepare('INSERT INTO search_history (user_id, keyword, result_count, created_at) VALUES (?, ?, ?, datetime(\'now\'))')
        .run(testUserId, '搜索1', 1);
      db.prepare('INSERT INTO search_history (user_id, keyword, result_count, created_at) VALUES (?, ?, ?, datetime(\'now\'))')
        .run(testUserId, '搜索2', 2);
        
      // 创建另一个用户以满足外键约束
      const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('otheruser', 'other@example.com', 'pass');
      const otherUserId = info.lastInsertRowid;

      db.prepare('INSERT INTO search_history (user_id, keyword, result_count, created_at) VALUES (?, ?, ?, datetime(\'now\'))')
        .run(otherUserId, '其他用户的搜索', 1);
    });

    test('返回用户的搜索历史', () => {
      const history = searchService.getSearchHistory(testUserId);

      expect(history.length).toBe(2);
      expect(history.every(h => h.keyword !== '其他用户的搜索')).toBe(true);
    });

    test('按最后搜索时间降序排序', () => {
      // 插入不同时间的搜索
      db.prepare('INSERT INTO search_history (user_id, keyword, result_count, created_at) VALUES (?, ?, ?, datetime(\'now\', \'-2 days\'))')
        .run(testUserId, '旧搜索', 1);

      const history = searchService.getSearchHistory(testUserId);

      // 最新的搜索应该在前面
      expect(history[0].keyword).not.toBe('旧搜索');
    });

    test('无搜索历史返回空数组', () => {
      const history = searchService.getSearchHistory(999); // 不存在的用户

      expect(history).toEqual([]);
    });
  });

  // 注意：saveSearchHistory 依赖 audioService，而 audioService 依赖数据库。
  // 在此测试中我们主要测试 saveSearchHistory 的逻辑
  describe('saveSearchHistory()', () => {
    test('记录新的搜索历史', () => {
      searchService.saveSearchHistory(testUserId, '新关键词', 5);

      const history = db.prepare('SELECT * FROM search_history WHERE user_id = ? AND keyword = ?')
        .get(testUserId, '新关键词');

      expect(history).toBeDefined();
      expect(history.keyword).toBe('新关键词');
      expect(history.result_count).toBe(5);
    });
  });

  describe('searchAudioMetadata() - 统计更新测试', () => {
    test('记录新的搜索关键词统计', () => {
      // 需要 FTS 数据才能搜索成功并触发 recordSearch
      // 但 recordSearch 是在 try 块中执行的，我们可以测试它是否被调用
      // 为了简化，我们直接测试 searchAudioMetadata 是否尝试插入数据
      // 即使 FTS 搜索为空，recordSearch 也应该被执行

      try {
        searchService.searchAudioMetadata('新统计关键词');
      } catch (e) {
        // 忽略 FTS 错误
      }

      const stat = db.prepare('SELECT * FROM search_stats WHERE keyword = ?')
        .get('新统计关键词');

      expect(stat).toBeDefined();
      expect(stat.keyword).toBe('新统计关键词');
      expect(stat.search_count).toBe(1);
    });

    test('更新已存在的搜索关键词计数', () => {
      // 先插入一次
      db.prepare('INSERT INTO search_stats (keyword, search_count, last_searched) VALUES (?, ?, datetime(\'now\'))')
        .run('已有关键词', 1);

      // 再次搜索
      try {
        searchService.searchAudioMetadata('已有关键词');
      } catch (e) {}

      const stat = db.prepare('SELECT * FROM search_stats WHERE keyword = ?')
        .get('已有关键词');

      expect(stat.search_count).toBe(2);
    });
  });
});
