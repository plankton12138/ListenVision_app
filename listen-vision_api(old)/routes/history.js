const express = require('express');
const router = express.Router();
const playHistoryController = require('../controllers/playHistoryController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { generalLimiter } = require('../middleware/rateLimiter');

/**
 * 播放历史相关路由
 * Prefix: /api/history
 */

/**
 * @swagger
 * /api/history:
 *   get:
 *     tags: [播放历史]
 *     summary: 获取播放历史
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/', authMiddleware, playHistoryController.getHistory);

/**
 * @swagger
 * /api/history/all:
 *   get:
 *     tags: [播放历史]
 *     summary: 获取所有播放历史（不分页）
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/all', authMiddleware, playHistoryController.getAllHistory);

/**
 * @swagger
 * /api/history:
 *   post:
 *     tags: [播放历史]
 *     summary: 记录播放
 *     description: 记录一次播放行为，支持游客模式
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - bvid
 *             properties:
 *               bvid:
 *                 type: string
 *                 example: BV1xx411c7mD
 *               title:
 *                 type: string
 *                 example: 视频标题
 *               artist:
 *                 type: string
 *                 example: UP主名称
 *               duration:
 *                 type: integer
 *                 example: 180
 *               coverUrl:
 *                 type: string
 *                 format: uri
 *               progress:
 *                 type: integer
 *                 description: 播放进度（秒）
 *                 default: 0
 *     responses:
 *       201:
 *         description: 记录成功
 */
router.post('/', optionalAuthMiddleware, generalLimiter, playHistoryController.recordPlay);

/**
 * @swagger
 * /api/history/stats:
 *   get:
 *     tags: [播放历史]
 *     summary: 获取播放历史统计
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/stats', authMiddleware, playHistoryController.getHistoryStats);

/**
 * @swagger
 * /api/history:
 *   delete:
 *     tags: [播放历史]
 *     summary: 清空播放历史
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 清空成功
 */
router.delete('/', authMiddleware, playHistoryController.clearHistory);

/**
 * @swagger
 * /api/history/{bvid}:
 *   delete:
 *     tags: [播放历史]
 *     summary: 删除指定播放记录
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 删除成功
 */
router.delete('/:bvid', authMiddleware, playHistoryController.removeHistoryItem);

/**
 * @swagger
 * /api/history/by-id/{id}:
 *   delete:
 *     tags: [播放历史]
 *     summary: 按ID删除播放记录
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: 删除成功
 */
router.delete('/by-id/:id', authMiddleware, playHistoryController.removeHistoryById);

module.exports = router;
