const favoriteService = require('../services/favoriteService');
const { logBehavior, extractBvid } = require('../services/recommendationService');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 收藏控制器
 * 处理收藏相关请求
 */

/**
 * 获取收藏列表
 */
const getFavorites = catchAsync(async (req, res) => {
  // req.user 可能不存在（使用 optionalAuthMiddleware 时）
  const userId = req.user ? req.user.id : null;

  const favorites = await favoriteService.getFavorites(userId);

  return successResponse(res, favorites, '获取收藏列表成功');
});

/**
 * 根据 ID 获取单个收藏
 */
const getFavoriteById = catchAsync(async (req, res) => {
  const { id } = req.params;

  const favorite = await favoriteService.getFavoriteById(id);

  return successResponse(res, favorite, '获取收藏成功');
});

/**
 * 添加收藏
 */
const addFavorite = catchAsync(async (req, res) => {
  const { url, title } = req.body;

  if (!url || !title) {
    throw new AppError('URL 和标题不能为空', 400);
  }

  // req.user 来自 authMiddleware
  const favorite = await favoriteService.addFavorite(req.user.id, url, title);

  // Phase 3.2: 记录喜欢行为
  const bvid = extractBvid(url);
  logBehavior(req.user.id, bvid, 'like');

  return successResponse(res, favorite, '添加收藏成功', 201);
});

/**
 * 更新收藏
 */
const updateFavorite = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { url, title, username } = req.body;

  if (!url || !title) {
    throw new AppError('URL 和标题不能为空', 400);
  }

  const updateData = { url, title, username };
  const favorite = await favoriteService.updateFavorite(id, updateData);

  return successResponse(res, favorite, '更新收藏成功');
});

/**
 * 删除收藏
 */
const deleteFavorite = catchAsync(async (req, res) => {
  const { id } = req.params;

  await favoriteService.deleteFavorite(id);

  return successResponse(res, { success: true }, '删除收藏成功');
});

module.exports = {
  getFavorites,
  getFavoriteById,
  addFavorite,
  updateFavorite,
  deleteFavorite
};
