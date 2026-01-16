// Mock 数据库模块 - 必须在 require favoriteService 之前定义
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

  db.exec(`
    CREATE TABLE favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      title TEXT NOT NULL,
      username TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
    )
  `);

  // 启用外键约束
  db.pragma('foreign_keys = ON');

  return db;
});

const favoriteService = require('../../services/favoriteService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('收藏服务测试', () => {
  // 测试用户 ID
  let testUserId;

  beforeEach(() => {
    // 清空表
    db.exec('DELETE FROM favorites');
    db.exec('DELETE FROM users');

    // 创建测试用户
    const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'test@example.com', 'hashedpassword');
    testUserId = info.lastInsertRowid;

    // 创建其他测试用户（用于外键测试）
    db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('user1', 'user1@example.com', 'hashedpassword');
    db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('user2', 'user2@example.com', 'hashedpassword');
    db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('otheruser', 'other@example.com', 'hashedpassword');
  });

  describe('getFavorites()', () => {
    test('未登录应返回所有收藏', () => {
      // 添加几个收藏
      db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example1.com/audio1.mp3', 'Audio 1', 'user1');
      db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example2.com/audio2.mp3', 'Audio 2', 'user2');

      const favorites = favoriteService.getFavorites(null);

      expect(favorites).toHaveLength(2);
    });

    test('已登录应只返回当前用户的收藏', () => {
      // 添加当前用户的收藏
      db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example.com/my-audio.mp3', 'My Audio', 'testuser');
      // 添加其他用户的收藏
      db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example.com/other-audio.mp3', 'Other Audio', 'otheruser');

      const favorites = favoriteService.getFavorites(testUserId);

      expect(favorites).toHaveLength(1);
      expect(favorites[0].username).toBe('testuser');
    });

    test('空表应返回空数组', () => {
      const favorites = favoriteService.getFavorites();
      expect(favorites).toEqual([]);
    });
  });

  describe('getFavoriteById()', () => {
    test('根据 ID 获取收藏', () => {
      const info = db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example.com/audio.mp3', 'Test Audio', 'testuser');

      const favorite = favoriteService.getFavoriteById(info.lastInsertRowid);

      expect(favorite).toEqual({
        id: info.lastInsertRowid,
        url: 'https://example.com/audio.mp3',
        title: 'Test Audio',
        username: 'testuser',
        created_at: expect.any(String)
      });
    });

    test('收藏不存在应抛出错误', () => {
      expect(() => {
        favoriteService.getFavoriteById(99999);
      }).toThrow('收藏不存在');
    });
  });

  describe('addFavorite()', () => {
    test('成功添加收藏', () => {
      const favorite = favoriteService.addFavorite(
        testUserId,
        'https://example.com/new-audio.mp3',
        'New Audio'
      );

      expect(favorite).toHaveProperty('id');
      expect(favorite.url).toBe('https://example.com/new-audio.mp3');
      expect(favorite.title).toBe('New Audio');
      expect(favorite.username).toBe('testuser');
    });

    test('用户不存在应抛出错误', () => {
      expect(() => {
        favoriteService.addFavorite(
          99999,  // 不存在的用户 ID
          'https://example.com/audio.mp3',
          'Audio'
        );
      }).toThrow('用户不存在');
    });

    test('重复的 URL 应抛出错误', () => {
      // 先添加一个收藏
      favoriteService.addFavorite(
        testUserId,
        'https://example.com/audio.mp3',
        'Audio'
      );

      // 尝试添加相同 URL
      expect(() => {
        favoriteService.addFavorite(
          testUserId,
          'https://example.com/audio.mp3',
          'Another Title'
        );
      }).toThrow('该内容已被收藏');
    });
  });

  describe('updateFavorite()', () => {
    test('成功更新收藏', () => {
      const info = db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example.com/old.mp3', 'Old Title', 'testuser');

      const updated = favoriteService.updateFavorite(info.lastInsertRowid, {
        url: 'https://example.com/new.mp3',
        title: 'New Title',
        username: 'testuser'
      });

      expect(updated.url).toBe('https://example.com/new.mp3');
      expect(updated.title).toBe('New Title');
    });

    test('收藏不存在应抛出错误', () => {
      expect(() => {
        favoriteService.updateFavorite(99999, {
          url: 'https://example.com/audio.mp3',
          title: 'Audio',
          username: 'testuser'
        });
      }).toThrow('收藏不存在');
    });
  });

  describe('deleteFavorite()', () => {
    test('成功删除收藏', () => {
      const info = db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)')
        .run('https://example.com/audio.mp3', 'Audio', 'testuser');

      const result = favoriteService.deleteFavorite(info.lastInsertRowid);

      expect(result).toEqual({
        success: true,
        message: '收藏已删除'
      });

      // 验证收藏已被删除
      const favorite = db.prepare('SELECT * FROM favorites WHERE id = ?').get(info.lastInsertRowid);
      expect(favorite).toBeUndefined();
    });

    test('收藏不存在应抛出错误', () => {
      expect(() => {
        favoriteService.deleteFavorite(99999);
      }).toThrow('收藏不存在');
    });
  });
});
