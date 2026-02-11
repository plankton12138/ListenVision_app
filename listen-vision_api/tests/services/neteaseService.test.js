jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');
  const db = new Database(':memory:');

  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
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

  return db;
});

global.fetch = jest.fn();

const neteaseService = require('../../services/neteaseService');
const db = require('../../config/database');

describe('NeteaseService', () => {
  let testUserId;

  beforeEach(() => {
    jest.clearAllMocks();
    
    db.exec('DELETE FROM platform_accounts');
    db.exec('DELETE FROM users');
    
    const result = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)').run('testuser', 'test@test.com', 'hash');
    testUserId = result.lastInsertRowid;
  });

  describe('getQRCode', () => {
    it('should get QR code successfully', async () => {
      fetch
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ code: 200, data: { unikey: 'test-key' } }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ code: 200, data: { qrimg: 'base64img', qrurl: 'http://url' } }),
        });

      const result = await neteaseService.getQRCode();

      expect(result.key).toBe('test-key');
      expect(result.qrimg).toBe('base64img');
      expect(result.qrurl).toBe('http://url');
    });

    it('should throw error when key fetch fails', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ code: 400, message: 'Error' }),
      });

      await expect(neteaseService.getQRCode()).rejects.toThrow('获取二维码失败');
    });
  });

  describe('checkQRLoginStatus', () => {
    it('should return pending status', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ code: 801 }),
      });

      const result = await neteaseService.checkQRLoginStatus('test-key');

      expect(result.status).toBe('pending');
    });

    it('should return expired status', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ code: 800 }),
      });

      const result = await neteaseService.checkQRLoginStatus('test-key');

      expect(result.status).toBe('expired');
    });

    it('should return success status with cookie', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ code: 803, cookie: 'test-cookie' }),
      });

      const result = await neteaseService.checkQRLoginStatus('test-key');

      expect(result.status).toBe('success');
      expect(result.cookie).toBe('test-cookie');
    });
  });

  describe('saveAccount and getCookie', () => {
    it('should save and retrieve account', async () => {
      await neteaseService.saveAccount(testUserId, {
        platformUserId: '12345',
        platformUsername: 'testuser',
        cookie: 'test-cookie',
      });

      const cookie = neteaseService.getCookie(testUserId);
      expect(cookie).toBe('test-cookie');
    });

    it('should return null for non-existent account', () => {
      const cookie = neteaseService.getCookie(999);
      expect(cookie).toBeNull();
    });
  });

  describe('getBindStatus', () => {
    it('should return bound status', async () => {
      await neteaseService.saveAccount(testUserId, {
        platformUserId: '12345',
        platformUsername: 'testuser',
        cookie: 'test-cookie',
      });

      const status = neteaseService.getBindStatus(testUserId);

      expect(status.isBound).toBe(true);
      expect(status.userInfo.id).toBe('12345');
      expect(status.userInfo.username).toBe('testuser');
    });

    it('should return not bound status', () => {
      const status = neteaseService.getBindStatus(testUserId);
      expect(status.isBound).toBe(false);
    });
  });

  describe('unbindAccount', () => {
    it('should unbind account', async () => {
      await neteaseService.saveAccount(testUserId, {
        cookie: 'test-cookie',
      });

      neteaseService.unbindAccount(testUserId);

      const cookie = neteaseService.getCookie(testUserId);
      expect(cookie).toBeNull();
    });
  });

  describe('search', () => {
    it('should search songs successfully', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          code: 200,
          result: {
            songs: [
              {
                id: 1,
                name: 'Test Song',
                artists: [{ name: 'Artist' }],
                album: { name: 'Album' },
                duration: 180000,
              },
            ],
            songCount: 1,
          },
        }),
      });

      const result = await neteaseService.search('test');

      expect(result.keywords).toBe('test');
      expect(result.songs).toHaveLength(1);
      expect(result.songs[0].name).toBe('Test Song');
    });
  });

  describe('getSongDetail', () => {
    it('should get song detail', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          code: 200,
          songs: [
            {
              id: 1,
              name: 'Song',
              ar: [{ name: 'Artist' }],
              al: { name: 'Album', picUrl: 'http://cover' },
              dt: 180000,
            },
          ],
        }),
      });

      const result = await neteaseService.getSongDetail('1');

      expect(result.songs).toHaveLength(1);
      expect(result.songs[0].name).toBe('Song');
    });
  });

  describe('getSongUrl', () => {
    it('should get song url', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          code: 200,
          data: [
            {
              url: 'http://audio.mp3',
              size: 1024,
              type: 'mp3',
              br: 320,
            },
          ],
        }),
      });

      const result = await neteaseService.getSongUrl('1');

      expect(result.url).toBe('http://audio.mp3');
      expect(result.type).toBe('mp3');
    });

    it('should return null url when not available', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          code: 200,
          data: [{}],
        }),
      });

      const result = await neteaseService.getSongUrl('1');

      expect(result.url).toBeNull();
    });
  });

  describe('getLyric', () => {
    it('should get lyric', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          code: 200,
          lrc: { lyric: '[00:00]Test lyric' },
          tlyric: { lyric: '[00:00]Translated' },
        }),
      });

      const result = await neteaseService.getLyric('1');

      expect(result.lyric).toBe('[00:00]Test lyric');
      expect(result.tlyric).toBe('[00:00]Translated');
    });
  });
});
