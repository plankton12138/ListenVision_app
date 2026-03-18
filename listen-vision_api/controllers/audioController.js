const audioService = require('../services/audio');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 音频元数据控制器
 */

/**
 * 获取音频元数据
 */
const getAudioMetadata = catchAsync(async (req, res) => {
  const { bvid } = req.params;
  const { maxAge } = req.query;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const metadata = await audioService.getAudioMetadata(
    bvid,
    maxAge ? parseInt(maxAge) : undefined
  );

  successResponse(res, metadata);
});

/**
 * 获取音频流URL
 */
const getAudioStreamUrl = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const result = await audioService.getAudioStreamUrl(
    bvid,
    req.user?.id || null
  );

  successResponse(res, result);
});

/**
 * 批量获取音频元数据
 */
const getMultipleMetadata = catchAsync(async (req, res) => {
  const { bvids } = req.body;

  if (!Array.isArray(bvids) || bvids.length === 0) {
    throw new AppError('bvids 参数必须是非空数组', 400);
  }

  // 限制一次最多获取50个
  const limitedBvids = bvids.slice(0, 50);

  const metadataMap = await audioService.getMultipleMetadata(limitedBvids);

  // 改为对象格式，key 为 bvid
  const metadataObj = {};
  for (const [bvid, data] of metadataMap.entries()) {
    metadataObj[bvid] = data;
  }

  successResponse(res, { metadata: metadataObj });
});

/**
 * 刷新元数据缓存
 */
const refreshMetadata = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const metadata = await audioService.refreshMetadata(bvid);

  successResponse(res, metadata, '刷新成功');
});

/**
 * 删除元数据缓存
 */
const deleteMetadata = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const success = audioService.deleteMetadata(bvid);

  if (!success) {
    throw new AppError('元数据不存在', 404);
  }

  successResponse(res, { deleted: true }, '删除成功');
});

/**
 * 获取所有缓存元数据
 */
const getAllMetadata = catchAsync(async (req, res) => {
  const { limit = 50, offset = 0 } = req.query;

  const metadata = audioService.getAllMetadata(
    parseInt(limit) || 50,
    parseInt(offset) || 0
  );

  successResponse(res, {
    metadata,
    limit: parseInt(limit) || 50,
    offset: parseInt(offset) || 0
  });
});

/**
 * 获取搜索历史
 */
const getSearchHistory = catchAsync(async (req, res) => {
  const { limit = 20, offset = 0 } = req.query;

  const history = audioService.getSearchHistory(
    req.user.id,
    parseInt(limit) || 20,
    parseInt(offset) || 0
  );

  successResponse(res, {
    history,
    limit: parseInt(limit) || 20,
    offset: parseInt(offset) || 0
  });
});

/**
 * 获取最近搜索关键词
 */
const getRecentSearches = catchAsync(async (req, res) => {
  const { limit = 10 } = req.query;

  const keywords = audioService.getRecentSearches(
    req.user.id,
    parseInt(limit) || 10
  );

  successResponse(res, {
    keywords
  });
});

/**
 * 清空搜索历史
 */
const clearSearchHistory = catchAsync(async (req, res) => {
  audioService.clearSearchHistory(req.user.id);

  successResponse(res, { cleared: true }, '搜索历史已清空');
});

/**
 * 删除特定搜索关键词
 */
const deleteSearchKeyword = catchAsync(async (req, res) => {
  const { keyword } = req.params;

  if (!keyword) {
    throw new AppError('缺少 keyword 参数', 400);
  }

  const success = audioService.deleteSearchKeyword(req.user.id, keyword);

  if (!success) {
    throw new AppError('搜索记录不存在', 404);
  }

  successResponse(res, { deleted: true }, '删除成功');
});

/**
 * 获取缓存统计信息
 */
const getCacheStats = catchAsync(async (req, res) => {
  const stats = audioService.getCacheStats();

  successResponse(res, stats);
});

/**
 * 清理过期缓存
 */
const cleanExpiredCache = catchAsync(async (req, res) => {
  const { maxAge } = req.query;

  const count = audioService.cleanExpiredCache(
    maxAge ? parseInt(maxAge) : undefined
  );

  successResponse(res, { cleaned: count }, `清理了 ${count} 条过期缓存`);
});

module.exports = {
  // 元数据
  getAudioMetadata,
  getAudioStreamUrl,
  getMultipleMetadata,
  refreshMetadata,
  deleteMetadata,
  getAllMetadata,

  // 搜索历史
  getSearchHistory,
  getRecentSearches,
  clearSearchHistory,
  deleteSearchKeyword,

  // 统计
  getCacheStats,
  cleanExpiredCache
};
