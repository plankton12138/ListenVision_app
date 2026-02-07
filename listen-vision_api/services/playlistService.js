const db = require('../config/database');
const { AppError } = require('../middleware/errorHandler');
const { logger } = require('../utils/logger');

// 系统歌单类型常量
const SYSTEM_TYPES = {
  FAVORITES: 'favorites',
  NOW_PLAYING: 'now_playing'
};

// 有效的排序类型
const VALID_SORT_TYPES = [
  'added_at_desc', 'added_at_asc',
  'title_asc', 'title_desc',
  'artist_asc', 'artist_desc',
  'position_asc'
];

// 预编译语句
const stmt = {
  // 歌单查询
  playlistsByUserId: db.prepare(`
    SELECT id, user_id, name, description, cover_url, type, system_type,
           is_public, play_count, created_at, updated_at,
           (SELECT COUNT(*) FROM playlist_items WHERE playlist_id = playlists.id) as item_count
    FROM playlists
    WHERE user_id = ?
    ORDER BY type DESC, system_type NULLS LAST, created_at DESC
  `),
  playlistById: db.prepare('SELECT * FROM playlists WHERE id = ?'),
  playlistBySystemType: db.prepare('SELECT * FROM playlists WHERE user_id = ? AND system_type = ?'),
  // 歌单 CRUD
  insertPlaylist: db.prepare(`
    INSERT INTO playlists (user_id, name, description, cover_url, type, system_type, is_public)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `),
  updatePlaylist: db.prepare(`
    UPDATE playlists
    SET name = ?, description = ?, cover_url = ?, is_public = ?, updated_at = datetime('now')
    WHERE id = ?
  `),
  updatePlayCount: db.prepare('UPDATE playlists SET play_count = play_count + 1 WHERE id = ?'),
  deletePlaylist: db.prepare('DELETE FROM playlists WHERE id = ?'),
  // 歌单项查询
  itemsByPlaylistId: db.prepare(`
    SELECT * FROM playlist_items
    WHERE playlist_id = ?
    ORDER BY position ASC
  `),
  itemExists: db.prepare('SELECT 1 FROM playlist_items WHERE playlist_id = ? AND bvid = ?'),
  itemCount: db.prepare('SELECT COUNT(*) as count FROM playlist_items WHERE playlist_id = ?'),
  maxPosition: db.prepare('SELECT COALESCE(MAX(position), -1) as max_pos FROM playlist_items WHERE playlist_id = ?'),
  // 歌单项 CRUD
  insertItem: db.prepare(`
    INSERT INTO playlist_items (playlist_id, bvid, title, artist, duration, cover_url, position)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `),
  updateItemPosition: db.prepare(`
    UPDATE playlist_items SET position = ? WHERE id = ?
  `),
  deleteItem: db.prepare('DELETE FROM playlist_items WHERE playlist_id = ? AND bvid = ?'),
  clearPlaylist: db.prepare('DELETE FROM playlist_items WHERE playlist_id = ?'),
  // 批量位置更新（用于重排序）
  updateItemById: db.prepare('UPDATE playlist_items SET position = ? WHERE id = ?'),
  getItemById: db.prepare('SELECT * FROM playlist_items WHERE id = ?'),
};

/**
 * 确保用户拥有系统歌单
 * 为用户自动创建 "favorites" 和 "now_playing" 系统歌单
 * @param {number} userId - 用户ID
 */
const ensureSystemPlaylists = (userId) => {
  const systemPlaylists = [
    { systemType: SYSTEM_TYPES.FAVORITES, name: '我喜欢', description: '我收藏的音频内容' },
    { systemType: SYSTEM_TYPES.NOW_PLAYING, name: '正在播放', description: '当前播放队列' }
  ];

  for (const sp of systemPlaylists) {
    const existing = stmt.playlistBySystemType.get(userId, sp.systemType);
    if (!existing) {
      stmt.insertPlaylist.run(userId, sp.name, sp.description, null, 'system', sp.systemType, 0);
      logger.info(`创建系统歌单: ${sp.name}`, { userId, systemType: sp.systemType });
    }
  }
};

