const db = require('../config/database');

// 预编译语句（模块初始化时编译，提高性能）
const stmt = {
  usernameById: db.prepare('SELECT username FROM users WHERE id = ?'),
  allFavorites: db.prepare('SELECT * FROM favorites'),
  favoritesByUsername: db.prepare('SELECT * FROM favorites WHERE username = (SELECT username FROM users WHERE id = ?)'),
  favoriteById: db.prepare('SELECT * FROM favorites WHERE id = ?'),
  favoriteByUrlAndUser: db.prepare('SELECT id FROM favorites WHERE url = ? AND username = ?'),
  favoriteIdExists: db.prepare('SELECT id FROM favorites WHERE id = ?'),
  insertFavorite: db.prepare('INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)'),
  updateFavorite: db.prepare('UPDATE favorites SET url = ?, title = ?, username = ? WHERE id = ?'),
  deleteFavorite: db.prepare('DELETE FROM favorites WHERE id = ?'),
};

// 获取收藏列表（已登录只返回自己的，未登录返回所有）
const getFavorites = (userId = null) => {
  return userId ? stmt.favoritesByUsername.all(userId) : stmt.allFavorites.all();
};

// 根据 ID 获取单个收藏
const getFavoriteById = (favoriteId) => {
  const favorite = stmt.favoriteById.get(favoriteId);
  if (!favorite) {
    throw new Error('收藏不存在');
  }
  return favorite;
};

// 添加收藏
const addFavorite = (userId, url, title) => {
  // 获取用户名
  const user = stmt.usernameById.get(userId);
  if (!user) {
    throw new Error('用户不存在');
  }

  const username = user.username;

  // 检查是否已收藏
  const existing = stmt.favoriteByUrlAndUser.get(url, username);
  if (existing) {
    throw new Error('该内容已被收藏');
  }

  // 插入新收藏
  const result = stmt.insertFavorite.run(url, title, username);
  return stmt.favoriteById.get(result.lastInsertRowid);
};

// 更新收藏
const updateFavorite = (favoriteId, updateData) => {
  const existing = stmt.favoriteIdExists.get(favoriteId);
  if (!existing) {
    throw new Error('收藏不存在');
  }

  const { url, title, username } = updateData;
  stmt.updateFavorite.run(url, title, username, favoriteId);

  return stmt.favoriteById.get(favoriteId);
};

// 删除收藏
const deleteFavorite = (favoriteId) => {
  const existing = stmt.favoriteIdExists.get(favoriteId);
  if (!existing) {
    throw new Error('收藏不存在');
  }

  stmt.deleteFavorite.run(favoriteId);
  return { success: true, message: '收藏已删除' };
};

module.exports = {
  getFavorites,
  getFavoriteById,
  addFavorite,
  updateFavorite,
  deleteFavorite
};
