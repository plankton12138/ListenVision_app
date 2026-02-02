/**
 * 搜索服务
 *
 * Phase 3.1 - SQLite FTS5 全文搜索实现
 *
 * 功能:
 * 1. 本地音频元数据全文搜索（FTS5）
 * 2. 搜索建议（自动完成）
 * 3. 热门搜索关键词
 * 4. 搜索统计
 */

const { logger } = require('../utils/logger');
const db = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

// 预编译语句（模块初始化时编译，提高性能）
const stmt = {
  // FTS5 全文搜索
  searchFTS: db.prepare(`
    SELECT
      amc.bvid,
      amc.title,
      amc.artist,
      amc.duration,
      amc.cover_url
    FROM audio_metadata_cache_fts AS fts
    JOIN audio_metadata_cache AS amc ON fts.rowid = amc.id
    WHERE audio_metadata_cache_fts MATCH ?
    ORDER BY rank
    LIMIT ?
  `),

  // 搜索建议（基于搜索历史）
  searchSuggestions: db.prepare(`
    SELECT DISTINCT keyword, search_count
    FROM search_stats
    WHERE keyword LIKE ?
    ORDER BY search_count DESC, last_searched DESC
    LIMIT 10
  `),

  // 热门搜索关键词
  trendingKeywords: db.prepare(`
    SELECT keyword, search_count
    FROM search_stats
    WHERE last_searched > datetime('now', '-7 days')
    ORDER BY search_count DESC
    LIMIT 10
  `),

  // 记录搜索统计
  recordSearch: db.prepare(`
    INSERT INTO search_stats (keyword, search_count, last_searched)
    VALUES (?, COALESCE((SELECT search_count + 1 FROM search_stats WHERE keyword = ?), 1), datetime('now'))
    ON CONFLICT(keyword) DO UPDATE SET
      search_count = search_count + 1,
      last_searched = datetime('now')
  `),

  // 获取搜索历史
  getSearchHistory: db.prepare(`
    SELECT keyword, result_count, created_at
    FROM search_history
    WHERE user_id IS NULL OR user_id = ?
    ORDER BY created_at DESC
    LIMIT 20
  `),
};

/**
 * 全文搜索本地音频元数据
 *
 * 使用 SQLite FTS5 虚拟表进行高性能全文搜索
 *
 * @param {string} keyword - 搜索关键词
 * @param {number} limit - 返回结果数量限制
 * @returns {Array} 搜索结果列表
 */
const searchAudioMetadata = (keyword, limit = 20) => {
  try {
    // 使用 FTS5 MATCH 语法进行全文搜索
    // 支持 AND、OR、NOT 操作符
    const results = stmt.searchFTS.all(keyword, limit);

    // 统计搜索次数（用于热门关键词）
    stmt.recordSearch.run(keyword, keyword);

    return results;
  } catch (error) {
    logger.error('全文搜索失败: %s', error.message);
    throw new AppError(`搜索失败: ${error.message}`, 500);
  }
};

/**
 * 获取搜索建议（自动完成）
 *
 * @param {string} prefix - 搜索前缀
 * @returns {Array} 建议关键词列表
 */
const getSearchSuggestions = (prefix) => {
  try {
    if (!prefix || prefix.trim() === '') {
      return [];
    }
    const suggestions = stmt.searchSuggestions.all(`${prefix}%`);
    return suggestions.map(s => s.keyword);
  } catch (error) {
    logger.error('获取搜索建议失败: %s', error.message);
    throw new AppError(`获取搜索建议失败: ${error.message}`, 500);
  }
};

/**
 * 获取热门搜索关键词
 *
 * 返回过去7天内搜索次数最多的关键词
 *
 * @returns {Array} 热门关键词列表
 */
const getTrendingKeywords = () => {
  try {
    const trending = stmt.trendingKeywords.all();
    return trending.map(t => ({
      keyword: t.keyword,
      searchCount: t.search_count
    }));
  } catch (error) {
    logger.error('获取热门关键词失败: %s', error.message);
    throw new AppError(`获取热门关键词失败: ${error.message}`, 500);
  }
};

/**
 * 获取用户搜索历史
 *
 * @param {number|null} userId - 用户ID（NULL 表示游客）
 * @returns {Array} 搜索历史列表
 */
const getSearchHistory = (userId = null) => {
  try {
    const history = stmt.getSearchHistory.all(userId);
    return history;
  } catch (error) {
    logger.error('获取搜索历史失败: %s', error.message);
    throw new AppError(`获取搜索历史失败: ${error.message}`, 500);
  }
};

// 导入搜索历史服务
const { saveSearchHistory: _saveSearchHistory, deleteSearchKeyword: _deleteSearchKeyword } = require('./audio/searchHistoryService');

/**
 * 保存用户搜索历史
 * 直接委托给 searchHistoryService 实现
 */
const saveSearchHistory = (userId, keyword, resultCount = 0) => {
  return _saveSearchHistory(userId, keyword, resultCount);
};

/**
 * 删除用户搜索关键词
 * 直接委托给 searchHistoryService 实现
 */
const deleteSearchKeyword = (userId, keyword) => {
  return _deleteSearchKeyword(userId, keyword);
};

/**
 * 清空用户搜索历史
 * 直接委托给 audioService 实现
 */
const clearSearchHistory = (userId) => {
  return audioService.clearSearchHistory(userId);
};

module.exports = {
  searchAudioMetadata,
  getSearchSuggestions,
  getTrendingKeywords,
  getSearchHistory,
  saveSearchHistory,
  deleteSearchKeyword,
  clearSearchHistory,
};
