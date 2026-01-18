const express = require('express');
const router = express.Router();
const recommendationController = require('../controllers/recommendationController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');

/**
 * 推荐内容相关路由
 * Prefix: /api/recommendations
 */

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
router.get('/hot-playlists', optionalAuthMiddleware, recommendationController.getHotPlaylists);

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
router.get('/rank', optionalAuthMiddleware, recommendationController.getHotRank);

// ==================== 个性化推荐 ====================

/**
 * @swagger
 * /api/recommendations/personalized:
 *   get:
 *     tags: [推荐]
 *     summary: 获取个性化推荐
 *     description: |
 *       未登录：返回热门推荐
 *       已登录：基于搜索历史和播放历史推荐
 *     security:
 *       - bearerAuth: []
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
router.get('/personalized', optionalAuthMiddleware, recommendationController.getPersonalized);

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
 *           description: 分区ID
 *           example: 3
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 20
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/category/:tid', optionalAuthMiddleware, recommendationController.getByCategory);

/**
 * @swagger
 * /api/recommendations/music:
 *   get:
 *     tags: [推荐]
 *     summary: 获取音乐区推荐（综合）
 *     description: 组合音乐区、原创音乐、翻唱等多个分区的内容
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
router.get('/music', optionalAuthMiddleware, recommendationController.getMusicRecommendation);

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
router.get('/categories', recommendationController.getCategoryTids);

module.exports = router;
