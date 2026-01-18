const db = require('../config/database');

// 预编译语句
const stmt = {
  // 获取播放历史
  historyByUserId: db.prepare(`
    SELECT * FROM play_history
    WHERE user_id = ?
    ORDER BY played_at DESC
    LIMIT ? OFFSET ?
  `),
  historyByUserIdNoLimit: db.prepare(`
    SELECT * FROM play_history
    WHERE user_id = ?
    ORDER BY played_at DESC
  `),
  historyByBvid: db.prepare(`
    SELECT * FROM play_history
    WHERE user_id = ? AND bvid = ?
    ORDER BY played_at DESC
    LIMIT 1
  `),
  // 插入/更新播放记录
  insertHistory: db.prepare(`
    INSERT INTO play_history (user_id, bvid, title, artist, duration, cover_url, progress)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `),
  updateHistoryProgress: db.prepare(`
    UPDATE play_history
    SET progress = ?, played_at = datetime('now')
    WHERE id = ?
  `),
  // 删除历史
  deleteHistoryByUserId: db.prepare('DELETE FROM play_history WHERE user_id = ?'),
  deleteHistoryItem: db.prepare('DELETE FROM play_history WHERE user_id = ? AND bvid = ?'),
  deleteHistoryById: db.prepare('DELETE FROM play_history WHERE id = ?'),
  // 统计
  countByUserId: db.prepare('SELECT COUNT(*) as count FROM play_history WHERE user_id = ?'),
};

/**
 * 记录播放
 * 如果该bvid的历史记录已存在，更新播放时间和进度；否则插入新记录
 * @param {number} userId - 用户ID（可选，游客传null）
 * @param {string} bvid - 视频BVID
 * @param {Object} metadata - 音频元数据
 * @param {number} progress - 播放进度（秒）
 * @returns {Object} 播放记录
 */
const recordPlay = (userId, bvid, metadata = {}, progress = 0) => {
  const { title, artist, duration, coverUrl } = metadata;

  // 查找是否已有该音频的播放记录
  const existingRecord = userId
    ? stmt.historyByBvid.get(userId, bvid)
    : null;

  if (existingRecord) {
    // 更新现有记录
    stmt.updateHistoryProgress.run(progress, existingRecord.id);
    return { ...existingRecord, progress, played_at: new Date().toISOString() };
  } else {
    // 插入新记录
    const result = stmt.insertHistory.run(
      userId, bvid, title || null, artist || null,
      duration || null, coverUrl || null, progress
    );

    // 获取刚插入的记录
    const newRecord = db.prepare('SELECT * FROM play_history WHERE id = ?').get(result.lastInsertRowid);
    return newRecord;
  }
};

/**
 * 获取播放历史
 * @param {number} userId - 用户ID
 * @param {number} limit - 返回数量限制
 * @param {number} offset - 偏移量
 * @returns {Array} 播放历史列表
 */
const getHistory = (userId, limit = 50, offset = 0) => {
  return stmt.historyByUserId.all(userId, limit, offset);
};

/**
 * 获取所有播放历史（不分页）
 * @param {number} userId - 用户ID
 * @returns {Array} 播放历史列表
 */
const getAllHistory = (userId) => {
  return stmt.historyByUserIdNoLimit.all(userId);
};

/**
 * 清空播放历史
 * @param {number} userId - 用户ID
 * @returns {boolean} 成功返回true
 */
const clearHistory = (userId) => {
  stmt.deleteHistoryByUserId.run(userId);
  return true;
};

/**
 * 删除指定播放记录
 * @param {number} userId - 用户ID
 * @param {string} bvid - 视频BVID
 * @returns {boolean} 成功返回true
 */
const removeHistoryItem = (userId, bvid) => {
  stmt.deleteHistoryItem.run(userId, bvid);
  return true;
};

/**
 * 按ID删除播放记录
 * @param {number} id - 记录ID
 * @returns {boolean} 成功返回true
 */
const removeHistoryById = (id) => {
  stmt.deleteHistoryById.run(id);
  return true;
};

/**
 * 获取播放历史统计
 * @param {number} userId - 用户ID
 * @returns {Object} 统计信息
 */
const getHistoryStats = (userId) => {
  const { count } = stmt.countByUserId.get(userId);

  // 获取最近播放
  const recent = stmt.historyByUserId.all(userId, 1, 0);

  return {
    totalPlays: count,
    lastPlayed: recent.length > 0 ? recent[0] : null
  };
};

module.exports = {
  recordPlay,
  getHistory,
  getAllHistory,
  clearHistory,
  removeHistoryItem,
  removeHistoryById,
  getHistoryStats
};
