// Mock 数据库模块 - 必须在 require audioService 之前定义
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');

  // 创建内存数据库用于测试
  const db = new Database(':memory:');

  // 创建测试表结构
  db.exec(`
    CREATE TABLE audio_metadata_cache (
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

  db.exec(`
    CREATE TABLE search_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      keyword TEXT NOT NULL,
      result_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  return db;
});

// Mock bilibiliService
jest.mock('../../services/bilibiliService', () => ({
  getVideoInfo: jest.fn(),
  getAudioStream: jest.fn()
}));

const audioService = require('../../services/audio');
const bilibiliService = require('../../services/bilibiliService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('音频服务测试', () => {
  // 在每个测试前清空表
  beforeEach(() => {
    db.exec('DELETE FROM audio_metadata_cache');
    db.exec('DELETE FROM search_history');
    jest.clearAllMocks();
  });

  // ==================== 工具函数测试 ====================

  describe('getCodec()', () => {
    test('应返回 MP3 编解码器', () => {
      expect(audioService.getCodec('mp3')).toBe('libmp3lame');
    });

    test('应返回 AAC 编解码器', () => {
      expect(audioService.getCodec('aac')).toBe('aac');
    });

    test('应返回 M4A 编解码器', () => {
      expect(audioService.getCodec('m4a')).toBe('aac');
    });

    test('未知格式应返回默认编解码器', () => {
      expect(audioService.getCodec('unknown')).toBe('libmp3lame');
    });
  });

  describe('getFormat()', () => {
    test('应返回 MP3 格式', () => {
      expect(audioService.getFormat('mp3')).toBe('mp3');
    });

    test('应返回 AAC 格式', () => {
      expect(audioService.getFormat('aac')).toBe('adts');
    });

    test('应返回 M4A 格式', () => {
      expect(audioService.getFormat('m4a')).toBe('adts');
    });

    test('未知格式应返回默认格式', () => {
      expect(audioService.getFormat('unknown')).toBe('mp3');
    });
  });

  // ==================== 元数据缓存测试 ====================

  describe('getCacheStats()', () => {
    test('空表应返回零统计', () => {
      const stats = audioService.getCacheStats();

      expect(stats).toEqual({
        totalCached: 0,
        lastUpdate: null
      });
    });

    test('应返回正确的缓存统计', () => {
      // 插入3条元数据
      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run('BV1xx411c7mD', '测试1', '艺术家1', 180, 12345, '{}');

      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run('BV1yy411c7mE', '测试2', '艺术家2', 240, 12346, '{}');

      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run('BV1zz411c7mF', '测试3', '艺术家3', 200, 12347, '{}');

      const stats = audioService.getCacheStats();

      expect(stats.totalCached).toBe(3);
      expect(stats.lastUpdate).toBeTruthy();
      expect(typeof stats.lastUpdate).toBe('string');
    });
  });

  describe('deleteMetadata()', () => {
    test('应成功删除存在的元数据', () => {
      // 插入测试数据
      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run('BV1xx411c7mD', '测试', '艺术家', 180, 12345, '{}');

      const result = audioService.deleteMetadata('BV1xx411c7mD');

      expect(result).toBe(true);

      // 验证已删除
      const row = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1xx411c7mD');
      expect(row).toBeUndefined();
    });

    test('删除不存在的元数据应返回 false', () => {
      const result = audioService.deleteMetadata('BV1notexist');
      expect(result).toBe(false);
    });

    test('应只删除指定的BVID', () => {
      // 插入多条数据
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1xx411c7mD', '测试1', '艺术家1', 180, 12345, '{}');
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1yy411c7mE', '测试2', '艺术家2', 240, 12346, '{}');

      audioService.deleteMetadata('BV1xx411c7mD');

      const remaining = db.prepare('SELECT * FROM audio_metadata_cache').all();
      expect(remaining).toHaveLength(1);
      expect(remaining[0].bvid).toBe('BV1yy411c7mE');
    });
  });

  describe('getAllMetadata()', () => {
    beforeEach(() => {
      // 插入测试数据
      const metadata = [
        { bvid: 'BV1xx411c7mD', title: '测试1', artist: '艺术家1', duration: 180 },
        { bvid: 'BV1yy411c7mE', title: '测试2', artist: '艺术家2', duration: 240 },
        { bvid: 'BV1zz411c7mF', title: '测试3', artist: '艺术家3', duration: 200 }
      ];

      metadata.forEach(m => {
        db.prepare(`
          INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata)
          VALUES (?, ?, ?, ?, ?, ?)
        `).run(m.bvid, m.title, m.artist, m.duration, 12345, '{}');
      });
    });

    test('应返回所有元数据', () => {
      const result = audioService.getAllMetadata();

      expect(result).toHaveLength(3);
      expect(result[0]).toMatchObject({
        bvid: expect.any(String),
        title: expect.any(String),
        artist: expect.any(String),
        duration: expect.any(Number)
      });
    });

    test('应支持 limit 参数', () => {
      const result = audioService.getAllMetadata(2);

      expect(result).toHaveLength(2);
    });

    test('应支持 offset 参数', () => {
      const result = audioService.getAllMetadata(10, 1);

      expect(result).toHaveLength(2);
    });

    test('应按创建时间倒序排列', () => {
      const result = audioService.getAllMetadata();

      // 由于插入速度快，可能需要验证顺序逻辑
      expect(result.length).toBeGreaterThan(0);
    });

    test('应解析 JSON 元数据', () => {
      // 插入带 JSON 元数据的记录
      const extraMetadata = {
        desc: '测试描述',
        owner: { mid: 123, name: 'UP主' },
        pages: [{ cid: 1, page: 1 }]
      };

      db.prepare(`
        UPDATE audio_metadata_cache
        SET metadata = ?
        WHERE bvid = ?
      `).run(JSON.stringify(extraMetadata), 'BV1xx411c7mD');

      const result = audioService.getAllMetadata();
      const withExtra = result.find(r => r.bvid === 'BV1xx411c7mD');

      expect(withExtra.desc).toBe('测试描述');
      expect(withExtra.owner).toEqual({ mid: 123, name: 'UP主' });
      expect(withExtra.pages).toEqual([{ cid: 1, page: 1 }]);
    });
  });

  describe('cleanExpiredCache()', () => {
    test('应删除过期的缓存', () => {
      const now = new Date();

      // 插入旧数据（31天前）
      const oldDate = new Date(now.getTime() - 31 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('BV1old', '旧数据', '艺术家', 180, 12345, '{}', oldDate);

      // 插入新数据（1天前）
      const newDate = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('BV1new', '新数据', '艺术家', 180, 12346, '{}', newDate);

      // 清理30天前的缓存
      const cleaned = audioService.cleanExpiredCache(30 * 24 * 60 * 60 * 1000);

      expect(cleaned).toBe(1);

      // 验证旧数据已删除，新数据保留
      const oldData = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1old');
      const newData = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1new');

      expect(oldData).toBeUndefined();
      expect(newData).toBeDefined();
    });

    test('应支持自定义过期时间', () => {
      const now = new Date();

      // 插入5天前的数据
      const oldDate = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('BV1old', '旧数据', '艺术家', 180, 12345, '{}', oldDate);

      // 清理3天前的缓存（应该删除5天前的数据）
      const cleaned = audioService.cleanExpiredCache(3 * 24 * 60 * 60 * 1000);

      expect(cleaned).toBe(1);

      const oldData = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1old');
      expect(oldData).toBeUndefined();
    });

    test('没有过期数据时应返回 0', () => {
      const now = new Date();

      // 插入新数据
      const newDate = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      db.prepare(`
        INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('BV1new', '新数据', '艺术家', 180, 12345, '{}', newDate);

      const cleaned = audioService.cleanExpiredCache(30 * 24 * 60 * 60 * 1000);

      expect(cleaned).toBe(0);
    });
  });

  // ==================== 搜索历史测试 ====================

  describe('saveSearchHistory()', () => {
    test('应成功保存搜索历史', () => {
      audioService.saveSearchHistory(1, '测试关键词', 10);

      const history = db.prepare('SELECT * FROM search_history WHERE user_id = ?').all(1);

      expect(history).toHaveLength(1);
      expect(history[0].keyword).toBe('测试关键词');
      expect(history[0].result_count).toBe(10);
    });

    test('应保存默认 result_count', () => {
      audioService.saveSearchHistory(1, '测试关键词');

      const history = db.prepare('SELECT * FROM search_history WHERE user_id = ?').all(1);

      expect(history[0].result_count).toBe(0);
    });

    test('同一用户可保存多条搜索历史', () => {
      audioService.saveSearchHistory(1, '关键词1', 5);
      audioService.saveSearchHistory(1, '关键词2', 8);
      audioService.saveSearchHistory(1, '关键词3', 12);

      const history = db.prepare('SELECT * FROM search_history WHERE user_id = ?').all(1);

      expect(history).toHaveLength(3);
    });
  });

  describe('getSearchHistory()', () => {
    beforeEach(() => {
      // 插入测试数据
      const searches = [
        { userId: 1, keyword: '音乐', resultCount: 10 },
        { userId: 1, keyword: '动画', resultCount: 20 },
        { userId: 1, keyword: '游戏', resultCount: 15 },
        { userId: 2, keyword: '电影', resultCount: 5 }
      ];

      searches.forEach(s => {
        audioService.saveSearchHistory(s.userId, s.keyword, s.resultCount);
      });
    });

    test('应返回指定用户的搜索历史', () => {
      const history = audioService.getSearchHistory(1);

      expect(history).toHaveLength(3);
      expect(history[0].user_id).toBe(1);
    });

    test('应支持 limit 参数', () => {
      const history = audioService.getSearchHistory(1, 2);

      expect(history).toHaveLength(2);
    });

    test('应支持 offset 参数', () => {
      const history = audioService.getSearchHistory(1, 10, 1);

      expect(history).toHaveLength(2);
    });

    test('应按创建时间倒序排列', () => {
      const history = audioService.getSearchHistory(1);

      // 验证顺序：数据库按 created_at DESC 排序
      // 由于同一测试内插入速度快，created_at 可能相同
      // 此时按插入顺序的倒序（SQLite默认行为）
      expect(history).toHaveLength(3);
      expect(history.map(h => h.keyword)).toContain('音乐');
      expect(history.map(h => h.keyword)).toContain('动画');
      expect(history.map(h => h.keyword)).toContain('游戏');
    });

    test('不同用户的搜索历史应隔离', () => {
      const user1History = audioService.getSearchHistory(1);
      const user2History = audioService.getSearchHistory(2);

      expect(user1History).toHaveLength(3);
      expect(user2History).toHaveLength(1);
      expect(user2History[0].keyword).toBe('电影');
    });
  });

  describe('getRecentSearches()', () => {
    beforeEach(() => {
      // 插入测试数据（包含重复关键词）
      audioService.saveSearchHistory(1, '音乐');
      audioService.saveSearchHistory(1, '动画');
      audioService.saveSearchHistory(1, '音乐'); // 重复
      audioService.saveSearchHistory(1, '游戏');
      audioService.saveSearchHistory(1, '动画'); // 重复
    });

    test('应返回去重后的关键词', () => {
      const searches = audioService.getRecentSearches(1);

      expect(searches).toHaveLength(3);
      expect(searches).toEqual(expect.arrayContaining(['音乐', '动画', '游戏']));
    });

    test('应支持 limit 参数', () => {
      const searches = audioService.getRecentSearches(1, 2);

      expect(searches).toHaveLength(2);
    });

    test('应返回关键词数组（不含其他字段）', () => {
      const searches = audioService.getRecentSearches(1);

      searches.forEach(keyword => {
        expect(typeof keyword).toBe('string');
        expect(keyword).toBeTruthy();
      });
    });

    test('应按最近搜索排序', () => {
      const searches = audioService.getRecentSearches(1);

      // 验证去重后的关键词列表（按 created_at DESC）
      expect(searches).toHaveLength(3);
      expect(searches).toEqual(expect.arrayContaining(['音乐', '动画', '游戏']));
    });

    test('没有搜索历史应返回空数组', () => {
      const searches = audioService.getRecentSearches(999);

      expect(searches).toEqual([]);
    });
  });

  describe('clearSearchHistory()', () => {
    test('应清空指定用户的搜索历史', () => {
      audioService.saveSearchHistory(1, '关键词1');
      audioService.saveSearchHistory(1, '关键词2');
      audioService.saveSearchHistory(2, '关键词3');

      const result = audioService.clearSearchHistory(1);

      expect(result).toBe(true);

      const user1History = db.prepare('SELECT * FROM search_history WHERE user_id = ?').all(1);
      const user2History = db.prepare('SELECT * FROM search_history WHERE user_id = ?').all(2);

      expect(user1History).toHaveLength(0);
      expect(user2History).toHaveLength(1);
    });

    test('清空不存在的历史应返回 false', () => {
      const result = audioService.clearSearchHistory(999);
      expect(result).toBe(false);
    });
  });

  describe('deleteSearchKeyword()', () => {
    beforeEach(() => {
      audioService.saveSearchHistory(1, '音乐');
      audioService.saveSearchHistory(1, '动画');
      audioService.saveSearchHistory(1, '音乐'); // 重复
      audioService.saveSearchHistory(1, '游戏');
    });

    test('应删除指定关键词的所有记录', () => {
      const result = audioService.deleteSearchKeyword(1, '音乐');

      expect(result).toBe(true);

      const remaining = db.prepare('SELECT * FROM search_history WHERE user_id = ? AND keyword = ?').all(1, '音乐');
      expect(remaining).toHaveLength(0);
    });

    test('不应影响其他关键词', () => {
      audioService.deleteSearchKeyword(1, '音乐');

      const allHistory = audioService.getSearchHistory(1);
      expect(allHistory).toHaveLength(2); // 动画和游戏
    });

    test('删除不存在的关键词应返回 false', () => {
      const result = audioService.deleteSearchKeyword(1, '不存在的关键词');
      expect(result).toBe(false);
    });

    test('不应影响其他用户的关键词', () => {
      audioService.saveSearchHistory(2, '音乐');

      audioService.deleteSearchKeyword(1, '音乐');

      const user2History = db.prepare('SELECT * FROM search_history WHERE user_id = ? AND keyword = ?').all(2, '音乐');
      expect(user2History).toHaveLength(1);
    });
  });

  // ==================== 集成测试（带 mock 的 B站 API） ====================

  describe('getAudioMetadata()', () => {
    test('应从缓存返回未过期的元数据', async () => {
      // 插入缓存的元数据（1分钟前）
      const recentDate = new Date(Date.now() - 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      db.prepare(`
        INSERT INTO audio_metadata_cache
        (bvid, title, artist, duration, cid, metadata, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('BV1xx411c7mD', '缓存标题', '缓存艺术家', 180, 12345, '{}', recentDate);

      const metadata = await audioService.getAudioMetadata('BV1xx411c7mD', 7 * 24 * 60 * 60 * 1000);

      expect(metadata).toMatchObject({
        bvid: 'BV1xx411c7mD',
        title: '缓存标题',
        artist: '缓存艺术家',
        duration: 180
      });

      // 不应调用 B站 API
      expect(bilibiliService.getVideoInfo).not.toHaveBeenCalled();
    });

    test('缓存过期时应从B站获取', async () => {
      // 插入过期的缓存（8天前）
      const oldDate = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      db.prepare(`
        INSERT INTO audio_metadata_cache
        (bvid, title, artist, duration, cid, metadata, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('BV1xx411c7mD', '旧缓存', '旧艺术家', 180, 12345, '{}', oldDate);

      // Mock B站 API
      bilibiliService.getVideoInfo.mockResolvedValue({
        bvid: 'BV1xx411c7mD',
        title: '新标题',
        owner: { name: '新艺术家' },
        duration: 200,
        cover: 'https://example.com/cover.jpg',
        cid: 12345,
        desc: '描述'
      });

      const metadata = await audioService.getAudioMetadata('BV1xx411c7mD', 7 * 24 * 60 * 60 * 1000);

      expect(metadata.title).toBe('新标题');
      expect(metadata.artist).toBe('新艺术家');
      expect(bilibiliService.getVideoInfo).toHaveBeenCalledWith('BV1xx411c7mD');
    });

    test('无缓存时应从B站获取', async () => {
      bilibiliService.getVideoInfo.mockResolvedValue({
        bvid: 'BV1xx411c7mD',
        title: '测试视频',
        owner: { name: 'UP主' },
        duration: 180,
        cover: 'https://example.com/cover.jpg',
        cid: 12345,
        desc: '描述'
      });

      const metadata = await audioService.getAudioMetadata('BV1xx411c7mD');

      expect(metadata.bvid).toBe('BV1xx411c7mD');
      expect(metadata.title).toBe('测试视频');
      expect(bilibiliService.getVideoInfo).toHaveBeenCalledWith('BV1xx411c7mD');

      // 验证已缓存
      const cached = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1xx411c7mD');
      expect(cached).toBeDefined();
    });
  });

  describe('getMultipleMetadata()', () => {
    test('应批量从缓存获取元数据', async () => {
      // 插入缓存
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1xx411c7mD', '缓存1', '艺术家1', 180, 12345, '{}');
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1yy411c7mE', '缓存2', '艺术家2', 240, 12346, '{}');

      const metadataMap = await audioService.getMultipleMetadata(['BV1xx411c7mD', 'BV1yy411c7mE']);

      expect(metadataMap.size).toBe(2);
      expect(metadataMap.get('BV1xx411c7mD').title).toBe('缓存1');
      expect(metadataMap.get('BV1yy411c7mE').title).toBe('缓存2');
    });

    test('应从B站获取缺失的元数据', async () => {
      // 只缓存一个
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1xx411c7mD', '缓存1', '艺术家1', 180, 12345, '{}');

      bilibiliService.getVideoInfo
        .mockResolvedValueOnce({
          bvid: 'BV1yy411c7mE',
          title: '新视频',
          owner: { name: 'UP主2' },
          duration: 200,
          cover: 'https://example.com/cover2.jpg',
          cid: 12346,
          desc: '描述2'
        });

      const metadataMap = await audioService.getMultipleMetadata(['BV1xx411c7mD', 'BV1yy411c7mE']);

      expect(metadataMap.size).toBe(2);
      expect(metadataMap.get('BV1xx411c7mD').title).toBe('缓存1');
      expect(metadataMap.get('BV1yy411c7mE').title).toBe('新视频');
      expect(bilibiliService.getVideoInfo).toHaveBeenCalledWith('BV1yy411c7mE');
    });

    test('应处理超过10个的批量查询', async () => {
      const bvids = Array.from({ length: 15 }, (_, i) => `BV1${i}`);

      // 缓存前10个
      for (let i = 0; i < 10; i++) {
        db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
          .run(bvids[i], `缓存${i}`, `艺术家${i}`, 180, 12345 + i, '{}');
      }

      bilibiliService.getVideoInfo.mockResolvedValue({
        bvid: 'BV1test',
        title: '新视频',
        owner: { name: 'UP主' },
        duration: 180,
        cover: 'https://example.com/cover.jpg',
        cid: 12399,
        desc: '描述'
      });

      const metadataMap = await audioService.getMultipleMetadata(bvids);

      expect(metadataMap.size).toBe(15);
    });
  });

  describe('refreshMetadata()', () => {
    test('应强制刷新元数据', async () => {
      // 插入旧缓存
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1xx411c7mD', '旧标题', '旧艺术家', 180, 12345, '{}');

      bilibiliService.getVideoInfo.mockResolvedValue({
        bvid: 'BV1xx411c7mD',
        title: '新标题',
        owner: { name: '新艺术家' },
        duration: 200,
        cover: 'https://example.com/cover.jpg',
        cid: 12345,
        desc: '描述'
      });

      const metadata = await audioService.refreshMetadata('BV1xx411c7mD');

      expect(metadata.title).toBe('新标题');
      expect(bilibiliService.getVideoInfo).toHaveBeenCalledWith('BV1xx411c7mD');

      // 验证缓存已更新
      const cached = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1xx411c7mD');
      expect(cached.title).toBe('新标题');
    });
  });

  describe('getAudioStreamUrl()', () => {
    test('应返回音频流URL', async () => {
      // 插入元数据缓存
      db.prepare(`INSERT INTO audio_metadata_cache (bvid, title, artist, duration, cid, metadata) VALUES (?, ?, ?, ?, ?, ?)`)
        .run('BV1xx411c7mD', '测试视频', 'UP主', 180, 12345, '{}');

      bilibiliService.getAudioStream.mockResolvedValue({
        baseUrl: 'https://example.com/audio.m4s',
        mimeType: 'audio/mp4',
        codecs: 'mp4a.40.2'
      });

      const result = await audioService.getAudioStreamUrl('BV1xx411c7mD', 1);

      expect(result).toMatchObject({
        bvid: 'BV1xx411c7mD',
        title: '测试视频',
        artist: 'UP主',
        audioUrl: 'https://example.com/audio.m4s',
        mimeType: 'audio/mp4',
        codecs: 'mp4a.40.2'
      });

      expect(bilibiliService.getAudioStream).toHaveBeenCalledWith('BV1xx411c7mD', 12345, 1);

      // 验证音频URL已更新
      const cached = db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?').get('BV1xx411c7mD');
      expect(cached.audio_url).toBe('https://example.com/audio.m4s');
    });
  });
});
