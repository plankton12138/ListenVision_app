const pool = require('../config/database');

/**
 * 收藏服务
 * 处理收藏相关的业务逻辑
 */

/**
 * 获取收藏列表
 */
const getFavorites = async (userId = null) => {
  let results;

  if (userId) {
    // 已登录，只返回当前用户的收藏
    [results] = await pool.execute(
      'SELECT * FROM favorites WHERE username = (SELECT username FROM users WHERE id = ?)',
      [userId]
    );
  } else {
    // 未登录，返回所有收藏（或可改为返回空）
    [results] = await pool.execute('SELECT * FROM favorites');
  }

  return results;
};

/**
 * 根据 ID 获取单个收藏
 */
const getFavoriteById = async (favoriteId) => {
  const [favorites] = await pool.execute(
    'SELECT * FROM favorites WHERE id = ?',
    [favoriteId]
  );

  if (favorites.length === 0) {
    throw new Error('收藏不存在');
  }

  return favorites[0];
};

/**
 * 添加收藏
 */
const addFavorite = async (userId, url, title) => {
  // 获取用户名
  const [users] = await pool.execute(
    'SELECT username FROM users WHERE id = ?',
    [userId]
  );

  if (users.length === 0) {
    throw new Error('用户不存在');
  }

  const username = users[0].username;

  // 检查是否已收藏
  const [existing] = await pool.execute(
    'SELECT id FROM favorites WHERE url = ? AND username = ?',
    [url, username]
  );

  if (existing.length > 0) {
    throw new Error('该内容已被收藏');
  }

  // 插入新收藏
  const [result] = await pool.execute(
    'INSERT INTO favorites (url, title, username) VALUES (?, ?, ?)',
    [url, title, username]
  );

  // 获取新创建的收藏
  const [newFavorite] = await pool.execute(
    'SELECT * FROM favorites WHERE id = ?',
    [result.insertId]
  );

  return newFavorite[0];
};

/**
 * 更新收藏
 */
const updateFavorite = async (favoriteId, updateData) => {
  const { url, title, username } = updateData;

  // 检查收藏是否存在
  const [existing] = await pool.execute(
    'SELECT id FROM favorites WHERE id = ?',
    [favoriteId]
  );

  if (existing.length === 0) {
    throw new Error('收藏不存在');
  }

  // 更新收藏
  await pool.execute(
    'UPDATE favorites SET url = ?, title = ?, username = ? WHERE id = ?',
    [url, title, username, favoriteId]
  );

  // 获取更新后的收藏
  const [updatedFavorite] = await pool.execute(
    'SELECT * FROM favorites WHERE id = ?',
    [favoriteId]
  );

  return updatedFavorite[0];
};

/**
 * 删除收藏
 */
const deleteFavorite = async (favoriteId) => {
  // 检查收藏是否存在
  const [existing] = await pool.execute(
    'SELECT id FROM favorites WHERE id = ?',
    [favoriteId]
  );

  if (existing.length === 0) {
    throw new Error('收藏不存在');
  }

  // 删除收藏
  await pool.execute(
    'DELETE FROM favorites WHERE id = ?',
    [favoriteId]
  );

  return { success: true, message: '收藏已删除' };
};

module.exports = {
  getFavorites,
  getFavoriteById,
  addFavorite,
  updateFavorite,
  deleteFavorite
};
