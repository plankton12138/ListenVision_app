/**
 * 音频服务统一入口
 *
 * 将音频相关功能拆分为多个子模块：
 * - conversionService: 音频格式转换，支持并发控制
 * - metadataService: 元数据缓存管理，支持 Bilibili API
 * - searchHistoryService: 搜索历史管理
 *
 * 使用方式：
 *   const audioService = require('./services/audio');
 *   // 或按需导入
 *   const { conversionService } = require('./services/audio');
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
