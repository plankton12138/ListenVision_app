/**
 * 推荐内容相关路由
 *
 * Phase 2 - 推荐页面 API 端点
 */

const express = require('express');
const router = express.Router();
const recommendationService = require('../services/recommendationService');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { successResponse } = require('../utils/response');
const { catchAsync, AppError } = require('../middleware/errorHandler');

// ==================== 热门推荐 ====================

/**
 * GET /api/recommendations/hot-playlists
 *
 * 获取热门歌单
 *
 * Authentication: 可选
 */
const getHotPlaylists = catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 10;

  const result = await recommendationService.getHotPlaylists(page, pageSize);

  return successResponse(res, result, '获取热门歌单成功');
});

/**
 * GET /api/recommendations/rank
 *
 * 获取热歌榜单
 *
 * Authentication: 可选
 */
const getHotRank = catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 10;

  const result = await recommendationService.getHotRank(page, pageSize);

  return successResponse(res, result, '获取热歌榜单成功');
});

// ==================== 个性化推荐 ====================

/**
 * GET /api/recommendations/personalized
 *
 * 获取推荐内容
 *
 * 直接使用热门歌单API（无需WBI签名，稳定可靠）
 *
 * 返回格式：{ source: string, playlists: array }
 */
const getPersonalized = catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 10;

  // 使用热门歌单API获取推荐内容
  const hotPlaylists = await recommendationService.getHotPlaylists(page, pageSize);

  const result = {
    playlists: hotPlaylists.playlists || [],
    source: 'hot'
  };

  return successResponse(res, result, '获取推荐成功');
});

// ==================== 分区推荐 ====================

/**
 * GET /api/recommendations/category/:tid
 *
 * 获取分区推荐
 *
 * Authentication: 可选
 */
const getByCategory = catchAsync(async (req, res) => {
  const tid = parseInt(req.params.tid);
  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 20;

  if (isNaN(tid)) {
    throw new AppError('无效的分区ID', 400);
  }

  const result = await recommendationService.getByCategory(tid, page, pageSize);

  return successResponse(res, result, '获取分区推荐成功');
});

/**
 * GET /api/recommendations/music
 *
 * 获取音乐区推荐（综合）
 *
 * Authentication: 可选
 */
const getMusicRecommendation = catchAsync(async (req, res) => {
  const limit = parseInt(req.query.limit) || 20;

  const result = await recommendationService.getMusicRecommendation(limit);

  return successResponse(res, result, '获取音乐推荐成功');
});

// ==================== 常量 ====================

/**
 * GET /api/recommendations/categories
 *
 * 获取可用的分区ID列表
 */
const getCategoryTids = catchAsync(async (req, res) => {
  return successResponse(res, recommendationService.CATEGORY_TIDS, '获取分区列表成功');
});

// ==================== 注册路由 ====================

router.get('/hot-playlists', optionalAuthMiddleware, getHotPlaylists);
router.get('/rank', optionalAuthMiddleware, getHotRank);
router.get('/personalized', optionalAuthMiddleware, getPersonalized);
router.get('/category/:tid', optionalAuthMiddleware, getByCategory);
router.get('/music', optionalAuthMiddleware, getMusicRecommendation);
router.get('/categories', getCategoryTids);

module.exports = router;