/**
 * 获取用户所有歌单
 * @param {number} userId - 用户ID
 * @returns {Array} 歌单列表
 */
const getUserPlaylists = (userId) => {
  ensureSystemPlaylists(userId);
  return stmt.playlistsByUserId.all(userId);
};

/**
 * 获取歌单详情（包含items）
 * @param {number} playlistId - 歌单ID
 * @param {number} userId - 用户ID（用于权限验证）
 * @param {string} sortType - 排序方式，默认按position ASC
 * @returns {Object} 歌单详情及items
 */
const getPlaylistDetail = (playlistId, userId, sortType = 'position_asc') => {
  // 确保用户系统歌单已创建（防止直接调用此接口时出现 404）
  ensureSystemPlaylists(userId);

  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }
  if (playlist.user_id !== userId && !playlist.is_public) {
    throw new AppError('无权访问此歌单', 403);
  }

  let items;
  if (sortType === 'position_asc') {
    items = stmt.itemsByPlaylistId.all(playlistId);
  } else {
    const orderBy = getOrderByClause(sortType);
    const dynamicStmt = db.prepare(`
      SELECT * FROM playlist_items
      WHERE playlist_id = ?
      ORDER BY ${orderBy}
    `);
    items = dynamicStmt.all(playlistId);
  }

  return {
    ...playlist,
    items,
    sortType
  };
};

/**
 * 创建歌单
 * @param {number} userId - 用户ID
 * @param {string} name - 歌单名称
 * @param {string} description - 歌单描述
 * @param {string} coverUrl - 封面URL
 * @returns {Object} 新创建的歌单
 */
const createPlaylist = (userId, name, description = null, coverUrl = null) => {
  // 验证歌单名称
  if (!name || name.trim() === '') {
    throw new AppError('歌单名称不能为空', 400);
  }

  const trimmedName = name.trim();
  if (trimmedName.length < 1 || trimmedName.length > 100) {
    throw new AppError('歌单名称长度必须在1-100个字符之间', 400);
  }

  const result = stmt.insertPlaylist.run(userId, trimmedName, description, coverUrl, 'user', null, 0);
  return stmt.playlistById.get(result.lastInsertRowid);
};

/**
 * 更新歌单信息
 * @param {number} playlistId - 歌单ID
 * @param {number} userId - 用户ID
 * @param {Object} updates - 更新内容
 * @returns {Object} 更新后的歌单
 */
const updatePlaylist = (playlistId, userId, updates) => {
  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }
  if (playlist.user_id !== userId) {
    throw new AppError('无权修改此歌单', 403);
  }
  if (playlist.type === 'system') {
    throw new AppError('系统歌单不能修改', 400);
  }

  const { name, description, coverUrl, isPublic } = updates;

  // 验证名称
  if (name !== undefined) {
    const trimmedName = name.trim();
    if (trimmedName.length < 1 || trimmedName.length > 100) {
      throw new AppError('歌单名称长度必须在1-100个字符之间', 400);
    }
  }

  stmt.updatePlaylist.run(
    name !== undefined ? name.trim() : playlist.name,
    description !== undefined ? description : playlist.description,
    coverUrl !== undefined ? coverUrl : playlist.cover_url,
    isPublic !== undefined ? (isPublic ? 1 : 0) : playlist.is_public,
    playlistId
  );

  return stmt.playlistById.get(playlistId);
};

/**
 * 删除歌单
 * @param {number} playlistId - 歌单ID
 * @param {number} userId - 用户ID
 * @returns {boolean} 成功返回true
 */
const deletePlaylist = (playlistId, userId) => {
  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }
  if (playlist.user_id !== userId) {
    throw new AppError('无权删除此歌单', 403);
  }
  if (playlist.type === 'system') {
    throw new AppError('系统歌单不能删除', 400);
  }

  stmt.deletePlaylist.run(playlistId);
  return true;
};

/**
 * 添加音频到歌单
 * @param {number} playlistId - 歌单ID
 * @param {Object} itemData - 音频数据 { bvid, title, artist, duration, coverUrl }
 * @returns {Object} 添加的歌单项
 */
