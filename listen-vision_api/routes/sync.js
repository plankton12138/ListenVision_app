const express = require('express');
const router = express.Router();
const syncController = require('../controllers/syncController');
const { authMiddleware } = require('../middleware/auth');
const { generalLimiter } = require('../middleware/rateLimiter');

/**
 * 同步相关路由
 * Prefix: /api/v1/sync
 *
 * 用于双向数据同步，支持：
 * - 获取云端收藏列表（带时间戳）
 * - 获取云端歌单列表（带时间戳）
 * - 获取云端播放历史（带时间戳）
 * - 获取增量变更
 */

// 所有同步端点都需要认证
router.use(authMiddleware);

/**
 * @swagger
 * /api/v1/sync/favorites:
 *   get:
 *     tags: [同步]
 *     summary: 获取云端收藏列表（带时间戳）
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/favorites', generalLimiter, syncController.getCloudFavorites);

/**
 * @swagger
 * /api/v1/sync/playlists:
 *   get:
 *     tags: [同步]
 *     summary: 获取云端歌单列表（带时间戳）
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/playlists', generalLimiter, syncController.getCloudPlaylists);

/**
 * @swagger
 * /api/v1/sync/history:
 *   get:
 *     tags: [同步]
 *     summary: 获取云端播放历史（带时间戳）
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/history', generalLimiter, syncController.getCloudHistory);

/**
 * @swagger
 * /api/v1/sync/changes:
 *   get:
 *     tags: [同步]
 *     summary: 获取增量变更
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: since
 *         schema:
 *           type: string
 *           format: date-time
 *         description: 时间戳（ISO 8601格式），返回该时间之后的变更
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/changes', generalLimiter, syncController.getCloudChanges);

/**
 * @swagger
 * /api/v1/sync/status:
 *   get:
 *     tags: [同步]
 *     summary: 获取同步状态
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/status', generalLimiter, syncController.getSyncStatus);

module.exports = router;
