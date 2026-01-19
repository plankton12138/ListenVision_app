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
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  // Phase 3.1: 搜索统计表
  db.exec(`
    CREATE TABLE search_stats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      keyword TEXT NOT NULL,
      search_count INTEGER DEFAULT 1,
      last_searched TEXT DEFAULT (datetime('now')),
      UNIQUE(user_id, keyword),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
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
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now", "-1 day"))')
        .run(testUserId, '流行音乐', 5);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '测试音乐', 3);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '摇滚', 2);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '流行歌曲', 4);
    });

    test('根据前缀返回搜索建议', () => {
      const suggestions = searchService.getSearchSuggestions('流行', testUserId);

      expect(suggestions.length).toBeGreaterThan(0);
      expect(suggestions.every(s => s.startsWith('流行'))).toBe(true);
    });

    test('按搜索次数排序建议', () => {
      const suggestions = searchService.getSearchSuggestions('流行', testUserId);

      // 验证建议按搜索次数降序排序
      expect(suggestions[0]).toBe('流行音乐'); // 搜索次数最多
      expect(suggestions[1]).toBe('流行歌曲');
    });

    test('无匹配建议返回空数组', () => {
      const suggestions = searchService.getSearchSuggestions('不存在的', testUserId);

      expect(suggestions).toEqual([]);
    });

    test('空前缀返回空数组', () => {
      const suggestions = searchService.getSearchSuggestions('', testUserId);

      expect(suggestions).toEqual([]);
    });
  });

  describe('getTrendingKeywords()', () => {
    beforeEach(() => {
      // 插入热门关键词（最近7天）
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now", "-1 day"))')
        .run(testUserId, '热门1', 10);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '热门2', 8);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now", "-2 days"))')
        .run(testUserId, '热门3', 6);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now", "-8 days"))')
        .run(testUserId, '旧热门', 20); // 超过7天
    });

    test('返回最近7天的热门关键词', () => {
      const trending = searchService.getTrendingKeywords();

      expect(trending.length).toBeGreaterThan(0);
      expect(trending.every(k => k !== '旧热门')).toBe(true); // 旧热门不应包含
    });

    test('按搜索次数降序排序', () => {
      const trending = searchService.getTrendingKeywords();

      expect(trending[0]).toBe('热门1'); // 搜索次数最多
      expect(trending[1]).toBe('热门2');
    });

    test('限制返回前10个关键词', () => {
      // 插入超过10个关键词
      for (let i = 4; i <= 15; i++) {
        db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
          .run(testUserId, `热门${i}`, i);
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
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '搜索1', 1);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '搜索2', 2);
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(999, '其他用户的搜索', 1);
    });

    test('返回用户的搜索历史', () => {
      const history = searchService.getSearchHistory(testUserId);

      expect(history.length).toBe(2);
      expect(history.every(h => h !== '其他用户的搜索')).toBe(true);
    });

    test('按最后搜索时间降序排序', () => {
      // 插入不同时间的搜索
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now", "-2 days"))')
        .run(testUserId, '旧搜索', 1);

      const history = searchService.getSearchHistory(testUserId);

      // 最新的搜索应该在前面
      expect(history[0]).not.toBe('旧搜索');
    });

    test('无搜索历史返回空数组', () => {
      const history = searchService.getSearchHistory(999); // 不存在的用户

      expect(history).toEqual([]);
    });
  });

  describe('recordSearch()', () => {
    test('记录新的搜索关键词', () => {
      searchService.recordSearch('新关键词', testUserId);

      const stat = db.prepare('SELECT * FROM search_stats WHERE user_id = ? AND keyword = ?')
        .get(testUserId, '新关键词');

      expect(stat).toBeDefined();
      expect(stat.keyword).toBe('新关键词');
      expect(stat.search_count).toBe(1);
    });

    test('更新已存在的搜索关键词计数', () => {
      // 先插入一次
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, datetime("now"))')
        .run(testUserId, '已有关键词', 1);

      // 再次记录
      searchService.recordSearch('已有关键词', testUserId);

      const stat = db.prepare('SELECT * FROM search_stats WHERE user_id = ? AND keyword = ?')
        .get(testUserId, '已有关键词');

      expect(stat.search_count).toBe(2);
    });

    test('更新最后搜索时间', () => {
      // 插入旧的搜索时间
      const oldTime = '2024-01-01 00:00:00';
      db.prepare('INSERT INTO search_stats (user_id, keyword, search_count, last_searched) VALUES (?, ?, ?, ?)')
        .run(testUserId, '测试', 1, oldTime);

      searchService.recordSearch('测试', testUserId);

      const stat = db.prepare('SELECT * FROM search_stats WHERE user_id = ? AND keyword = ?')
        .get(testUserId, '测试');

      expect(stat.last_searched).not.toBe(oldTime);
    });

    test('支持游客搜索（user_id 为 null）', () => {
      searchService.recordSearch('游客搜索', null);

      const stat = db.prepare('SELECT * FROM search_stats WHERE user_id IS NULL AND keyword = ?')
        .get('游客搜索');

      expect(stat).toBeDefined();
    });
  });
});
