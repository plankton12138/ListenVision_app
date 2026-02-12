// Mock 数据库模块 - 必须在 require playlistService 之前定义
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
    CREATE TABLE playlists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      cover_url TEXT,
      type TEXT DEFAULT 'user',
      system_type TEXT,
      is_public INTEGER DEFAULT 0,
      play_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  db.exec(`
    CREATE TABLE playlist_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playlist_id INTEGER NOT NULL,
      bvid TEXT NOT NULL,
      title TEXT,
      artist TEXT,
      duration INTEGER,
      cover_url TEXT,
      local_path TEXT,
      position INTEGER NOT NULL DEFAULT 0,
      added_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
      UNIQUE(playlist_id, bvid)
    )
  `);

  return db;
});

const playlistService = require('../../services/playlistService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('歌单服务测试', () => {
  let testUserId;

  // 在每个测试前清空表并创建测试用户
  beforeEach(() => {
    db.exec('DELETE FROM users');
    db.exec('DELETE FROM playlists');
    db.exec('DELETE FROM playlist_items');

    // 创建测试用户
    const bcrypt = require('bcryptjs');
    const hashedPassword = bcrypt.hashSync('password123', 10);
    const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'test@example.com', hashedPassword);
    testUserId = info.lastInsertRowid;
  });

  describe('ensureSystemPlaylists()', () => {
    test('应为用户创建 favorites 和 now_playing 系统歌单', () => {
      playlistService.ensureSystemPlaylists(testUserId);

      const playlists = db.prepare('SELECT * FROM playlists WHERE user_id = ?').all(testUserId);

      expect(playlists).toHaveLength(2);
      expect(playlists.some(p => p.system_type === 'favorites' && p.name === '我喜欢')).toBe(true);
      expect(playlists.some(p => p.system_type === 'now_playing' && p.name === '正在播放')).toBe(true);
    });

    test('重复调用不应创建重复的系统歌单', () => {
      playlistService.ensureSystemPlaylists(testUserId);
      playlistService.ensureSystemPlaylists(testUserId);

      const playlists = db.prepare('SELECT * FROM playlists WHERE user_id = ? AND system_type IS NOT NULL').all(testUserId);

      expect(playlists).toHaveLength(2);
    });

    test('系统歌单应标记为 type = system', () => {
      playlistService.ensureSystemPlaylists(testUserId);

      const systemPlaylists = db.prepare('SELECT * FROM playlists WHERE user_id = ? AND type = ?').all(testUserId, 'system');

      expect(systemPlaylists).toHaveLength(2);
    });
  });

  describe('getUserPlaylists()', () => {
    test('应返回用户所有歌单（包含自动创建的系统歌单）', () => {
      // 手动创建一个用户歌单
      db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '我的测试歌单', 'user');

      const playlists = playlistService.getUserPlaylists(testUserId);

      expect(playlists).toHaveLength(3); // 2个系统歌单 + 1个用户歌单
      expect(playlists.some(p => p.name === '我喜欢')).toBe(true);
      expect(playlists.some(p => p.name === '正在播放')).toBe(true);
      expect(playlists.some(p => p.name === '我的测试歌单')).toBe(true);
    });

    test('应包含 item_count 字段', () => {
      const playlists = playlistService.getUserPlaylists(testUserId);

      expect(playlists[0]).toHaveProperty('item_count');
      expect(typeof playlists[0].item_count).toBe('number');
    });
  });

  describe('getPlaylistDetail()', () => {
    test('应返回歌单详情及其items', () => {
      const playlistInfo = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user');
      const playlistId = playlistInfo.lastInsertRowid;

      // 添加歌单项
      db.prepare(`
        INSERT INTO playlist_items (playlist_id, bvid, title, artist, position)
        VALUES (?, ?, ?, ?, ?)
      `).run(playlistId, 'BV1xx411c7mD', '测试音频', '测试歌手', 0);

      const detail = playlistService.getPlaylistDetail(playlistId, testUserId);

      expect(detail.id).toBe(playlistId);
      expect(detail.name).toBe('测试歌单');
      expect(detail.items).toHaveLength(1);
      expect(detail.items[0].bvid).toBe('BV1xx411c7mD');
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.getPlaylistDetail(99999, testUserId);
      }).toThrow('歌单不存在');
    });

    test('无权访问私有歌单应抛出 403 错误', () => {
      // 创建另一个用户
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('otheruser', 'other@example.com', 'hash').lastInsertRowid;

      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type, is_public) VALUES (?, ?, ?, ?)')
        .run(otherUserId, '私有歌单', 'user', 0).lastInsertRowid;

      expect(() => {
        playlistService.getPlaylistDetail(playlistId, testUserId);
      }).toThrow('无权访问此歌单');
    });

    test('应支持自定义排序', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      // 添加多个歌单项
      db.prepare(`INSERT INTO playlist_items (playlist_id, bvid, title, artist, position) VALUES (?, ?, ?, ?, ?)`)
        .run(playlistId, 'BV1xx', '标题C', '歌手C', 2);
      db.prepare(`INSERT INTO playlist_items (playlist_id, bvid, title, artist, position) VALUES (?, ?, ?, ?, ?)`)
        .run(playlistId, 'BV1yy', '标题A', '歌手A', 0);
      db.prepare(`INSERT INTO playlist_items (playlist_id, bvid, title, artist, position) VALUES (?, ?, ?, ?, ?)`)
        .run(playlistId, 'BV1zz', '标题B', '歌手B', 1);

      const detail = playlistService.getPlaylistDetail(playlistId, testUserId, 'title_asc');

      expect(detail.items[0].title).toBe('标题A');
      expect(detail.items[1].title).toBe('标题B');
      expect(detail.items[2].title).toBe('标题C');
    });
  });

  describe('createPlaylist()', () => {
    test('应成功创建歌单', () => {
      const playlist = playlistService.createPlaylist(
        testUserId,
        '新歌单',
        '这是描述',
        'https://example.com/cover.jpg'
      );

      expect(playlist).toHaveProperty('id');
      expect(playlist.name).toBe('新歌单');
      expect(playlist.description).toBe('这是描述');
      expect(playlist.cover_url).toBe('https://example.com/cover.jpg');
      expect(playlist.type).toBe('user');
    });

    test('空名称应抛出 400 错误', () => {
      expect(() => {
        playlistService.createPlaylist(testUserId, '');
      }).toThrow('歌单名称不能为空');
    });

    test('仅空格名称应抛出 400 错误', () => {
      expect(() => {
        playlistService.createPlaylist(testUserId, '   ');
      }).toThrow('歌单名称不能为空');
    });

    test('应自动trim歌单名称', () => {
      const playlist = playlistService.createPlaylist(testUserId, '  新歌单  ');

      expect(playlist.name).toBe('新歌单');
    });

    test('可选参数应正确处理', () => {
      const playlist = playlistService.createPlaylist(testUserId, '极简歌单');

      expect(playlist.name).toBe('极简歌单');
      expect(playlist.description).toBeNull();
      expect(playlist.cover_url).toBeNull();
    });
  });

  describe('updatePlaylist()', () => {
    test('应成功更新歌单信息', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '旧名称', 'user').lastInsertRowid;

      const updated = playlistService.updatePlaylist(playlistId, testUserId, {
        name: '新名称',
        description: '新描述',
        coverUrl: 'https://example.com/new.jpg'
      });

      expect(updated.name).toBe('新名称');
      expect(updated.description).toBe('新描述');
      expect(updated.cover_url).toBe('https://example.com/new.jpg');
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.updatePlaylist(99999, testUserId, { name: '新名称' });
      }).toThrow('歌单不存在');
    });

    test('无权修改他人歌单应抛出 403 错误', () => {
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('other', 'other@example.com', 'hash').lastInsertRowid;
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(otherUserId, '其他用户歌单', 'user').lastInsertRowid;

      expect(() => {
        playlistService.updatePlaylist(playlistId, testUserId, { name: '新名称' });
      }).toThrow('无权修改此歌单');
    });

    test('系统歌单不能修改', () => {
      playlistService.ensureSystemPlaylists(testUserId);
      const favorites = db.prepare('SELECT * FROM playlists WHERE user_id = ? AND system_type = ?')
        .get(testUserId, 'favorites');

      expect(() => {
        playlistService.updatePlaylist(favorites.id, testUserId, { name: '新名称' });
      }).toThrow('系统歌单不能修改');
    });

    test('部分更新应保留原有值', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, description, type) VALUES (?, ?, ?, ?)')
        .run(testUserId, '原名', '原描述', 'user').lastInsertRowid;

      const updated = playlistService.updatePlaylist(playlistId, testUserId, {
        name: '新名'
      });

      expect(updated.name).toBe('新名');
      expect(updated.description).toBe('原描述');
    });

    test('应支持 is_public 切换', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type, is_public) VALUES (?, ?, ?, ?)')
        .run(testUserId, '测试歌单', 'user', 0).lastInsertRowid;

      const updated = playlistService.updatePlaylist(playlistId, testUserId, {
        isPublic: true
      });

      expect(updated.is_public).toBe(1);
    });
  });

  describe('deletePlaylist()', () => {
    test('应成功删除歌单', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '待删除歌单', 'user').lastInsertRowid;

      const result = playlistService.deletePlaylist(playlistId, testUserId);

      expect(result).toBe(true);

      const playlist = db.prepare('SELECT * FROM playlists WHERE id = ?').get(playlistId);
      expect(playlist).toBeUndefined();
    });

    test('删除歌单应级联删除其items', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '待删除歌单', 'user').lastInsertRowid;
      db.prepare('INSERT INTO playlist_items (playlist_id, bvid, title, position) VALUES (?, ?, ?, ?)')
        .run(playlistId, 'BV1xx', '测试', 0);

      playlistService.deletePlaylist(playlistId, testUserId);

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ?').all(playlistId);
      expect(items).toHaveLength(0);
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.deletePlaylist(99999, testUserId);
      }).toThrow('歌单不存在');
    });

    test('无权删除他人歌单应抛出 403 错误', () => {
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('other', 'other@example.com', 'hash').lastInsertRowid;
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(otherUserId, '其他用户歌单', 'user').lastInsertRowid;

      expect(() => {
        playlistService.deletePlaylist(playlistId, testUserId);
      }).toThrow('无权删除此歌单');
    });

    test('系统歌单不能删除', () => {
      playlistService.ensureSystemPlaylists(testUserId);
      const favorites = db.prepare('SELECT * FROM playlists WHERE user_id = ? AND system_type = ?')
        .get(testUserId, 'favorites');

      expect(() => {
        playlistService.deletePlaylist(favorites.id, testUserId);
      }).toThrow('系统歌单不能删除');
    });
  });

  describe('addItem()', () => {
    test('应成功添加音频到歌单', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      const item = playlistService.addItem(playlistId, {
        bvid: 'BV1xx411c7mD',
        title: '测试音频',
        artist: '测试歌手',
        duration: 180,
        coverUrl: 'https://example.com/cover.jpg'
      });

      expect(item).toHaveProperty('id');
      expect(item.bvid).toBe('BV1xx411c7mD');
      expect(item.title).toBe('测试音频');
      expect(item.artist).toBe('测试歌手');
      expect(item.duration).toBe(180);
      expect(item.cover_url).toBe('https://example.com/cover.jpg');
      expect(item.position).toBe(0);
    });

    test('重复添加应抛出 409 错误', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1xx411c7mD', title: '第一次' });

      expect(() => {
        playlistService.addItem(playlistId, { bvid: 'BV1xx411c7mD', title: '第二次' });
      }).toThrow('该音频已在歌单中');
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.addItem(99999, { bvid: 'BV1xx411c7mD' });
      }).toThrow('歌单不存在');
    });

    test('应自动递增 position', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1aa', title: '第一首' });
      playlistService.addItem(playlistId, { bvid: 'BV1bb', title: '第二首' });
      playlistService.addItem(playlistId, { bvid: 'BV1cc', title: '第三首' });

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);

      expect(items[0].position).toBe(0);
      expect(items[1].position).toBe(1);
      expect(items[2].position).toBe(2);
    });

    test('可选参数应正确处理为 null', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      const item = playlistService.addItem(playlistId, { bvid: 'BV1xx' });

      expect(item.title).toBeNull();
      expect(item.artist).toBeNull();
      expect(item.duration).toBeNull();
      expect(item.cover_url).toBeNull();
    });
  });

  describe('removeItem()', () => {
    test('应成功移除歌单项并重新排序剩余项', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1aa', title: '第一首' });
      playlistService.addItem(playlistId, { bvid: 'BV1bb', title: '第二首' });
      playlistService.addItem(playlistId, { bvid: 'BV1cc', title: '第三首' });

      const result = playlistService.removeItem(playlistId, 'BV1bb');

      expect(result).toBe(true);

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);

      expect(items).toHaveLength(2);
      expect(items[0].bvid).toBe('BV1aa');
      expect(items[0].position).toBe(0);
      expect(items[1].bvid).toBe('BV1cc');
      expect(items[1].position).toBe(1);
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.removeItem(99999, 'BV1xx');
      }).toThrow('歌单不存在');
    });

    test('移除不存在的项不应报错', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      const result = playlistService.removeItem(playlistId, 'BV1xx');

      expect(result).toBe(true);
    });

    test('移除第一项后应正确重排序', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1aa', title: 'A' });
      playlistService.addItem(playlistId, { bvid: 'BV1bb', title: 'B' });
      playlistService.addItem(playlistId, { bvid: 'BV1cc', title: 'C' });

      playlistService.removeItem(playlistId, 'BV1aa');

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);

      expect(items[0].position).toBe(0);
      expect(items[1].position).toBe(1);
    });

    test('移除最后一项后应正确重排序', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1aa', title: 'A' });
      playlistService.addItem(playlistId, { bvid: 'BV1bb', title: 'B' });
      playlistService.addItem(playlistId, { bvid: 'BV1cc', title: 'C' });

      playlistService.removeItem(playlistId, 'BV1cc');

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);

      expect(items).toHaveLength(2);
      expect(items[0].position).toBe(0);
      expect(items[1].position).toBe(1);
    });
  });

  describe('reorderItems()', () => {
    test('应成功调整歌单项顺序', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      const item1 = playlistService.addItem(playlistId, { bvid: 'BV1aa', title: 'A' });
      const item2 = playlistService.addItem(playlistId, { bvid: 'BV1bb', title: 'B' });
      const item3 = playlistService.addItem(playlistId, { bvid: 'BV1cc', title: 'C' });

      const result = playlistService.reorderItems(playlistId, [
        { id: item3.id, position: 0 },
        { id: item1.id, position: 1 },
        { id: item2.id, position: 2 }
      ]);

      expect(result).toBe(true);

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);

      expect(items[0].bvid).toBe('BV1cc');
      expect(items[1].bvid).toBe('BV1aa');
      expect(items[2].bvid).toBe('BV1bb');
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.reorderItems(99999, [{ id: 1, position: 0 }]);
      }).toThrow('歌单不存在');
    });
  });

  describe('toggleFavorite()', () => {
    test('应成功添加收藏', () => {
      const result = playlistService.toggleFavorite(testUserId, {
        bvid: 'BV1xx411c7mD',
        title: '收藏的音频',
        artist: '歌手'
      });

      expect(result.added).toBe(true);
      expect(result.favorited).toBe(true);

      const favorited = playlistService.isFavorited(testUserId, 'BV1xx411c7mD');
      expect(favorited).toBe(true);
    });

    test('应成功取消收藏', () => {
      // 先收藏
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1xx411c7mD', title: '测试' });

      // 再取消
      const result = playlistService.toggleFavorite(testUserId, { bvid: 'BV1xx411c7mD' });

      expect(result.added).toBe(false);
      expect(result.favorited).toBe(false);

      const favorited = playlistService.isFavorited(testUserId, 'BV1xx411c7mD');
      expect(favorited).toBe(false);
    });

    test('应自动创建 favorites 系统歌单', () => {
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1xx', title: '测试' });

      const favorites = db.prepare('SELECT * FROM playlists WHERE user_id = ? AND system_type = ?')
        .get(testUserId, 'favorites');

      expect(favorites).toBeDefined();
      expect(favorites.name).toBe('我喜欢');
    });
  });

  describe('isFavorited()', () => {
    test('未收藏应返回 false', () => {
      const favorited = playlistService.isFavorited(testUserId, 'BV1xx');
      expect(favorited).toBe(false);
    });

    test('已收藏应返回 true', () => {
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1xx', title: '测试' });

      const favorited = playlistService.isFavorited(testUserId, 'BV1xx');
      expect(favorited).toBe(true);
    });

    test('取消收藏后应返回 false', () => {
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1xx', title: '测试' });
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1xx' });

      const favorited = playlistService.isFavorited(testUserId, 'BV1xx');
      expect(favorited).toBe(false);
    });
  });

  describe('getFavorites()', () => {
    test('应返回收藏列表', () => {
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1aa', title: '收藏A', artist: '歌手A' });
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1bb', title: '收藏B', artist: '歌手B' });
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1cc', title: '收藏C', artist: '歌手C' });

      const favorites = playlistService.getFavorites(testUserId);

      expect(favorites).toHaveLength(3);
      expect(favorites.some(f => f.bvid === 'BV1aa' && f.title === '收藏A')).toBe(true);
      expect(favorites.some(f => f.bvid === 'BV1bb' && f.title === '收藏B')).toBe(true);
      expect(favorites.some(f => f.bvid === 'BV1cc' && f.title === '收藏C')).toBe(true);
    });

    test('空收藏应返回空数组', () => {
      const favorites = playlistService.getFavorites(testUserId);
      expect(favorites).toEqual([]);
    });

    test('取消收藏后应从列表中移除', () => {
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1aa', title: 'A' });
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1bb', title: 'B' });
      playlistService.toggleFavorite(testUserId, { bvid: 'BV1aa' }); // 取消第一个

      const favorites = playlistService.getFavorites(testUserId);

      expect(favorites).toHaveLength(1);
      expect(favorites[0].bvid).toBe('BV1bb');
    });
  });

  describe('saveNowPlaying() / getNowPlaying()', () => {
    test('应成功保存和获取播放队列', () => {
      const queue = [
        { bvid: 'BV1aa', title: '第一首', artist: '歌手A', duration: 180, coverUrl: 'https://example.com/a.jpg' },
        { bvid: 'BV1bb', title: '第二首', artist: '歌手B', duration: 200, coverUrl: 'https://example.com/b.jpg' },
        { bvid: 'BV1cc', title: '第三首', artist: '歌手C', duration: 220, coverUrl: 'https://example.com/c.jpg' }
      ];

      playlistService.saveNowPlaying(testUserId, queue);
      const saved = playlistService.getNowPlaying(testUserId);

      expect(saved).toHaveLength(3);
      expect(saved[0].bvid).toBe('BV1aa');
      expect(saved[0].title).toBe('第一首');
      expect(saved[0].position).toBe(0);
      expect(saved[1].bvid).toBe('BV1bb');
      expect(saved[1].position).toBe(1);
      expect(saved[2].bvid).toBe('BV1cc');
      expect(saved[2].position).toBe(2);
    });

    test('保存新队列应清空旧队列', () => {
      // 保存第一组
      playlistService.saveNowPlaying(testUserId, [
        { bvid: 'BV1old', title: '旧队列' }
      ]);

      // 保存第二组
      playlistService.saveNowPlaying(testUserId, [
        { bvid: 'BV1new', title: '新队列' }
      ]);

      const saved = playlistService.getNowPlaying(testUserId);

      expect(saved).toHaveLength(1);
      expect(saved[0].bvid).toBe('BV1new');
    });

    test('保存空队列应清空播放列表', () => {
      playlistService.saveNowPlaying(testUserId, [
        { bvid: 'BV1aa', title: '测试' }
      ]);

      playlistService.saveNowPlaying(testUserId, []);

      const saved = playlistService.getNowPlaying(testUserId);

      expect(saved).toEqual([]);
    });

    test('空队列应返回空数组', () => {
      const saved = playlistService.getNowPlaying(testUserId);
      expect(saved).toEqual([]);
    });

    test('应自动创建 now_playing 系统歌单', () => {
      playlistService.saveNowPlaying(testUserId, [{ bvid: 'BV1xx', title: '测试' }]);

      const nowPlaying = db.prepare('SELECT * FROM playlists WHERE user_id = ? AND system_type = ?')
        .get(testUserId, 'now_playing');

      expect(nowPlaying).toBeDefined();
      expect(nowPlaying.name).toBe('正在播放');
    });

    test('应正确处理可选元数据字段', () => {
      const queue = [
        { bvid: 'BV1minimal' } // 仅提供必需字段
      ];

      playlistService.saveNowPlaying(testUserId, queue);
      const saved = playlistService.getNowPlaying(testUserId);

      expect(saved).toHaveLength(1);
      expect(saved[0].bvid).toBe('BV1minimal');
      expect(saved[0].title).toBeNull();
      expect(saved[0].artist).toBeNull();
      expect(saved[0].duration).toBeNull();
      expect(saved[0].cover_url).toBeNull();
    });
  });

  describe('sortItems()', () => {
    test('应成功按标题重新排序', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1cc', title: 'C标题' });
      playlistService.addItem(playlistId, { bvid: 'BV1aa', title: 'A标题' });
      playlistService.addItem(playlistId, { bvid: 'BV1bb', title: 'B标题' });

      playlistService.sortItems(playlistId, 'title_asc', testUserId);

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);

      expect(items[0].title).toBe('A标题');
      expect(items[1].title).toBe('B标题');
      expect(items[2].title).toBe('C标题');
    });

    test('应支持多种排序方式', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(testUserId, '测试歌单', 'user').lastInsertRowid;

      playlistService.addItem(playlistId, { bvid: 'BV1xx', title: 'X', artist: 'Z歌手' });
      playlistService.addItem(playlistId, { bvid: 'BV1yy', title: 'Y', artist: 'A歌手' });
      playlistService.addItem(playlistId, { bvid: 'BV1zz', title: 'Z', artist: 'M歌手' });

      // 按歌手升序
      playlistService.sortItems(playlistId, 'artist_asc', testUserId);
      let items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);
      expect(items[0].artist).toBe('A歌手');
      expect(items[1].artist).toBe('M歌手');
      expect(items[2].artist).toBe('Z歌手');

      // 按标题降序
      playlistService.sortItems(playlistId, 'title_desc', testUserId);
      items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ? ORDER BY position')
        .all(playlistId);
      expect(items[0].title).toBe('Z');
      expect(items[1].title).toBe('Y');
      expect(items[2].title).toBe('X');
    });

    test('歌单不存在应抛出 404 错误', () => {
      expect(() => {
        playlistService.sortItems(99999, 'title_asc', testUserId);
      }).toThrow('歌单不存在');
    });

    test('无权修改他人歌单应抛出 403 错误', () => {
      const otherUserId = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('other', 'other@example.com', 'hash').lastInsertRowid;
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type) VALUES (?, ?, ?)')
        .run(otherUserId, '其他用户歌单', 'user').lastInsertRowid;

      expect(() => {
        playlistService.sortItems(playlistId, 'title_asc', testUserId);
      }).toThrow('无权修改此歌单');
    });
  });

  describe('incrementPlayCount()', () => {
    test('应成功增加播放次数', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type, play_count) VALUES (?, ?, ?, ?)')
        .run(testUserId, '测试歌单', 'user', 5).lastInsertRowid;

      playlistService.incrementPlayCount(playlistId);

      const playlist = db.prepare('SELECT * FROM playlists WHERE id = ?').get(playlistId);
      expect(playlist.play_count).toBe(6);
    });

    test('多次调用应累加播放次数', () => {
      const playlistId = db.prepare('INSERT INTO playlists (user_id, name, type, play_count) VALUES (?, ?, ?, ?)')
        .run(testUserId, '测试歌单', 'user', 0).lastInsertRowid;

      playlistService.incrementPlayCount(playlistId);
      playlistService.incrementPlayCount(playlistId);
      playlistService.incrementPlayCount(playlistId);

      const playlist = db.prepare('SELECT * FROM playlists WHERE id = ?').get(playlistId);
      expect(playlist.play_count).toBe(3);
    });

    test('对不存在的歌单调用不应报错', () => {
      expect(() => {
        playlistService.incrementPlayCount(99999);
      }).not.toThrow();
    });
  });

  describe('SYSTEM_TYPES 常量', () => {
    test('应导出正确的系统类型常量', () => {
      expect(playlistService.SYSTEM_TYPES).toBeDefined();
      expect(playlistService.SYSTEM_TYPES.FAVORITES).toBe('favorites');
      expect(playlistService.SYSTEM_TYPES.NOW_PLAYING).toBe('now_playing');
    });
  });
});
