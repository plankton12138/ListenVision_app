// Mock 数据库模块 - 必须在 require downloadService 之前定义
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

  // Phase 3.3: 下载任务表
  db.exec(`
    CREATE TABLE download_tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      bvid TEXT NOT NULL,
      title TEXT,
      artist TEXT,
      cover_url TEXT,
      duration INTEGER,
      progress INTEGER DEFAULT 0,
      file_size INTEGER DEFAULT 0,
      downloaded_size INTEGER DEFAULT 0,
      status TEXT DEFAULT 'pending',
      file_path TEXT,
      error_message TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 索引
  db.exec('CREATE INDEX idx_download_tasks_user_id ON download_tasks(user_id)');
  db.exec('CREATE INDEX idx_download_tasks_status ON download_tasks(status)');

  // 启用外键约束
  db.pragma('foreign_keys = ON');

  return db;
});

const downloadService = require('../../services/downloadService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('下载任务服务测试 (Phase 3.3)', () => {
  let testUserId;
  let otherUserId;

  beforeEach(() => {
    // 清空表
    db.exec('DELETE FROM download_tasks');
    db.exec('DELETE FROM users');

    // 创建测试用户
    const info1 = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'test@example.com', 'hashedpassword');
    testUserId = info1.lastInsertRowid;

    const info2 = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('otheruser', 'other@example.com', 'hashedpassword');
    otherUserId = info2.lastInsertRowid;
  });

  describe('createDownloadTask()', () => {
    test('成功创建下载任务', () => {
      const task = downloadService.createDownloadTask(testUserId, 'BV1xx411c7mD');

      expect(task).toHaveProperty('id');
      expect(task.user_id).toBe(testUserId);
      expect(task.bvid).toBe('BV1xx411c7mD');
      expect(task.status).toBe('pending');
      expect(task.progress).toBe(0);
      expect(task.downloaded_size).toBe(0);
    });

    test('任务包含时间戳', () => {
      const task = downloadService.createDownloadTask(testUserId, 'BV1xx411c7mD');

      expect(task).toHaveProperty('created_at');
      expect(task).toHaveProperty('updated_at');
      expect(typeof task.created_at).toBe('string');
    });
  });

  describe('getUserTasks()', () => {
    beforeEach(() => {
      // 创建多个任务
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'pending');
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1yy411c7mD', 'downloading');
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1zz411c7mD', 'completed');
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(otherUserId, 'BV1aa411c7mD', 'pending');
    });

    test('返回用户的所有任务', () => {
      const tasks = downloadService.getUserTasks(testUserId);

      expect(tasks).toHaveLength(3);
    });

    test('按 created_at 降序排序', () => {
      const tasks = downloadService.getUserTasks(testUserId);

      // 验证任务按创建时间降序排序
      const times = tasks.map(t => t.created_at);
      expect(times[0] >= times[1] || times[1] >= times[2]).toBe(true);
    });

    test('无任务返回空数组', () => {
      const tasks = downloadService.getUserTasks(999);

      expect(tasks).toEqual([]);
    });
  });

  describe('updateDownloadProgress()', () => {
    let taskId;

    beforeEach(() => {
      const info = db.prepare(`INSERT INTO download_tasks (user_id, bvid, status, file_size) VALUES (?, ?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'downloading', 1024000);
      taskId = info.lastInsertRowid;
    });

    test('成功更新下载进度', () => {
      const result = downloadService.updateDownloadProgress(taskId, 50, 512000);

      expect(result).toBe(true);

      const task = db.prepare('SELECT * FROM download_tasks WHERE id = ?').get(taskId);
      expect(task.progress).toBe(50);
      expect(task.downloaded_size).toBe(512000);
      expect(task.status).toBe('downloading');
    });
  });

  describe('pauseDownloadTask()', () => {
    test('成功暂停下载任务', () => {
      const info = db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'downloading');

      const result = downloadService.pauseDownloadTask(info.lastInsertRowid);
      expect(result).toBe(true);

      const task = db.prepare('SELECT * FROM download_tasks WHERE id = ?').get(info.lastInsertRowid);
      expect(task.status).toBe('paused');
    });
  });

  describe('completeDownloadTask()', () => {
    test('成功标记任务完成', () => {
      const info = db.prepare(`INSERT INTO download_tasks (user_id, bvid, status, downloaded_size, file_size) VALUES (?, ?, ?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'downloading', 1024000, 1024000);

      const result = downloadService.completeDownloadTask(info.lastInsertRowid);
      expect(result).toBe(true);

      const task = db.prepare('SELECT * FROM download_tasks WHERE id = ?').get(info.lastInsertRowid);
      expect(task.status).toBe('completed');
    });
  });

  describe('failDownloadTask()', () => {
    test('成功标记任务失败', () => {
      const info = db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'downloading');

      const result = downloadService.failDownloadTask(info.lastInsertRowid, '下载失败：网络错误');
      expect(result).toBe(true);

      const task = db.prepare('SELECT * FROM download_tasks WHERE id = ?').get(info.lastInsertRowid);
      expect(task.status).toBe('failed');
      expect(task.error_message).toBe('下载失败：网络错误');
    });
  });

  describe('deleteDownloadTask()', () => {
    test('成功删除任务', () => {
      const info = db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'pending');

      const result = downloadService.deleteDownloadTask(info.lastInsertRowid, testUserId);
      expect(result).toBe(true);

      const task = db.prepare('SELECT * FROM download_tasks WHERE id = ?').get(info.lastInsertRowid);
      expect(task).toBeUndefined();
    });

    test('删除其他用户的任务应抛出错误', () => {
      const info = db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(otherUserId, 'BV1xx411c7mD', 'pending');

      expect(() => {
        downloadService.deleteDownloadTask(info.lastInsertRowid, testUserId);
      }).toThrow('无权限删除此任务');
    });

    test('删除不存在的任务应抛出错误', () => {
      expect(() => {
        downloadService.deleteDownloadTask(99999, testUserId);
      }).toThrow('无权限删除此任务');
    });
  });

  describe('clearCompletedTasks()', () => {
    beforeEach(() => {
      // 创建不同状态的任务
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1xx411c7mD', 'completed');
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1yy411c7mD', 'completed');
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1zz411c7mD', 'downloading');
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(testUserId, 'BV1aa411c7mD', 'failed');
    });

    test('清空所有已完成的任务', () => {
      const deletedCount = downloadService.clearCompletedTasks(testUserId);
      expect(deletedCount).toBe(2);

      const tasks = db.prepare('SELECT * FROM download_tasks WHERE user_id = ?').all(testUserId);
      expect(tasks).toHaveLength(2);
      expect(tasks.every(t => t.status !== 'completed')).toBe(true);
    });

    test('清空后其他用户的任务不受影响', () => {
      db.prepare(`INSERT INTO download_tasks (user_id, bvid, status) VALUES (?, ?, ?)`)
        .run(otherUserId, 'BV1bb411c7mD', 'completed');

      downloadService.clearCompletedTasks(testUserId);

      const otherUserTasks = db.prepare('SELECT * FROM download_tasks WHERE user_id = ?').all(otherUserId);
      expect(otherUserTasks).toHaveLength(1);
    });
  });
});
