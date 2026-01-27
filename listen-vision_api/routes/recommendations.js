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
 * @swagger
 * /api/recommendations/hot-playlists:
 *   get:
 *     tags: [推荐]
 *     summary: 获取热门歌单
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: 获取成功
 */
const getHotPlaylists = catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 10;

  const result = await recommendationService.getHotPlaylists(page, pageSize);

  return successResponse(res, result, '获取热门歌单成功');
});

/**
 * @swagger
 * /api/recommendations/rank:
 *   get:
 *     tags: [推荐]
 *     summary: 获取热歌榜单
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: 获取成功
 */
const getHotRank = catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 10;

  const result = await recommendationService.getHotRank(page, pageSize);

  return successResponse(res, result, '获取热歌榜单成功');
});

/**
 * @swagger
 * /api/recommendations/personalized:
 *   get:
 *     tags: [推荐]
 *     summary: 获取个性化推荐内容
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: 获取成功
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
 * @swagger
 * /api/recommendations/category/{tid}:
 *   get:
 *     tags: [推荐]
 *     summary: 获取分区推荐
 *     parameters:
 *       - in: path
 *         name: tid
 *         required: true
 *         schema:
 *           type: integer
 *         description: 分区ID
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: 获取成功
 *       400:
 *         description: 无效的分区ID
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
 * @swagger
 * /api/recommendations/music:
 *   get:
 *     tags: [推荐]
 *     summary: 获取音乐区推荐（综合）
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *     responses:
 *       200:
 *         description: 获取成功
 */
const getMusicRecommendation = catchAsync(async (req, res) => {
  const limit = parseInt(req.query.limit) || 20;

  const result = await recommendationService.getMusicRecommendation(limit);

  return successResponse(res, result, '获取音乐推荐成功');
});

// ==================== Phase 2B: 音乐区爬虫 ====================

/**
 * @swagger
 * /api/recommendations/music-zone:
 *   get:
 *     tags: [推荐]
 *     summary: 获取音乐区个性化推荐（爬虫方式）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: 获取成功
 *       401:
 *         description: 请先登录
 */
const getMusicZoneRecommendations = catchAsync(async (req, res) => {
  // 必须登录
  if (!req.user) {
    throw new AppError('请先登录', 401);
  }

  const page = parseInt(req.query.page) || 1;
  const pageSize = parseInt(req.query.pageSize) || 20;

  const result = await recommendationService.getMusicZoneRecommendations(
    req.user.id,
    page,
    pageSize
  );

  if (result.fallback) {
    // 爬取失败，返回降级提示
    return successResponse(res, result, '爬取失败，请稍后重试');
  }

  return successResponse(res, result, '获取音乐区推荐成功');
});

// ==================== 常量 ====================

/**
 * @swagger
 * /api/recommendations/categories:
 *   get:
 *     tags: [推荐]
 *     summary: 获取可用的分区ID列表
 *     responses:
 *       200:
 *         description: 获取成功
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
// Phase 2B: 音乐区爬虫路由（需要登录）
router.get('/music-zone', authMiddleware, getMusicZoneRecommendations);
router.get('/categories', getCategoryTids);

module.exports = router;