const addItem = (playlistId, itemData) => {
  const { bvid, title, artist, duration, coverUrl } = itemData;

  // 验证必要参数
  if (!bvid || bvid.trim() === '') {
    throw new AppError('BVID不能为空', 400);
  }

  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }

  // 检查是否已存在
  const existing = stmt.itemExists.get(playlistId, bvid);
  if (existing) {
    throw new AppError('该音频已在歌单中', 409);
  }

  // 获取当前最大位置
  const { max_pos } = stmt.maxPosition.get(playlistId);
  const nextPosition = max_pos + 1;

  const result = stmt.insertItem.run(
    playlistId, bvid.trim(), title || null, artist || null,
    duration || null, coverUrl || null, nextPosition
  );

  return stmt.getItemById.get(result.lastInsertRowid);
};

/**
 * 从歌单移除音频
 * @param {number} playlistId - 歌单ID
 * @param {string} bvid - 视频BVID
 * @returns {boolean} 成功返回true
 */
const removeItem = (playlistId, bvid) => {
  if (!bvid || bvid.trim() === '') {
    throw new AppError('BVID不能为空', 400);
  }

  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }

  stmt.deleteItem.run(playlistId, bvid.trim());

  // 重新排序剩余项
  const items = stmt.itemsByPlaylistId.all(playlistId);
  const updateStmt = db.prepare('UPDATE playlist_items SET position = ? WHERE id = ?');
  const transaction = db.transaction((items) => {
    items.forEach((item, index) => {
      updateStmt.run(index, item.id);
    });
  });
  transaction(items);

  return true;
};

/**
 * 调整歌单项顺序
 * @param {number} playlistId - 歌单ID
 * @param {Array} items - 项数组
 * @returns {boolean} 成功返回true
 */
const reorderItems = (playlistId, items) => {
  // 验证参数
  if (!Array.isArray(items)) {
    throw new AppError('items必须是数组', 400);
  }

  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }

  const transaction = db.transaction((itemList) => {
    itemList.forEach(({ id, position }) => {
      if (id && typeof position === 'number') {
        stmt.updateItemById.run(position, id);
      }
    });
  });
  transaction(items);

  return true;
};

/**
 * 切换收藏状态（快捷方法）
 * @param {number} userId - 用户ID
 * @param {Object} itemData - 音频数据 { bvid, title, artist, duration, coverUrl }
 * @returns {Object} { added: boolean, favorited: boolean }
 */
const toggleFavorite = (userId, itemData) => {
  const { bvid, title, artist, duration, coverUrl } = itemData;

  // 验证必要参数
  if (!bvid || bvid.trim() === '') {
    throw new AppError('BVID不能为空', 400);
  }

  ensureSystemPlaylists(userId);
  const favoritesPlaylist = stmt.playlistBySystemType.get(userId, SYSTEM_TYPES.FAVORITES);

  const existing = stmt.itemExists.get(favoritesPlaylist.id, bvid);
  if (existing) {
    // 已收藏，移除
    removeItem(favoritesPlaylist.id, bvid);
    return { added: false, favorited: false };
  } else {
    // 未收藏，添加
    addItem(favoritesPlaylist.id, { bvid, title, artist, duration, coverUrl });
    return { added: true, favorited: true };
  }
};

/**
 * 检查是否已收藏
 * @param {number} userId - 用户ID
 * @param {string} bvid - 视频BVID
 * @returns {boolean} 是否已收藏
 */
const isFavorited = (userId, bvid) => {
  if (!bvid || bvid.trim() === '') {
    throw new AppError('BVID不能为空', 400);
  }

  ensureSystemPlaylists(userId);
  const favoritesPlaylist = stmt.playlistBySystemType.get(userId, SYSTEM_TYPES.FAVORITES);
  const existing = stmt.itemExists.get(favoritesPlaylist.id, bvid);
  return !!existing;
};

/**
 * 获取收藏列表
 * @param {number} userId - 用户ID
 * @returns {Array} 收藏列表
 */
const getFavorites = (userId) => {
  ensureSystemPlaylists(userId);
  const favoritesPlaylist = stmt.playlistBySystemType.get(userId, SYSTEM_TYPES.FAVORITES);
  return stmt.itemsByPlaylistId.all(favoritesPlaylist.id);
};

