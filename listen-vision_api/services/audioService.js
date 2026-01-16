const db = require('../config/database');
const bilibiliService = require('./bilibiliService');

/**
 * 音频元数据管理服务
 *
 * 功能：
 * 1. 音频元数据缓存
 * 2. 搜索历史记录
 * 3. 获取/更新缓存
 */

// ==================== 预编译语句 ====================

const stmt = {
  // 元数据缓存
  getMetadata: db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?'),
  getMultipleMetadata: db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'),
  insertMetadata: db.prepare(`
    INSERT OR REPLACE INTO audio_metadata_cache
    (bvid, title, artist, duration, cover_url, audio_url, cid, metadata, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
  `),
  updateAudioUrl: db.prepare(`
    UPDATE audio_metadata_cache SET audio_url = ?, updated_at = datetime('now') WHERE bvid = ?
  `),
  deleteMetadata: db.prepare('DELETE FROM audio_metadata_cache WHERE bvid = ?'),
  getAllMetadata: db.prepare('SELECT * FROM audio_metadata_cache ORDER BY created_at DESC LIMIT ? OFFSET ?'),

  // 搜索历史
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

  // 统计
  getCacheStats: db.prepare(`
    SELECT COUNT(*) as total, MAX(updated_at) as last_update FROM audio_metadata_cache
  `),
};

// ==================== 元数据缓存 ====================

/**
 * 获取音频元数据（优先从缓存）
 *
 * @param {string} bvid - 视频BVID
 * @param {number} maxAge - 缓存最大年龄（毫秒），默认7天
 * @returns {Object|null} 元数据
 */
const getAudioMetadata = async (bvid, maxAge = 7 * 24 * 60 * 60 * 1000) => {
  // 先从缓存获取
  const cached = stmt.getMetadata.get(bvid);

  if (cached) {
    const updatedAt = new Date(cached.updated_at);
    const age = Date.now() - updatedAt.getTime();

    // 缓存未过期
    if (age < maxAge) {
      return parseCachedMetadata(cached);
    }
  }

  // 缓存过期或不存在，从B站获取
  return await fetchAndCacheMetadata(bvid);
};

/**
 * 批量获取音频元数据
 *
 * @param {Array<string>} bvids - BVID列表
 * @returns {Map<string, Object>} BVID -> 元数据的映射
 */
const getMultipleMetadata = async (bvids) => {
  const result = new Map();
  const toFetch = [];

  // 分批查询（SQLite的IN限制）
  const batchSize = 10;
  for (let i = 0; i < bvids.length; i += batchSize) {
    const batch = bvids.slice(i, i + batchSize);
    const placeholders = batch.map(() => '?').join(',');
    const query = `SELECT * FROM audio_metadata_cache WHERE bvid IN (${placeholders})`;
    const cached = db.prepare(query).all(...batch);

    cached.forEach(row => {
      result.set(row.bvid, parseCachedMetadata(row));
    });
  }

  // 找出需要从B站获取的
  bvids.forEach(bvid => {
    if (!result.has(bvid)) {
      toFetch.push(bvid);
    }
  });

  // 并行获取缺失的元数据
  if (toFetch.length > 0) {
    await Promise.all(toFetch.map(async (bvid) => {
      try {
        const metadata = await fetchAndCacheMetadata(bvid);
        result.set(bvid, metadata);
      } catch (error) {
        // 记录错误但继续处理其他BVID
        console.error(`获取 ${bvid} 元数据失败:`, error.message);
      }
    }));
  }

  return result;
};

/**
 * 从B站获取并缓存元数据
 *
 * @param {string} bvid - 视频BVID
 * @returns {Object} 元数据
 */
const fetchAndCacheMetadata = async (bvid) => {
  // 获取视频信息
  const videoInfo = await bilibiliService.getVideoInfo(bvid);

  // 构建元数据
  const metadata = {
    bvid: videoInfo.bvid,
    title: videoInfo.title,
    artist: videoInfo.owner.name,
    duration: videoInfo.duration,
    cover: videoInfo.cover,
    cid: videoInfo.cid,
    desc: videoInfo.desc,
    owner: videoInfo.owner
  };

  // 保存到缓存
  stmt.insertMetadata.run(
    metadata.bvid,
    metadata.title,
    metadata.artist,
    metadata.duration,
    metadata.cover,
    null, // audio_url 需要额外获取
    metadata.cid,
    JSON.stringify(metadata)
  );

  return metadata;
};

/**
 * 获取音频流URL（优先从缓存）
 *
 * @param {string} bvid - 视频BVID
 * @param {number} userId - 用户ID
 * @returns {Object} { url, duration, ... }
 */
