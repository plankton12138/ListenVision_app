const audioService = require('../services/audio');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { successResponse } = require('../utils/response');

/**
 * 音频元数据控制器
 */

const parseOptionalNumber = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
};

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
    maxAge ? parseOptionalNumber(maxAge, undefined) : undefined
  );

  return successResponse(res, metadata);
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

  return successResponse(res, result);
});

/**
 * 批量获取音频元数据
 */
const getMultipleMetadata = catchAsync(async (req, res) => {
  const { bvids } = req.body;

  if (!Array.isArray(bvids) || bvids.length === 0) {
    throw new AppError('bvids 参数必须是非空数组', 400);
  }

  const limitedBvids = bvids.slice(0, 50);
  const metadataMap = await audioService.getMultipleMetadata(limitedBvids);
  const metadataObj = {};

  for (const [bvid, data] of metadataMap.entries()) {
    metadataObj[bvid] = data;
  }

  return successResponse(res, { metadata: metadataObj });
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
  return successResponse(res, metadata, '刷新成功');
});

/**
 * 删除元数据缓存
 */
const deleteMetadata = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const deleted = audioService.deleteMetadata(bvid);
  if (!deleted) {
    throw new AppError('元数据不存在', 404);
  }

  return successResponse(res, { deleted: true }, '删除成功');
});

/**
 * 获取所有缓存元数据
 */
const getAllMetadata = catchAsync(async (req, res) => {
  const limit = parseOptionalNumber(req.query.limit, 50);
  const offset = parseOptionalNumber(req.query.offset, 0);
  const metadata = audioService.getAllMetadata(limit, offset);

  return successResponse(res, {
    metadata,
    limit,
    offset
  });
});

/**
 * 获取搜索历史
 */
const getSearchHistory = catchAsync(async (req, res) => {
  const limit = parseOptionalNumber(req.query.limit, 20);
  const offset = parseOptionalNumber(req.query.offset, 0);
  const history = audioService.getSearchHistory(req.user.id, limit, offset);

  return successResponse(res, {
    history,
    limit,
    offset
  });
});

/**
 * 获取最近搜索关键词
 */
const getRecentSearches = catchAsync(async (req, res) => {
  const limit = parseOptionalNumber(req.query.limit, 10);
  const keywords = audioService.getRecentSearches(req.user.id, limit);

  return successResponse(res, { keywords });
});

/**
 * 清空搜索历史
 */
const clearSearchHistory = catchAsync(async (req, res) => {
  audioService.clearSearchHistory(req.user.id);
  return successResponse(res, { cleared: true }, '搜索历史已清空');
});

/**
 * 删除特定搜索关键词
 */
const deleteSearchKeyword = catchAsync(async (req, res) => {
  const { keyword } = req.params;

  if (!keyword) {
    throw new AppError('缺少 keyword 参数', 400);
  }

  const deleted = audioService.deleteSearchKeyword(req.user.id, keyword);
  if (!deleted) {
    throw new AppError('搜索记录不存在', 404);
  }

  return successResponse(res, { deleted: true }, '删除成功');
});

/**
 * 获取缓存统计信息
 */
const getCacheStats = catchAsync(async (req, res) => {
  const stats = audioService.getCacheStats();
  return successResponse(res, stats);
});

/**
 * 清理过期缓存
 */
const cleanExpiredCache = catchAsync(async (req, res) => {
  const { maxAge } = req.query;
  const count = audioService.cleanExpiredCache(
    maxAge ? parseOptionalNumber(maxAge, undefined) : undefined
  );

  return successResponse(res, { cleaned: count }, `清理了 ${count} 条过期缓存`);
});

module.exports = {
  getAudioMetadata,
  getAudioStreamUrl,
  getMultipleMetadata,
  refreshMetadata,
  deleteMetadata,
  getAllMetadata,
  getSearchHistory,
  getRecentSearches,
  clearSearchHistory,
  deleteSearchKeyword,
  getCacheStats,
  cleanExpiredCache
};
