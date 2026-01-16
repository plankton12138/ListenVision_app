const express = require('express');
const router = express.Router();
const audioController = require('../controllers/audioController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');

/**
 * 音频元数据路由
 */

// ========== 元数据 ==========

/**
 * @swagger
 * /api/audio/metadata/{bvid}:
 *   get:
 *     tags: [音频元数据]
 *     summary: 获取音频元数据
 *     description: 获取指定BVID的音频元数据（优先从缓存）
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *         description: 视频BVID
 *       - in: query
 *         name: maxAge
 *         schema:
 *           type: integer
 *         description: 缓存最大年龄（毫秒）
 *     responses:
 *       200:
 *         description: 获取成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     bvid:
 *                       type: string
 *                     title:
 *                       type: string
 *                     artist:
 *                       type: string
 *                     duration:
 *                       type: integer
 *                     cover:
 *                       type: string
 */
router.get('/metadata/:bvid', optionalAuthMiddleware, audioController.getAudioMetadata);

/**
 * @swagger
 * /api/audio/metadata/{bvid}:
 *   post:
 *     tags: [音频元数据]
 *     summary: 刷新元数据缓存
 *     description: 强制从B站重新获取并缓存元数据
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 刷新成功
 */
router.post('/metadata/:bvid/refresh', optionalAuthMiddleware, audioController.refreshMetadata);

/**
 * @swagger
 * /api/audio/metadata/{bvid}:
 *   delete:
 *     tags: [音频元数据]
 *     summary: 删除元数据缓存
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
router.delete('/metadata/:bvid', optionalAuthMiddleware, audioController.deleteMetadata);

/**
 * @swagger
 * /api/audio/metadata:
 *   get:
 *     tags: [音频元数据]
 *     summary: 获取所有缓存元数据
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/metadata', optionalAuthMiddleware, audioController.getAllMetadata);

/**
 * @swagger
 * /api/audio/metadata/batch:
 *   post:
 *     tags: [音频元数据]
 *     summary: 批量获取音频元数据
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - bvids
 *             properties:
 *               bvids:
 *                 type: array
 *                 items:
 *                   type: string
 *                 maxItems: 50
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.post('/metadata/batch', optionalAuthMiddleware, audioController.getMultipleMetadata);

/**
 * @swagger
 * /api/audio/stream/{bvid}:
 *   get:
 *     tags: [音频元数据]
 *     summary: 获取音频流URL
 *     description: 获取指定BVID的音频播放URL
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 获取成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     bvid:
 *                       type: string
 *                     title:
 *                       type: string
 *                     audioUrl:
 *                       type: string
 *                     duration:
 *                       type: integer
 */
router.get('/stream/:bvid', optionalAuthMiddleware, audioController.getAudioStreamUrl);

// ========== 搜索历史 ==========

/**
 * @swagger
 * /api/audio/search/history:
 *   get:
 *     tags: [音频元数据]
 *     summary: 获取搜索历史
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/search/history', authMiddleware, audioController.getSearchHistory);

/**
 * @swagger
 * /api/audio/search/recent:
 *   get:
 *     tags: [音频元数据]
 *     summary: 获取最近搜索关键词
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/search/recent', authMiddleware, audioController.getRecentSearches);

/**
 * @swagger
 * /api/audio/search/history:
 *   delete:
 *     tags: [音频元数据]
 *     summary: 清空搜索历史
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 清空成功
 */
router.delete('/search/history', authMiddleware, audioController.clearSearchHistory);

/**
 * @swagger
 * /api/audio/search/{keyword}:
 *   delete:
 *     tags: [音频元数据]
 *     summary: 删除特定搜索关键词
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: keyword
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 删除成功
 */
router.delete('/search/:keyword', authMiddleware, audioController.deleteSearchKeyword);

// ========== 统计 ==========

/**
 * @swagger
 * /api/audio/stats:
 *   get:
 *     tags: [音频元数据]
 *     summary: 获取缓存统计信息
 *     responses:
 *       200:
 *         description: 获取成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     totalCached:
 *                       type: integer
 *                       description: 缓存总数
 *                     lastUpdate:
 *                       type: string
 *                       description: 最后更新时间
 */
router.get('/stats', optionalAuthMiddleware, audioController.getCacheStats);

/**
 * @swagger
 * /api/audio/clean:
 *   post:
 *     tags: [音频元数据]
 *     summary: 清理过期缓存
 *     parameters:
 *       - in: query
 *         name: maxAge
 *         schema:
 *           type: integer
 *         description: 最大年龄（毫秒），默认30天
 *     responses:
 *       200:
 *         description: 清理成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     cleaned:
 *                       type: integer
 *                       description: 清理的数量
 */
router.post('/clean', optionalAuthMiddleware, audioController.cleanExpiredCache);

module.exports = router;