/**
 * 保存当前播放队列
 * @param {number} userId - 用户ID
 * @param {Array} items - 播放队列项
 * @returns {boolean} 成功返回true
 */
const saveNowPlaying = (userId, items) => {
  // 验证参数
  if (!Array.isArray(items)) {
    throw new AppError('items必须是数组', 400);
  }

  ensureSystemPlaylists(userId);
  const nowPlayingPlaylist = stmt.playlistBySystemType.get(userId, SYSTEM_TYPES.NOW_PLAYING);

  // 清空现有内容
  stmt.clearPlaylist.run(nowPlayingPlaylist.id);

  // 插入新内容
  if (items.length > 0) {
    const insertStmt = db.prepare(`
      INSERT INTO playlist_items (playlist_id, bvid, title, artist, duration, cover_url, position)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    const transaction = db.transaction((itemList) => {
      itemList.forEach((item, index) => {
        if (item && item.bvid) {
          insertStmt.run(
            nowPlayingPlaylist.id,
            item.bvid,
            item.title || null,
            item.artist || null,
            item.duration || null,
            item.coverUrl || null,
            index
          );
        }
      });
    });
    transaction(items);
  }

  return true;
};

/**
 * 获取当前播放队列
 * @param {number} userId - 用户ID
 * @returns {Array} 播放队列
 */
const getNowPlaying = (userId) => {
  ensureSystemPlaylists(userId);
  const nowPlayingPlaylist = stmt.playlistBySystemType.get(userId, SYSTEM_TYPES.NOW_PLAYING);
  return stmt.itemsByPlaylistId.all(nowPlayingPlaylist.id);
};

/**
 * 获取排序子句
 * @param {string} sortType - 排序类型
 * @returns {string} ORDER BY 子句
 */
const getOrderByClause = (sortType) => {
  switch (sortType) {
    case 'added_at_desc':
      return 'added_at DESC';
    case 'added_at_asc':
      return 'added_at ASC';
    case 'title_asc':
      return 'title ASC';
    case 'title_desc':
      return 'title DESC';
    case 'artist_asc':
      return 'artist ASC';
    case 'artist_desc':
      return 'artist DESC';
    case 'position_asc':
    default:
      return 'position ASC';
  }
};

/**
 * 重新排序歌单项（应用新的排序方式）
 * @param {number} playlistId - 歌单ID
 * @param {string} sortType - 排序类型
 * @param {number} userId - 用户ID（用于权限验证）
 */
const sortItems = (playlistId, sortType, userId) => {
  // 验证排序类型
  if (!sortType || !VALID_SORT_TYPES.includes(sortType)) {
    throw new AppError('无效的排序类型', 400);
  }

  const playlist = stmt.playlistById.get(playlistId);
  if (!playlist) {
    throw new AppError('歌单不存在', 404);
  }
  if (playlist.user_id !== userId) {
    throw new AppError('无权修改此歌单', 403);
  }

  // 获取当前项并按新排序方式重新排序
  const orderBy = getOrderByClause(sortType);
  const dynamicStmt = db.prepare(`
    SELECT id FROM playlist_items
    WHERE playlist_id = ?
    ORDER BY ${orderBy}
  `);
  const items = dynamicStmt.all(playlistId);

  // 更新position字段
  const updateStmt = db.prepare('UPDATE playlist_items SET position = ? WHERE id = ?');
  items.forEach((item, index) => {
    updateStmt.run(index, item.id);
  });
};

/**
 * 增加歌单播放次数
 * @param {number} playlistId - 歌单ID
 */
const incrementPlayCount = (playlistId) => {
  stmt.updatePlayCount.run(playlistId);
};

module.exports = {
  SYSTEM_TYPES,
  ensureSystemPlaylists,
  getUserPlaylists,
  getPlaylistDetail,
  createPlaylist,
  updatePlaylist,
  deletePlaylist,
  addItem,
  removeItem,
  reorderItems,
  sortItems,
  toggleFavorite,
  isFavorited,
  getFavorites,
  saveNowPlaying,
  getNowPlaying,
  incrementPlayCount
};
