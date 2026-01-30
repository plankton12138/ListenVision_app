// Mock 数据库模块 - 必须在 require playHistoryService 之前定义
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
    CREATE TABLE play_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      bvid TEXT,
      local_path TEXT,
      audio_type TEXT DEFAULT 'online' CHECK(audio_type IN ('online', 'local')),
      title TEXT,
      artist TEXT,
      duration INTEGER,
      cover_url TEXT,
      progress INTEGER DEFAULT 0,
      played_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 创建索引（模拟生产环境）
  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_play_history_user_id ON play_history(user_id);
    CREATE INDEX IF NOT EXISTS idx_play_history_played_at ON play_history(user_id, played_at);
    CREATE INDEX IF NOT EXISTS idx_play_history_identifier ON play_history(user_id, bvid, local_path);
  `);

  return db;
});

const playHistoryService = require('../../services/playHistoryService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('播放历史服务测试', () => {
  let testUserId;

  beforeEach(() => {
    // 在每个测试前清空表
    db.exec('DELETE FROM users');
    db.exec('DELETE FROM play_history');

    // 创建测试用户
    const bcrypt = require('bcryptjs');
    const hashedPassword = bcrypt.hashSync('password123', 10);
    const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'test@example.com', hashedPassword);
    testUserId = info.lastInsertRowid;
  });

  describe('recordPlay()', () => {
    describe('在线音频（bvid）', () => {
      test('应成功创建新的在线播放记录', () => {
        const record = playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1xx411c7mD',
          title: '测试音频',
          artist: '测试歌手',
          duration: 180,
          coverUrl: 'https://example.com/cover.jpg',
          progress: 0
        });

        expect(record).toHaveProperty('id');
        expect(record.user_id).toBe(testUserId);
        expect(record.bvid).toBe('BV1xx411c7mD');
        expect(record.local_path).toBeNull();
        expect(record.audio_type).toBe('online');
        expect(record.title).toBe('测试音频');
        expect(record.artist).toBe('测试歌手');
        expect(record.duration).toBe(180);
        expect(record.cover_url).toBe('https://example.com/cover.jpg');
        expect(record.progress).toBe(0);
        expect(record.played_at).toBeDefined();

        // 验证数据库中的记录
        const dbRecord = db.prepare('SELECT * FROM play_history WHERE id = ?').get(record.id);
        expect(dbRecord).toBeDefined();
        expect(dbRecord.bvid).toBe('BV1xx411c7mD');
      });

      test('应更新现有的在线播放记录', () => {
        // 第一次播放
        const firstRecord = playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1xx411c7mD',
          title: '测试音频',
          artist: '测试歌手',
          duration: 180,
          progress: 30
        });

        // 第二次播放（同一音频）
        const secondRecord = playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1xx411c7mD',
          title: '测试音频',
          artist: '测试歌手',
          duration: 180,
          progress: 60
        });

        // 应该返回同一个记录 ID
        expect(secondRecord.id).toBe(firstRecord.id);
        expect(secondRecord.progress).toBe(60);

        // 数据库中应该只有一条记录
        const count = db.prepare('SELECT COUNT(*) as count FROM play_history WHERE user_id = ? AND bvid = ?')
          .get(testUserId, 'BV1xx411c7mD');
        expect(count.count).toBe(1);
      });

      test('应正确处理可选参数', () => {
        const record = playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1xx411c7mD',
          title: '最小化记录'
        });

        expect(record.bvid).toBe('BV1xx411c7mD');
        expect(record.title).toBe('最小化记录');
        expect(record.artist).toBeNull();
        expect(record.duration).toBeNull();
        expect(record.cover_url).toBeNull();
        expect(record.progress).toBe(0);
      });
    });

    describe('本地音频（localPath）', () => {
      test('应成功创建新的本地播放记录', () => {
        const record = playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/test.mp3',
          title: '本地测试音频',
          artist: '本地歌手',
          duration: 200,
          coverUrl: 'https://example.com/local-cover.jpg',
          progress: 45
        });

        expect(record).toHaveProperty('id');
        expect(record.user_id).toBe(testUserId);
        expect(record.bvid).toBeNull();
        expect(record.local_path).toBe('C:/Music/test.mp3');
        expect(record.audio_type).toBe('local');
        expect(record.title).toBe('本地测试音频');
        expect(record.artist).toBe('本地歌手');
        expect(record.duration).toBe(200);
        expect(record.cover_url).toBe('https://example.com/local-cover.jpg');
        expect(record.progress).toBe(45);

        // 验证数据库中的记录
        const dbRecord = db.prepare('SELECT * FROM play_history WHERE id = ?').get(record.id);
        expect(dbRecord).toBeDefined();
        expect(dbRecord.local_path).toBe('C:/Music/test.mp3');
        expect(dbRecord.bvid).toBeNull();
      });

      test('应更新现有的本地播放记录', () => {
        // 第一次播放
        const firstRecord = playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/song.mp3',
          title: '本地歌曲',
          progress: 20
        });

        // 第二次播放（同一路径）
        const secondRecord = playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/song.mp3',
          title: '本地歌曲',
          progress: 80
        });

        expect(secondRecord.id).toBe(firstRecord.id);
        expect(secondRecord.progress).toBe(80);

        // 数据库中应该只有一条记录
        const count = db.prepare('SELECT COUNT(*) as count FROM play_history WHERE user_id = ? AND local_path = ?')
          .get(testUserId, 'C:/Music/song.mp3');
        expect(count.count).toBe(1);
      });

      test('不同本地路径应创建不同记录', () => {
        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/song1.mp3',
          title: '歌曲1'
        });

        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/song2.mp3',
          title: '歌曲2'
        });

        const records = db.prepare('SELECT * FROM play_history WHERE user_id = ? AND audio_type = ?')
          .all(testUserId, 'local');

        expect(records).toHaveLength(2);
      });
    });

    describe('错误处理', () => {
      test('缺少标识符应抛出 400 错误', () => {
        expect(() => {
          playHistoryService.recordPlay(testUserId, {
            title: '无标识符音频'
          });
        }).toThrow('缺少音频标识符');
      });

      test('null 用户也应支持记录播放（游客模式）', () => {
        const record = playHistoryService.recordPlay(null, {
          bvid: 'BV1guest',
          title: '游客播放'
        });

        expect(record).toHaveProperty('id');
        expect(record.user_id).toBeNull();
        expect(record.bvid).toBe('BV1guest');
      });
    });

    describe('混合场景', () => {
      test('在线和本地音频应独立记录', () => {
        playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1online',
          title: '在线音频'
        });

        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/local.mp3',
          title: '本地音频'
        });

        const records = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
        expect(records).toHaveLength(2);

        const online = records.find(r => r.audio_type === 'online');
        const local = records.find(r => r.audio_type === 'local');

        expect(online.bvid).toBe('BV1online');
        expect(online.local_path).toBeNull();
        expect(local.local_path).toBe('C:/Music/local.mp3');
        expect(local.bvid).toBeNull();
      });
    });
  });

  describe('getHistory()', () => {
    beforeEach(() => {
      // 创建多条播放记录
      playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1first',
        title: '第一条记录',
        progress: 100
      });

      // 短暂延迟以确保 played_at 不同
      // 注意：在快速测试中，SQLite 的 datetime('now') 可能相同，这里依赖数据库的时间戳

      playHistoryService.recordPlay(testUserId, {
        localPath: 'C:/Music/second.mp3',
        title: '第二条记录',
        progress: 50
      });

      playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1third',
        title: '第三条记录',
        progress: 75
      });
    });

    test('应返回用户的播放历史（默认参数）', () => {
      const history = playHistoryService.getHistory(testUserId);

      expect(history).toHaveLength(3);
      expect(history[0]).toHaveProperty('id');
      expect(history[0]).toHaveProperty('bvid');
      expect(history[0]).toHaveProperty('title');
      expect(history[0]).toHaveProperty('progress');
      expect(history[0]).toHaveProperty('played_at');
    });

    test('应按 played_at DESC 排序（最新的在前）', () => {
      const history = playHistoryService.getHistory(testUserId);

      // 验证顺序：最后插入的应该在最前面
      expect(history[0].title).toBe('第三条记录');
      expect(history[1].title).toBe('第二条记录');
      expect(history[2].title).toBe('第一条记录');
    });

    test('应支持 limit 参数', () => {
      const history = playHistoryService.getHistory(testUserId, 2);

      expect(history).toHaveLength(2);
      expect(history[0].title).toBe('第三条记录');
      expect(history[1].title).toBe('第二条记录');
    });

    test('应支持 offset 参数', () => {
      const history = playHistoryService.getHistory(testUserId, 2, 1);

      expect(history).toHaveLength(2);
      expect(history[0].title).toBe('第二条记录');
      expect(history[1].title).toBe('第一条记录');
    });

    test('应只返回当前用户的记录', () => {
      // 创建另一个用户
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('otheruser', 'other@example.com', 'hash').lastInsertRowid;

      playHistoryService.recordPlay(otherUserId, {
        bvid: 'BV1other',
        title: '其他用户的记录'
      });

      const history = playHistoryService.getHistory(testUserId);

      // 不应包含其他用户的记录
      expect(history.every(r => r.user_id === testUserId)).toBe(true);
      expect(history.find(r => r.bvid === 'BV1other')).toBeUndefined();
    });

    test('空历史应返回空数组', () => {
      db.exec('DELETE FROM play_history');

      const history = playHistoryService.getHistory(testUserId);
      expect(history).toEqual([]);
    });
  });

  describe('getAllHistory()', () => {
    beforeEach(() => {
      // 创建超过默认 limit (50) 的记录
      for (let i = 1; i <= 60; i++) {
        playHistoryService.recordPlay(testUserId, {
          bvid: `BV1${i}`,
          title: `音频${i}`
        });
      }
    });

    test('应返回所有播放历史（无分页限制）', () => {
      const allHistory = playHistoryService.getAllHistory(testUserId);

      expect(allHistory).toHaveLength(60);
    });

    test('应按 played_at DESC 排序', () => {
      const allHistory = playHistoryService.getAllHistory(testUserId);

      // 最后插入的应该在最前面
      expect(allHistory[0].title).toBe('音频60');
      expect(allHistory[59].title).toBe('音频1');
    });

    test('空历史应返回空数组', () => {
      db.exec('DELETE FROM play_history');

      const allHistory = playHistoryService.getAllHistory(testUserId);
      expect(allHistory).toEqual([]);
    });
  });

  describe('clearHistory()', () => {
    test('应清空用户的所有播放历史', () => {
      // 创建多条记录
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1a', title: 'A' });
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1b', title: 'B' });
      playHistoryService.recordPlay(testUserId, { localPath: 'C:/Music/c.mp3', title: 'C' });

      // 清空历史
      const result = playHistoryService.clearHistory(testUserId);

      expect(result).toBe(true);

      // 验证已清空
      const records = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
      expect(records).toHaveLength(0);
    });

    test('应只清空指定用户的历史', () => {
      // 创建另一个用户
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('otheruser', 'other@example.com', 'hash').lastInsertRowid;

      playHistoryService.recordPlay(testUserId, { bvid: 'BV1test', title: '测试用户' });
      playHistoryService.recordPlay(otherUserId, { bvid: 'BV1other', title: '其他用户' });

      // 只清空测试用户的历史
      playHistoryService.clearHistory(testUserId);

      // 验证测试用户的记录已清空
      const testRecords = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
      expect(testRecords).toHaveLength(0);

      // 验证其他用户的记录仍然存在
      const otherRecords = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(otherUserId);
      expect(otherRecords).toHaveLength(1);
      expect(otherRecords[0].bvid).toBe('BV1other');
    });

    test('清空空历史不应报错', () => {
      expect(() => {
        playHistoryService.clearHistory(testUserId);
      }).not.toThrow();
    });
  });

  describe('removeHistoryItem()', () => {
    describe('通过 bvid 删除在线音频', () => {
      test('应成功删除指定的在线播放记录', () => {
        playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1todelete',
          title: '待删除'
        });

        const result = playHistoryService.removeHistoryItem(testUserId, 'BV1todelete');

        expect(result).toBe(true);

        // 验证已删除
        const record = db.prepare('SELECT * FROM play_history WHERE user_id = ? AND bvid = ?')
          .get(testUserId, 'BV1todelete');
        expect(record).toBeUndefined();
      });

      test('应只删除匹配 bvid 的记录', () => {
        playHistoryService.recordPlay(testUserId, { bvid: 'BV1keep', title: '保留' });
        playHistoryService.recordPlay(testUserId, { bvid: 'BV1delete', title: '删除' });

        playHistoryService.removeHistoryItem(testUserId, 'BV1delete');

        const records = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
        expect(records).toHaveLength(1);
        expect(records[0].bvid).toBe('BV1keep');
      });
    });

    describe('通过 localPath 删除本地音频', () => {
      test('应成功删除指定的本地播放记录', () => {
        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/todelete.mp3',
          title: '待删除'
        });

        const result = playHistoryService.removeHistoryItem(testUserId, null, 'C:/Music/todelete.mp3');

        expect(result).toBe(true);

        // 验证已删除
        const record = db.prepare('SELECT * FROM play_history WHERE user_id = ? AND local_path = ?')
          .get(testUserId, 'C:/Music/todelete.mp3');
        expect(record).toBeUndefined();
      });

      test('应只删除匹配 localPath 的记录', () => {
        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/keep.mp3',
          title: '保留'
        });
        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/delete.mp3',
          title: '删除'
        });

        playHistoryService.removeHistoryItem(testUserId, null, 'C:/Music/delete.mp3');

        const records = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
        expect(records).toHaveLength(1);
        expect(records[0].local_path).toBe('C:/Music/keep.mp3');
      });
    });

    describe('混合场景', () => {
      test('删除在线记录不应影响本地记录', () => {
        playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1online',
          title: '在线'
        });
        playHistoryService.recordPlay(testUserId, {
          localPath: 'C:/Music/local.mp3',
          title: '本地'
        });

        playHistoryService.removeHistoryItem(testUserId, 'BV1online');

        const records = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
        expect(records).toHaveLength(1);
        expect(records[0].local_path).toBe('C:/Music/local.mp3');
      });
    });

    describe('错误处理', () => {
      test('删除不存在的记录不应报错', () => {
        expect(() => {
          playHistoryService.removeHistoryItem(testUserId, 'BV1nonexistent');
        }).not.toThrow();
      });

      test('同时提供 bvid 和 localPath 应优先使用 bvid', () => {
        playHistoryService.recordPlay(testUserId, {
          bvid: 'BV1test',
          title: '测试'
        });

        // 传入 bvid 和 localPath，应删除 bvid 对应的记录
        playHistoryService.removeHistoryItem(testUserId, 'BV1test', 'C:/Music/other.mp3');

        const records = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(testUserId);
        expect(records).toHaveLength(0);
      });
    });
  });

  describe('removeHistoryById()', () => {
    test('应成功删除指定 ID 的播放记录', () => {
      const record = playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1test',
        title: '测试'
      });

      const result = playHistoryService.removeHistoryById(record.id);

      expect(result).toBe(true);

      // 验证已删除
      const deleted = db.prepare('SELECT * FROM play_history WHERE id = ?').get(record.id);
      expect(deleted).toBeUndefined();
    });

    test('应支持删除多条记录中的特定一条', () => {
      const record1 = playHistoryService.recordPlay(testUserId, { bvid: 'BV1a', title: 'A' });
      const record2 = playHistoryService.recordPlay(testUserId, { bvid: 'BV1b', title: 'B' });
      const record3 = playHistoryService.recordPlay(testUserId, { bvid: 'BV1c', title: 'C' });

      // 删除中间的记录
      playHistoryService.removeHistoryById(record2.id);

      const records = db.prepare('SELECT * FROM play_history WHERE user_id = ? ORDER BY id')
        .all(testUserId);

      expect(records).toHaveLength(2);
      expect(records[0].id).toBe(record1.id);
      expect(records[1].id).toBe(record3.id);
    });

    test('删除不存在的 ID 不应报错', () => {
      expect(() => {
        playHistoryService.removeHistoryById(99999);
      }).not.toThrow();
    });
  });

  describe('getHistoryStats()', () => {
    test('应返回正确的播放统计信息', () => {
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1a', title: 'A' });
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1b', title: 'B' });
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1c', title: 'C' });

      const stats = playHistoryService.getHistoryStats(testUserId);

      expect(stats.totalPlays).toBe(3);
      expect(stats.lastPlayed).toBeDefined();
      expect(stats.lastPlayed.title).toBe('C'); // 最后插入的记录
    });

    test('空历史应返回零计数和 null 最后播放', () => {
      const stats = playHistoryService.getHistoryStats(testUserId);

      expect(stats.totalPlays).toBe(0);
      expect(stats.lastPlayed).toBeNull();
    });

    test('应正确区分不同用户的统计', () => {
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('otheruser', 'other@example.com', 'hash').lastInsertRowid;

      playHistoryService.recordPlay(testUserId, { bvid: 'BV1test', title: '测试用户' });
      playHistoryService.recordPlay(otherUserId, { bvid: 'BV1other', title: '其他用户' });

      const testStats = playHistoryService.getHistoryStats(testUserId);
      const otherStats = playHistoryService.getHistoryStats(otherUserId);

      expect(testStats.totalPlays).toBe(1);
      expect(otherStats.totalPlays).toBe(1);
      expect(testStats.lastPlayed.bvid).toBe('BV1test');
      expect(otherStats.lastPlayed.bvid).toBe('BV1other');
    });

    test('应包含完整的最后播放记录信息', () => {
      playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1full',
        title: '完整信息',
        artist: '歌手',
        duration: 180,
        coverUrl: 'https://example.com/cover.jpg',
        progress: 45
      });

      const stats = playHistoryService.getHistoryStats(testUserId);

      expect(stats.lastPlayed).toHaveProperty('id');
      expect(stats.lastPlayed).toHaveProperty('bvid');
      expect(stats.lastPlayed).toHaveProperty('title');
      expect(stats.lastPlayed).toHaveProperty('artist');
      expect(stats.lastPlayed).toHaveProperty('duration');
      expect(stats.lastPlayed).toHaveProperty('cover_url');
      expect(stats.lastPlayed).toHaveProperty('progress');
      expect(stats.lastPlayed).toHaveProperty('played_at');
      expect(stats.lastPlayed.title).toBe('完整信息');
      expect(stats.lastPlayed.progress).toBe(45);
    });

    test('lastPlayed 应指向最新播放的记录', () => {
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1old', title: '旧记录' });
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1new', title: '新记录' });

      const stats = playHistoryService.getHistoryStats(testUserId);

      expect(stats.lastPlayed.title).toBe('新记录');
    });
  });

  describe('音频类型区分', () => {
    test('在线音频应标记为 online', () => {
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1test', title: '在线' });

      const record = db.prepare('SELECT * FROM play_history WHERE user_id = ?').get(testUserId);

      expect(record.audio_type).toBe('online');
    });

    test('本地音频应标记为 local', () => {
      playHistoryService.recordPlay(testUserId, {
        localPath: 'C:/Music/test.mp3',
        title: '本地'
      });

      const record = db.prepare('SELECT * FROM play_history WHERE user_id = ?').get(testUserId);

      expect(record.audio_type).toBe('local');
    });

    test('统计应正确区分在线和本地音频', () => {
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1a', title: '在线A' });
      playHistoryService.recordPlay(testUserId, { bvid: 'BV1b', title: '在线B' });
      playHistoryService.recordPlay(testUserId, {
        localPath: 'C:/Music/local1.mp3',
        title: '本地1'
      });
      playHistoryService.recordPlay(testUserId, {
        localPath: 'C:/Music/local2.mp3',
        title: '本地2'
      });

      const allRecords = playHistoryService.getAllHistory(testUserId);

      expect(allRecords).toHaveLength(4);

      const onlineRecords = allRecords.filter(r => r.audio_type === 'online');
      const localRecords = allRecords.filter(r => r.audio_type === 'local');

      expect(onlineRecords).toHaveLength(2);
      expect(localRecords).toHaveLength(2);
    });
  });

  describe('边界情况', () => {
    test('处理特殊字符的本地路径', () => {
      const specialPath = 'C:/Music/Test Folder/中文-测试.mp3';

      const record = playHistoryService.recordPlay(testUserId, {
        localPath: specialPath,
        title: '特殊路径'
      });

      expect(record.local_path).toBe(specialPath);

      // 验证可以正确删除
      playHistoryService.removeHistoryItem(testUserId, null, specialPath);

      const deleted = db.prepare('SELECT * FROM play_history WHERE local_path = ?').get(specialPath);
      expect(deleted).toBeUndefined();
    });

    test('处理空字符串标题', () => {
      const record = playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1test',
        title: ''
      });

      expect(record.title).toBe('');
    });

    test('处理零进度', () => {
      const record = playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1test',
        title: '测试',
        progress: 0
      });

      expect(record.progress).toBe(0);
    });

    test('处理大时长值', () => {
      const longDuration = 7200; // 2小时

      const record = playHistoryService.recordPlay(testUserId, {
        bvid: 'BV1long',
        title: '长音频',
        duration: longDuration
      });

      expect(record.duration).toBe(longDuration);
    });
  });

  describe('游客模式支持', () => {
    test('null userId 应允许创建播放记录', () => {
      const record = playHistoryService.recordPlay(null, {
        bvid: 'BV1guest',
        title: '游客播放'
      });

      expect(record).toHaveProperty('id');
      expect(record.user_id).toBeNull();
    });

    test('游客记录不应被更新逻辑影响（userId 为 null）', () => {
      const first = playHistoryService.recordPlay(null, {
        bvid: 'BV1guest',
        title: '首次播放',
        progress: 10
      });

      // 游客模式下的"更新"实际上是插入新记录（因为没有 userId 来查找现有记录）
      const second = playHistoryService.recordPlay(null, {
        bvid: 'BV1guest',
        title: '继续播放',
        progress: 20
      });

      // 在游客模式下，由于 userId 为 null，无法通过 getHistoryByIdentifier 查找现有记录
      // 因此会插入新记录
      expect(second.id).not.toBe(first.id);
    });

    test('getHistory 不支持 null userId（返回空数组）', () => {
      playHistoryService.recordPlay(null, { bvid: 'BV1guest1', title: '游客1' });
      playHistoryService.recordPlay(null, { bvid: 'BV1guest2', title: '游客2' });

      // 服务实现中，WHERE user_id = ? 无法匹配 NULL（SQL: NULL = NULL 为 false）
      const history = playHistoryService.getHistory(null);

      expect(history).toEqual([]);
    });

    test('clearHistory 不支持 null userId（无法删除游客记录）', () => {
      playHistoryService.recordPlay(null, { bvid: 'BV1guest', title: '游客' });

      // 服务实现中，DELETE FROM play_history WHERE user_id = ? 无法匹配 NULL
      playHistoryService.clearHistory(null);

      const records = db.prepare('SELECT * FROM play_history WHERE user_id IS NULL').all();
      // 记录仍然存在，因为 SQL 无法匹配 NULL
      expect(records).toHaveLength(1);
      expect(records[0].bvid).toBe('BV1guest');
    });

    test('getHistoryStats 不支持 null userId（返回零计数）', () => {
      playHistoryService.recordPlay(null, { bvid: 'BV1guest', title: '游客' });

      // 服务实现中，COUNT 查询无法匹配 NULL
      const stats = playHistoryService.getHistoryStats(null);

      expect(stats.totalPlays).toBe(0);
      expect(stats.lastPlayed).toBeNull();
    });

    test('游客记录可通过 removeHistoryById 删除', () => {
      const record = playHistoryService.recordPlay(null, {
        bvid: 'BV1guest',
        title: '游客记录'
      });

      // 游客记录只能通过 ID 删除
      playHistoryService.removeHistoryById(record.id);

      const deleted = db.prepare('SELECT * FROM play_history WHERE id = ?').get(record.id);
      expect(deleted).toBeUndefined();
    });
  });
});
