const recommendationService = require('../services/recommendationService');
const { successResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');

/**
 * 推荐控制器
 * 处理推荐内容相关请求
 */

// ==================== 热门推荐 ====================

/**
 * 获取热门歌单
 */
const getHotPlaylists = catchAsync(async (req, res) => {
  const { page = 1, pageSize = 10 } = req.query;

  const result = await recommendationService.getHotPlaylists(
    parseInt(page),
    parseInt(pageSize)
  );

  return successResponse(res, result, '获取热门歌单成功');
});

/**
 * 获取热歌榜单
 */
const getHotRank = catchAsync(async (req, res) => {
  const { page = 1, pageSize = 10 } = req.query;

  const result = await recommendationService.getHotRank(
    parseInt(page),
    parseInt(pageSize)
  );

  return successResponse(res, result, '获取热歌榜单成功');
});

// ==================== 个性化推荐 ====================

/**
 * 获取个性化推荐
 */
const getPersonalized = catchAsync(async (req, res) => {
  const userId = req.user ? req.user.id : null;
  const { limit = 20 } = req.query;

  // 未登录用户返回热门推荐
  if (!userId) {
    const hotPlaylists = await recommendationService.getHotPlaylists(1, 3);
    return successResponse(res, {
      source: 'hot',
      playlists: hotPlaylists.playlists.slice(0, 2),
      videos: []
    }, '获取推荐成功');
  }

  const result = await recommendationService.getPersonalized(userId, parseInt(limit));

  return successResponse(res, result, '获取个性化推荐成功');
});

// ==================== 分区推荐 ====================

/**
 * 获取分区推荐
 */
const getByCategory = catchAsync(async (req, res) => {
  const userId = req.user ? req.user.id : null;
  const { tid } = req.params;
  const { page = 1, pageSize = 20 } = req.query;

  const result = await recommendationService.getByCategory(
    parseInt(tid),
    parseInt(page),
    parseInt(pageSize),
    userId
  );

  return successResponse(res, result, '获取分区推荐成功');
});

/**
 * 获取音乐区推荐（综合）
 */
const getMusicRecommendation = catchAsync(async (req, res) => {
  const userId = req.user ? req.user.id : null;
  const { limit = 20 } = req.query;

  const result = await recommendationService.getMusicRecommendation(parseInt(limit), userId);

  return successResponse(res, result, '获取音乐区推荐成功');
});

// ==================== 常量导出 ====================

/**
 * 获取可用的分区ID列表
 */
const getCategoryTids = catchAsync(async (req, res) => {
  return successResponse(res, recommendationService.CATEGORY_TIDS, '获取分区ID成功');
});

module.exports = {
  // 热门推荐
  getHotPlaylists,
  getHotRank,
  // 个性化推荐
  getPersonalized,
  // 分区推荐
  getByCategory,
  getMusicRecommendation,
  // 常量
  getCategoryTids
};
