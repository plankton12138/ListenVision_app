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

  // 删除历史
  deleteHistoryByUserId: db.prepare('DELETE FROM play_history WHERE user_id = ?'),
  deleteHistoryItemByIdentifier: db.prepare('DELETE FROM play_history WHERE id = ?'),
  deleteHistoryById: db.prepare('DELETE FROM play_history WHERE id = ?'),
  // 统计
  countByUserId: db.prepare('SELECT COUNT(*) as count FROM play_history WHERE user_id = ?'),
};

/**
 * 动态构建查找记录的 SQL
 * 处理 bvid 为 NULL 的情况（本地音频）
 */
const getHistoryByIdentifier = (userId, bvid, localPath) => {
  let sql = 'SELECT * FROM play_history WHERE user_id = ?';
  const params = [userId];

  if (bvid) {
    // 在线音频：使用 bvid
    sql += ' AND bvid = ?';
    params.push(bvid);
  } else {
    // 本地音频：bvid IS NULL 且 local_path 匹配
    sql += ' AND bvid IS NULL AND local_path = ?';
    params.push(localPath);
  }

  sql += ' ORDER BY played_at DESC LIMIT 1';

  return db.prepare(sql).get(...params);
};

/**
 * 动态构建删除记录的 SQL
 */
const deleteHistoryByIdentifier = (userId, bvid, localPath) => {
  let sql = 'DELETE FROM play_history WHERE user_id = ?';
  const params = [userId];

  if (bvid) {
    sql += ' AND bvid = ?';
    params.push(bvid);
  } else {
    sql += ' AND bvid IS NULL AND local_path = ?';
    params.push(localPath);
  }

  return db.prepare(sql).run(...params);
};

// 插入/更新播放记录（支持本地和在线）
const insertHistory = db.prepare(`
  INSERT INTO play_history (user_id, bvid, local_path, audio_type, title, artist, duration, cover_url, progress)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
`);

const updateHistoryProgress = db.prepare(`
  UPDATE play_history
  SET progress = ?, played_at = datetime('now')
  WHERE id = ?
`);

/**
 * 记录播放
 * Phase 2 遗留问题: 扩展支持本地音频和在线音频
 *
 * @param {number} userId - 用户ID（可选，游客传null）
 * @param {Object} options - 播放信息
 * @param {string} options.bvid - 在线音频BVID（可选）
 * @param {string} options.localPath - 本地音频路径（可选）
 * @param {string} options.title - 标题
 * @param {string} options.artist - 艺术家
 * @param {number} options.duration - 时长（秒）
 * @param {string} options.coverUrl - 封面URL
 * @param {number} options.progress - 播放进度（秒）
 * @returns {Object} 播放记录
 */
const recordPlay = (userId, options = {}) => {
  const {
    bvid = null,
    localPath = null,
    title = null,
    artist = null,
    duration = null,
    coverUrl = null,
    progress = 0
  } = options;

  // 确定音频类型和标识符
  const audioType = bvid ? 'online' : 'local';
  const identifier = bvid || localPath;

  if (!identifier) {
    throw new Error('Either bvid or localPath must be provided');
  }

  // 查找是否已有该音频的播放记录
  let existingRecord = null;
  if (userId) {
    existingRecord = getHistoryByIdentifier(userId, bvid, localPath);
  }

  if (existingRecord) {
    // 更新现有记录
    updateHistoryProgress.run(progress, existingRecord.id);
    // 返回格式化的数据（确保可以 JSON 序列化）
    return {
      id: existingRecord.id,
      user_id: existingRecord.user_id,
      bvid: existingRecord.bvid,
      local_path: existingRecord.local_path,
      audio_type: existingRecord.audio_type,
      title: existingRecord.title,
      artist: existingRecord.artist,
      duration: existingRecord.duration,
      cover_url: existingRecord.cover_url,
      progress: progress,
      played_at: new Date().toISOString()
    };
  } else {
    // 插入新记录
    const result = insertHistory.run(
      userId,
      bvid,
      localPath,
      audioType,
      title,
      artist,
      duration,
      coverUrl,
      progress
    );

    // 获取刚插入的记录并格式化
    const rawRecord = db.prepare('SELECT * FROM play_history WHERE id = ?').get(result.lastInsertRowid);
    return {
      id: rawRecord.id,
      user_id: rawRecord.user_id,
      bvid: rawRecord.bvid,
      local_path: rawRecord.local_path,
      audio_type: rawRecord.audio_type,
      title: rawRecord.title,
      artist: rawRecord.artist,
      duration: rawRecord.duration,
      cover_url: rawRecord.cover_url,
      progress: rawRecord.progress,
      played_at: rawRecord.played_at // SQLite 已返回 ISO 格式字符串
    };
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
 * @param {string} bvid - 视频BVID（在线音频）
 * @param {string} localPath - 本地路径（本地音频，可选）
 * @returns {boolean} 成功返回true
 */
const removeHistoryItem = (userId, bvid, localPath = null) => {
  if (bvid) {
    // 删除在线音频记录
    deleteHistoryByIdentifier(userId, bvid, null);
  } else if (localPath) {
    // 删除本地音频记录
    deleteHistoryByIdentifier(userId, null, localPath);
  }
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
