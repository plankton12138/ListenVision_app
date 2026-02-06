/**
 * 音频服务统一入口
 *
 * 将音频相关功能拆分为多个子模块：
 * - conversionService: 音频格式转换
 * - metadataService: 元数据缓存管理
 * - searchHistoryService: 搜索历史
 *
 * 保持向后兼容，原有导入方式仍然有效
 */

const conversionService = require('./conversionService');
const metadataService = require('./metadataService');
const searchHistoryService = require('./searchHistoryService');

module.exports = {
  // FFmpeg 配置
  setFFmpegPath: conversionService.setFFmpegPath,
  getFFmpegVersion: conversionService.getFFmpegVersion,

  // 音频转换
  convertStream: conversionService.convertStream,
  convertFile: conversionService.convertFile,
  convertWithMetadata: conversionService.convertWithMetadata,
  proxyAndConvert: conversionService.proxyAndConvert,

  // 元数据管理
  getAudioMetadata: metadataService.getAudioMetadata,
  getMultipleMetadata: metadataService.getMultipleMetadata,
  getAudioStreamUrl: metadataService.getAudioStreamUrl,
  refreshMetadata: metadataService.refreshMetadata,
  deleteMetadata: metadataService.deleteMetadata,
  getAllMetadata: metadataService.getAllMetadata,
  getCacheStats: metadataService.getCacheStats,
  cleanExpiredCache: metadataService.cleanExpiredCache,

  // 搜索历史
  saveSearchHistory: searchHistoryService.saveSearchHistory,
  getSearchHistory: searchHistoryService.getSearchHistory,
  getRecentSearches: searchHistoryService.getRecentSearches,
  clearSearchHistory: searchHistoryService.clearSearchHistory,
  deleteSearchKeyword: searchHistoryService.deleteSearchKeyword,

  // 子模块（供内部使用）
  conversionService,
  metadataService,
  searchHistoryService
};