const getAudioStreamUrl = async (bvid, userId = null) => {
  // 先获取元数据
  const metadata = await getAudioMetadata(bvid);

  // 检查是否有缓存的音频URL
  const cached = stmt.getMetadata.get(bvid);

  // 音频URL通常有效期较短（几小时），需要实时获取
  // 这里直接调用B站API获取最新URL
  const audioStream = await bilibiliService.getAudioStream(
    bvid,
    metadata.cid,
    userId
  );

  // 更新缓存的音频URL
  stmt.updateAudioUrl.run(audioStream.baseUrl, bvid);

  return {
    bvid: metadata.bvid,
    title: metadata.title,
    artist: metadata.artist,
    duration: metadata.duration,
    cover: metadata.cover,
    audioUrl: audioStream.baseUrl,
    mimeType: audioStream.mimeType,
    codecs: audioStream.codecs
  };
};

/**
 * 解析缓存的元数据
 */
const parseCachedMetadata = (row) => {
  const result = {
    bvid: row.bvid,
    title: row.title,
    artist: row.artist,
    duration: row.duration,
    cover: row.cover_url,
    audioUrl: row.audio_url,
    cid: row.cid,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };

  // 解析JSON元数据
  if (row.metadata) {
    try {
      const extra = JSON.parse(row.metadata);
      result.desc = extra.desc;
      result.owner = extra.owner;
      result.pages = extra.pages;
    } catch (e) {
      // 忽略解析错误
    }
  }

  return result;
};

/**
 * 刷新元数据缓存
 *
 * @param {string} bvid - 视频BVID
 * @returns {Object} 刷新后的元数据
 */
const refreshMetadata = async (bvid) => {
  // 强制从B站获取
  const metadata = await fetchAndCacheMetadata(bvid);
  return metadata;
};

/**
 * 删除元数据缓存
 *
 * @param {string} bvid - 视频BVID
 * @returns {boolean} 是否成功
 */
const deleteMetadata = (bvid) => {
  const info = stmt.deleteMetadata.run(bvid);
  return info.changes > 0;
};

/**
 * 获取所有缓存的元数据
 *
 * @param {number} limit - 限制数量
 * @param {number} offset - 偏移量
 * @returns {Array} 元数据列表
 */
const getAllMetadata = (limit = 50, offset = 0) => {
  const rows = stmt.getAllMetadata.all(limit, offset);
  return rows.map(parseCachedMetadata);
};

// ==================== 搜索历史 ====================

/**
 * 保存搜索历史
 *
 * @param {number} userId - 用户ID
 * @param {string} keyword - 搜索关键词
 * @param {number} resultCount - 结果数量
 */
const saveSearchHistory = (userId, keyword, resultCount = 0) => {
  stmt.insertSearchHistory.run(userId, keyword, resultCount);
};

/**
 * 获取搜索历史
 *
 * @param {number} userId - 用户ID
 * @param {number} limit - 限制数量
 * @param {number} offset - 偏移量
 * @returns {Array} 搜索历史
 */
const getSearchHistory = (userId, limit = 20, offset = 0) => {
  return stmt.getSearchHistory.all(userId, limit, offset);
};

/**
 * 获取最近的搜索关键词（去重）
 *
 * @param {number} userId - 用户ID
 * @param {number} limit - 限制数量
 * @returns {Array<string>} 关键词列表
 */
const getRecentSearches = (userId, limit = 10) => {
  return stmt.getRecentSearches.all(userId, limit).map(row => row.keyword);
};

/**
 * 清空搜索历史
 *
 * @param {number} userId - 用户ID
 * @returns {boolean} 是否成功
 */
const clearSearchHistory = (userId) => {
  const info = stmt.clearSearchHistory.run(userId);
  return info.changes > 0;
};

/**
 * 删除特定搜索关键词
 *
 * @param {number} userId - 用户ID
 * @param {string} keyword - 关键词
 * @returns {boolean} 是否成功
 */
const deleteSearchKeyword = (userId, keyword) => {
  const info = stmt.deleteSearchKeyword.run(userId, keyword);
  return info.changes > 0;
};

// ==================== 统计 ====================

/**
 * 获取缓存统计信息
 *
 * @returns {Object} 统计信息
 */
const getCacheStats = () => {
  const stats = stmt.getCacheStats.get();
  return {
    totalCached: stats.total || 0,
    lastUpdate: stats.last_update || null
  };
};

/**
 * 清理过期缓存
 *
 * @param {number} maxAge - 最大年龄（毫秒）
 * @returns {number} 清理数量
 */
const cleanExpiredCache = (maxAge = 30 * 24 * 60 * 60 * 1000) => {
  // 30天前的缓存
  const expireTime = new Date(Date.now() - maxAge).toISOString();
  const info = db.prepare('DELETE FROM audio_metadata_cache WHERE updated_at < ?').run(expireTime);
  return info.changes;
};

module.exports = {
  // 元数据缓存
  getAudioMetadata,
  getMultipleMetadata,
  getAudioStreamUrl,
  refreshMetadata,
  deleteMetadata,
  getAllMetadata,

  // 搜索历史
  saveSearchHistory,
  getSearchHistory,
  getRecentSearches,
  clearSearchHistory,
  deleteSearchKeyword,

  // 统计
  getCacheStats,
  cleanExpiredCache
};
