// Mock 数据库模块 - 必须在 require bilibiliService 之前定义
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
    CREATE TABLE bilibili_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      bili_user_id TEXT,
      bili_username TEXT,
      cookie_encrypted TEXT NOT NULL,
      refresh_token_encrypted TEXT,
      is_active INTEGER DEFAULT 1,
      expires_at TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  db.exec(`
    CREATE TABLE platform_accounts (
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
    CREATE TABLE audio_content_cache (
      bvid TEXT PRIMARY KEY,
      data BLOB NOT NULL,
      content_type TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

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

  db.exec(`
    CREATE TABLE subtitle_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT NOT NULL,
      cid INTEGER,
      lan TEXT NOT NULL,
      lan_doc TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(bvid, lan)
    )
  `);

  return db;
});

// Mock fetch 全局
global.fetch = jest.fn();

const bilibiliService = require('../../services/bilibiliService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('B站服务测试', () => {
  // 在每个测试前清空表
  beforeEach(() => {
    db.exec('DELETE FROM users');
    db.exec('DELETE FROM bilibili_accounts');
    db.exec('DELETE FROM platform_accounts');
    db.exec('DELETE FROM search_history');
    db.exec('DELETE FROM subtitle_cache');
    jest.clearAllMocks();
  });

  // 辅助函数：创建测试用户
  const createTestUser = (id = 1) => {
    const bcrypt = require('bcryptjs');
    const hashedPassword = bcrypt.hashSync('password123', 10);

    // 插入用户，指定ID
    db.prepare('INSERT INTO users (id, username, email, password) VALUES (?, ?, ?, ?)')
      .run(id, `testuser${id}`, `test${id}@example.com`, hashedPassword);

    return id;
  };

  describe('encryptCookie() / decryptCookie()', () => {
    test('应能成功加密和解密Cookie', () => {
      const originalCookie = 'SESSDATA=xxx; DedeUserID=yyy; bili_jct=zzz';

      // 加密
      const encrypted = bilibiliService.encryptCookie(originalCookie);
      expect(encrypted).toBeDefined();
      expect(typeof encrypted).toBe('string');
      expect(encrypted).toContain(':'); // IV和密文的分隔符

      // 解密
      const decrypted = bilibiliService.decryptCookie(encrypted);
      expect(decrypted).toBe(originalCookie);
    });

    test('解密无效数据应返回null', () => {
      const invalidEncrypted = 'invalid:encrypted:data';
      const result = bilibiliService.decryptCookie(invalidEncrypted);
      expect(result).toBeNull();
    });

    test('解密空字符串应返回null', () => {
      const result = bilibiliService.decryptCookie('');
      expect(result).toBeNull();
    });
  });

  describe('getBindStatus()', () => {
    test('未绑定用户应返回 isBound: false', () => {
      const status = bilibiliService.getBindStatus(999);
      expect(status).toEqual({ isBound: false });
    });

    test('已绑定用户应返回用户信息', async () => {
      const userId = createTestUser(1);
      await bilibiliService.saveCookie(userId, 'SESSDATA=test', { mid: '123456', uname: 'TestUser' });

      const status = bilibiliService.getBindStatus(userId);

      expect(status.isBound).toBe(true);
      expect(status.userInfo.mid).toBe('123456');
      expect(status.userInfo.uname).toBe('TestUser');
    });

    test('过期绑定应返回 isBound: false', async () => {
      const userId = createTestUser(3);
      await bilibiliService.saveCookie(userId, 'SESSDATA=test', { mid: '123456', uname: 'TestUser' });
      
      // 设置过期时间为过去
      const expiresAt = new Date(Date.now() - 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);
      db.prepare('UPDATE platform_accounts SET expires_at = ? WHERE user_id = ? AND platform = ?')
        .run(expiresAt, userId, 'bilibili');

      const status = bilibiliService.getBindStatus(userId);

      expect(status).toEqual({ isBound: false });
    });
  });

  describe('unbindAccount()', () => {
    test('应成功解绑账号', async () => {
      const userId = createTestUser(1);
      await bilibiliService.saveCookie(userId, 'SESSDATA=test', { mid: '123456', uname: 'TestUser' });

      const result = bilibiliService.unbindAccount(userId);

      expect(result.success).toBe(true);

      // 验证账号已被删除
      const account = db.prepare('SELECT * FROM platform_accounts WHERE user_id = ? AND platform = ?').get(userId, 'bilibili');
      expect(account).toBeUndefined();
    });

    test('解绑不存在的账号也应返回成功', () => {
      const result = bilibiliService.unbindAccount(999);
      expect(result.success).toBe(true);
    });
  });

  describe('getRecentSearches()', () => {
    test('应返回最近的搜索关键词', () => {
      const userId = createTestUser(1);

      // 插入搜索历史
      const keywords = ['音乐', '动画', '游戏'];
      keywords.forEach(keyword => {
        db.prepare('INSERT INTO search_history (user_id, keyword) VALUES (?, ?)')
          .run(userId, keyword);
      });

      const searches = bilibiliService.getRecentSearches(userId);

      expect(searches).toHaveLength(3);
      expect(searches).toEqual(expect.arrayContaining(keywords));
    });

    test('没有搜索历史应返回空数组', () => {
      const searches = bilibiliService.getRecentSearches(999);
      expect(searches).toEqual([]);
    });

    test('应返回最多10条搜索历史', () => {
      const userId = createTestUser(1);

      // 插入15条搜索历史
      for (let i = 1; i <= 15; i++) {
        db.prepare('INSERT INTO search_history (user_id, keyword) VALUES (?, ?)')
          .run(userId, `搜索${i}`);
      }

      const searches = bilibiliService.getRecentSearches(userId);

      expect(searches).toHaveLength(10);
    });

    test('应去重关键词', () => {
      const userId = createTestUser(1);

      // 插入重复的搜索关键词
      db.prepare('INSERT INTO search_history (user_id, keyword) VALUES (?, ?)').run(userId, '音乐');
      db.prepare('INSERT INTO search_history (user_id, keyword) VALUES (?, ?)').run(userId, '动画');
      db.prepare('INSERT INTO search_history (user_id, keyword) VALUES (?, ?)').run(userId, '音乐');

      const searches = bilibiliService.getRecentSearches(userId);

      expect(searches).toHaveLength(2);
    });
  });

  describe('searchBilibili()', () => {
    test('应成功搜索并返回视频列表', async () => {
      // Mock WBI密钥请求
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          code: 0,
          data: {
            wbi_img: {
              img_url: 'https://example.com/testimgkey1234567890123456.png',
              sub_url: 'https://example.com/testsubkey1234567890123456.png'
            }
          }
        })
      });

      // Mock搜索请求
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          code: 0,
          data: {
            result: [
              {
                type: 'video',
                bvid: 'BV1xx411c7mD',
                title: '测试视频1',
                description: '这是一个测试视频',
                pic: '//example.com/cover1.jpg',
                duration: '3:45',
                author: '测试UP主',
                play: 10000,
                arcurl: 'https://www.bilibili.com/video/BV1xx411c7mD'
              },
              {
                type: 'video',
                bvid: 'BV1yy411c7mE',
                title: '测试视频2',
                description: '这是另一个测试视频',
                pic: '//example.com/cover2.jpg',
                duration: '5:20',
                author: '另一个UP主',
                play: 5000,
                arcurl: 'https://www.bilibili.com/video/BV1yy411c7mE'
              }
            ],
            numResults: 2
          }
        })
      });

      const result = await bilibiliService.searchBilibili('测试关键词');

      expect(result.keyword).toBe('测试关键词');
      expect(result.videos).toHaveLength(2);
      expect(result.videos[0]).toEqual({
        bvid: 'BV1xx411c7mD',
        title: '测试视频1',
        description: '这是一个测试视频',
        cover: 'https://example.com/cover1.jpg',
        duration: '3:45',
        author: '测试UP主',
        play: 10000,
        arcurl: 'https://www.bilibili.com/video/BV1xx411c7mD'
      });
      expect(result.total).toBe(2);
    });

    test('应正确处理URL中的封面图片', async () => {
      // WBI缓存已由上一个测试设置，这里直接Mock搜索请求
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          code: 0,
          data: {
            result: [
              {
                type: 'video',
                bvid: 'BV1xx411c7mD',
                title: '测试视频',
                description: '测试',
                pic: '//static.example.com/cover.jpg',
                duration: '3:00',
                author: 'UP主',
                play: 1000,
                arcurl: 'https://www.bilibili.com/video/BV1xx411c7mD'
              }
            ],
            numResults: 1
          }
        })
      });

      const result = await bilibiliService.searchBilibili('测试');

      expect(result.videos.length).toBeGreaterThan(0);
      expect(result.videos[0].cover).toBe('https://static.example.com/cover.jpg');
    });

    test('API返回错误时应抛出异常', async () => {
      // WBI缓存已设置，直接Mock搜索请求返回错误
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          code: -1,
          message: '请求失败'
        })
      });

      await expect(bilibiliService.searchBilibili('测试'))
        .rejects.toThrow('搜索失败: 请求失败');
    });

    test('HTTP请求失败时应抛出异常', async () => {
      // WBI缓存已设置，直接Mock搜索请求失败
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await expect(bilibiliService.searchBilibili('测试'))
        .rejects.toThrow('搜索失败: Network error');
    });

    test('应记录搜索历史', async () => {
      const userId = createTestUser(1);

      // WBI缓存已设置，直接Mock搜索请求
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          code: 0,
          data: {
            result: [],
            numResults: 0
          }
        })
      });

      await bilibiliService.searchBilibili('测试关键词', 1, 20, userId);

      // 等待异步的setTimeout执行
      await new Promise(resolve => setTimeout(resolve, 10));

      const searches = db.prepare('SELECT * FROM search_history WHERE user_id = ?').all(userId);
      expect(searches.length).toBeGreaterThan(0);
      expect(searches[0].keyword).toBe('测试关键词');
    });
  });

  describe('getVideoInfo()', () => {
    test('应成功获取视频信息', async () => {
      const mockVideoInfo = {
        code: 0,
        data: {
          bvid: 'BV1xx411c7mD',
          title: '测试视频',
          desc: '视频描述',
          pic: 'https://example.com/cover.jpg',
          duration: 225,
          pubdate: 1234567890,
          cid: 12345,
          owner: {
            mid: 123456,
            name: '测试UP主',
            face: 'https://example.com/avatar.jpg'
          },
          stat: {
            view: 10000,
            like: 500,
            coin: 200,
            favorite: 100,
            danmaku: 300
          },
          pages: [
            { cid: 12345, page: 1, part: 'P1', duration: 225 }
          ]
        }
      };

      const mockAudioUrl = {
        code: 0,
        data: {
          timelength: 225000,
          dash: {
            audio: [
              { baseUrl: 'https://example.com/audio.m4a', bandwidth: 192000 }
            ]
          }
        }
      };

      // Mock两次fetch调用：1) getVideoInfo, 2) getAudioStream
      global.fetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockVideoInfo
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockAudioUrl
        });

      const result = await bilibiliService.getVideoInfo('BV1xx411c7mD');

      expect(result.bvid).toBe('BV1xx411c7mD');
      expect(result.title).toBe('测试视频');
      expect(result.owner.name).toBe('测试UP主');
      expect(result.stat.view).toBe(10000);
      expect(result.stream_url).toBe('https://example.com/audio.m4a');
    });

    test('API返回错误时应抛出异常', async () => {
      const mockResponse = {
        code: -400,
        message: '视频不存在'
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await expect(bilibiliService.getVideoInfo('BV1invalid'))
        .rejects.toThrow('获取视频信息失败: 视频不存在');
    });

    test('HTTP请求失败时应抛出异常', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await expect(bilibiliService.getVideoInfo('BV1xx411c7mD'))
        .rejects.toThrow('获取视频信息失败: Network error');
    });

    test('应正确处理缺失的统计数据', async () => {
      const mockVideoInfo = {
        code: 0,
        data: {
          bvid: 'BV1xx411c7mD',
          title: '测试视频',
          desc: '',
          pic: '',
          duration: 225,
          pubdate: 1234567890,
          cid: 12345,
          owner: {
            mid: 123456,
            name: '测试UP主',
            face: ''
          },
          stat: null,
          pages: []
        }
      };

      const mockAudioUrl = {
        code: 0,
        data: {
          timelength: 225000,
          dash: {
            audio: []
          }
        }
      };

      global.fetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockVideoInfo
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockAudioUrl
        });

      const result = await bilibiliService.getVideoInfo('BV1xx411c7mD');

      expect(result.stat.view).toBe(0);
      expect(result.stat.like).toBe(0);
      expect(result.stream_url).toBeNull();
    });
  });

  describe('signWbi()', () => {
    test('应正确生成WBI签名', () => {
      const params = {
        mid: '123456',
        pn: 1,
        ps: 20
      };

      const wbiKey = {
        imgKey: 'testimgkey1234567890123456',
        subKey: 'testsubkey1234567890123456'
      };

      const result = bilibiliService.signWbi(params, wbiKey);

      expect(result).toHaveProperty('w_rid');
      expect(result).toHaveProperty('wts');
      expect(result).toHaveProperty('mid', '123456');
      expect(result).toHaveProperty('pn', 1);
      expect(result).toHaveProperty('ps', 20);

      // wts 应该是时间戳（秒）
      expect(result.wts).toBeGreaterThan(0);
      expect(result.wts).toBeLessThanOrEqual(Math.floor(Date.now() / 1000));

      // w_rid 应该是32位MD5哈希
      expect(result.w_rid).toHaveLength(32);
      expect(/^[a-f0-9]{32}$/.test(result.w_rid)).toBe(true);
    });

    test('相同参数应生成相同的签名', () => {
      const params = {
        mid: '123456',
        pn: 1,
        ps: 20
      };

      const wbiKey = {
        imgKey: 'testimgkey1234567890123456',
        subKey: 'testsubkey1234567890123456'
      };

      // 冻结时间以确保wts一致
      const now = Math.floor(Date.now() / 1000);
      jest.spyOn(Date, 'now').mockReturnValue(now * 1000);

      const result1 = bilibiliService.signWbi(params, wbiKey);
      const result2 = bilibiliService.signWbi(params, wbiKey);

      expect(result1.w_rid).toBe(result2.w_rid);
      expect(result1.wts).toBe(result2.wts);

      jest.restoreAllMocks();
    });

    test('不同参数应生成不同的签名', () => {
      const wbiKey = {
        imgKey: 'testimgkey1234567890123456',
        subKey: 'testsubkey1234567890123456'
      };

      const now = Math.floor(Date.now() / 1000);
      jest.spyOn(Date, 'now').mockReturnValue(now * 1000);

      const result1 = bilibiliService.signWbi({ mid: '123456' }, wbiKey);
      const result2 = bilibiliService.signWbi({ mid: '789012' }, wbiKey);

      expect(result1.w_rid).not.toBe(result2.w_rid);

      jest.restoreAllMocks();
    });
  });

  describe('getVideoSubtitles()', () => {
    const mockVideoInfoResponse = {
      code: 0,
      data: {
        bvid: 'BV1test123', title: '测试视频', desc: '', pic: '',
        duration: 100, pubdate: 1234567890, cid: 99999,
        owner: { mid: 123, name: 'UP主', face: '' }, stat: {}, pages: []
      }
    };
    const mockAudioUrlResponse = { code: 0, data: { dash: { audio: [] } } };
    const mockNavResponse = {
      code: 0,
      data: {
        wbi_img: {
          img_url: 'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
          sub_url: 'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png'
        }
      }
    };

    /**
     * Setup URL-based fetch mock for subtitle tests
     * Avoids WBI key cache interference by matching URL patterns
     */
    const setupFetchMock = (playerResponse, subtitleResponse = null) => {
      global.fetch.mockImplementation(async (url) => {
        const urlStr = typeof url === 'string' ? url : url.toString();
        if (urlStr.includes('x/web-interface/view')) {
          return { ok: true, json: async () => mockVideoInfoResponse };
        }
        if (urlStr.includes('x/player/playurl')) {
          return { ok: true, json: async () => mockAudioUrlResponse };
        }
        if (urlStr.includes('x/web-interface/nav')) {
          return { ok: true, json: async () => mockNavResponse };
        }
        if (urlStr.includes('x/player/wbi/v2')) {
          return { ok: true, json: async () => playerResponse };
        }
        if (urlStr.includes('aisubtitle.hdslb.com') && subtitleResponse) {
          return { ok: true, json: async () => subtitleResponse };
        }
        throw new Error(`Unexpected fetch URL: ${urlStr}`);
      });
    };

    test('应返回字幕列表（有字幕的视频）', async () => {
      const userId = createTestUser(1);
      await bilibiliService.saveCookie(userId, 'SESSDATA=test; bili_jct=xxx', { mid: '123456', uname: 'TestUser' });

      const playerData = {
        code: 0,
        data: {
          subtitle: {
            subtitles: [
              {
                lan: 'zh-Hans',
                lan_doc: '中文（简体）',
                subtitle_url: '//aisubtitle.hdslb.com/bfs/subtitle/test.json?auth_key=abc'
              }
            ]
          }
        }
      };
      const subtitleContent = {
        body: [
          { from: 0.0, to: 3.5, content: '大家好' },
          { from: 3.5, to: 7.2, content: '今天我们来聊一聊' }
        ]
      };

      setupFetchMock(playerData, subtitleContent);

      const result = await bilibiliService.getVideoSubtitles('BV1test123', userId);

      expect(result.bvid).toBe('BV1test123');
      expect(result.subtitles).toHaveLength(1);
      expect(result.subtitles[0].lan).toBe('zh-Hans');
      expect(result.subtitles[0].lan_doc).toBe('中文（简体）');
      expect(result.subtitles[0].lines).toHaveLength(2);
      expect(result.subtitles[0].lines[0].content).toBe('大家好');
      expect(result.subtitles[0].lines[1].from).toBe(3.5);
    });

    test('应返回空数组（无字幕的视频）', async () => {
      const userId = createTestUser(1);
      await bilibiliService.saveCookie(userId, 'SESSDATA=test; bili_jct=xxx', { mid: '123456', uname: 'TestUser' });

      const playerData = {
        code: 0,
        data: { subtitle: { subtitles: [] } }
      };

      setupFetchMock(playerData);

      const result = await bilibiliService.getVideoSubtitles('BV1nosub', userId);

      expect(result.bvid).toBe('BV1nosub');
      expect(result.subtitles).toHaveLength(0);
    });

    test('未绑定账号时应抛出错误', async () => {
      const userId = createTestUser(1);

      setupFetchMock({ code: 0, data: {} });

      await expect(bilibiliService.getVideoSubtitles('BV1test', userId))
        .rejects.toThrow('需要绑定B站账号才能获取字幕');
    });

    test('B站 API 异常时应抛出错误', async () => {
      const userId = createTestUser(1);
      await bilibiliService.saveCookie(userId, 'SESSDATA=test; bili_jct=xxx', { mid: '123456', uname: 'TestUser' });

      const playerData = {
        code: -403,
        message: '访问权限不足'
      };

      setupFetchMock(playerData);

      await expect(bilibiliService.getVideoSubtitles('BV1err', userId))
        .rejects.toThrow('访问权限不足');
    });

    test('应使用缓存的字幕数据', async () => {
      const lines = [
        { from: 0, to: 3, content: '缓存内容' }
      ];
      db.prepare('INSERT INTO subtitle_cache (bvid, cid, lan, lan_doc, content) VALUES (?, ?, ?, ?, ?)')
        .run('BV1cached', 12345, 'zh-Hans', '中文（简体）', JSON.stringify(lines));

      const result = await bilibiliService.getVideoSubtitles('BV1cached', 1);

      expect(global.fetch).not.toHaveBeenCalled();
      expect(result.bvid).toBe('BV1cached');
      expect(result.subtitles).toHaveLength(1);
      expect(result.subtitles[0].lines[0].content).toBe('缓存内容');
    });
  });
});
