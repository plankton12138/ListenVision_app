const db = require('../../config/database');

// 预编译语句
const stmt = {
  insertSearchHistory: db.prepare(`
    INSERT INTO search_history (user_id, keyword, result_count) VALUES (?, ?, ?)
  `),
  getSearchHistory: db.prepare(`
    SELECT * FROM search_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?
  `),
  getRecentSearches: db.prepare(`
    SELECT DISTINCT keyword FROM search_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ?
  `),
  clearSearchHistory: db.prepare('DELETE FROM search_history WHERE user_id = ?'),
  deleteSearchKeyword: db.prepare('DELETE FROM search_history WHERE user_id = ? AND keyword = ?'),
};

/**
 * 保存搜索历史
 */
const saveSearchHistory = (userId, keyword, resultCount = 0) => {
  if (!keyword || keyword.trim() === '') return;
  stmt.insertSearchHistory.run(userId, keyword.trim(), resultCount);
};

/**
 * 获取搜索历史
 */
const getSearchHistory = (userId, limit = 20, offset = 0) => {
  return stmt.getSearchHistory.all(userId, limit, offset);
};

/**
 * 获取最近的搜索关键词（去重）
 */
const getRecentSearches = (userId, limit = 10) => {
  return stmt.getRecentSearches.all(userId, limit).map(row => row.keyword);
};

/**
 * 清空搜索历史
 */
const clearSearchHistory = (userId) => {
  const info = stmt.clearSearchHistory.run(userId);
  return info.changes > 0;
};

/**
 * 删除特定搜索关键词
 */
const deleteSearchKeyword = (userId, keyword) => {
  const info = stmt.deleteSearchKeyword.run(userId, keyword);
  return info.changes > 0;
};

module.exports = {
  saveSearchHistory,
  getSearchHistory,
  getRecentSearches,
  clearSearchHistory,
  deleteSearchKeyword
};
