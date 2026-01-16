const express = require('express');
const router = express.Router();
const bilibiliController = require('../controllers/bilibiliController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');

// 调试日志
console.log('[DEBUG] Loading bilibili routes, router stack length:', router.stack.length);

/**
 * B站API路由
 */

// ========== QR码登录 ==========

/**
 * @swagger
 * /api/bilibili/qrcode:
 *   post:
 *     tags: [B站API]
 *     summary: 获取QR码登录凭证
 *     description: 获取B站TV端QR码登录凭证
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
 *                     qrcodeKey:
 *                       type: string
 *                       description: QR码凭证
 *                     qrCodeUrl:
 *                       type: string
 *                       description: QR码图片URL
 *                     expires_in:
 *                       type: integer
 *                       description: 过期时间（秒）
 */
router.post('/qrcode', bilibiliController.getQRCode);

/**
 * @swagger
 * /api/bilibili/qrcode/check:
 *   post:
 *     tags: [B站API]
 *     summary: 检查QR码登录状态
 *     description: 检查QR码扫描状态并完成登录
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - qrcodeKey
 *             properties:
 *               qrcodeKey:
 *                 type: string
 *                 description: QR码凭证
 *     responses:
 *       200:
 *         description: 检查成功
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
 *                     status:
 *                       type: string
 *                       enum: [pending, scanned, success, expired]
 *                       description: 登录状态
 *                     userInfo:
 *                       type: object
 *                       description: 用户信息（登录成功时返回）
 */
router.post('/qrcode/check', authMiddleware, bilibiliController.checkQRLoginStatus);

// ========== 账号绑定 ==========

/**
 * @swagger
 * /api/bilibili/status:
 *   get:
 *     tags: [B站API]
 *     summary: 获取B站账号绑定状态
 *     description: 获取当前用户的B站账号绑定状态
 *     security:
 *       - bearerAuth: []
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
 *                     isBound:
 *                       type: boolean
 *                       description: 是否已绑定
 *                     biliUserId:
 *                       type: string
 *                       description: B站用户ID
 *                     biliUsername:
 *                       type: string
 *                       description: B站用户名
 */
router.get('/status', authMiddleware, bilibiliController.getBindStatus);

/**
 * @swagger
 * /api/bilibili/unbind:
 *   delete:
 *     tags: [B站API]
 *     summary: 解绑B站账号
 *     description: 解绑当前用户的B站账号
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 解绑成功
 */
router.delete('/unbind', authMiddleware, bilibiliController.unbindAccount);

// ========== 视频信息 ==========

/**
 * @swagger
 * /api/bilibili/video/{bvid}:
 *   get:
 *     tags: [B站API]
 *     summary: 获取视频信息
 *     description: 根据BVID获取B站视频详细信息
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *         description: 视频BVID
 *         example: BV1xx411c7mD
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
 *                     cover:
 *                       type: string
 *                     duration:
 *                       type: integer
 *                     owner:
 *                       type: object
 *                     cid:
 *                       type: integer
 */
router.get('/video/:bvid', optionalAuthMiddleware, bilibiliController.getVideoInfo);

/**
 * @swagger
 * /api/bilibili/audio/{bvid}:
 *   get:
 *     tags: [B站API]
 *     summary: 获取音频流URL
 *     description: 获取B站视频的音频流播放URL
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *         description: 视频BVID
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
 *                     baseUrl:
 *                       type: string
 *                       description: 音频流URL
 *                     bandwidth:
 *                       type: integer
 *                     mimeType:
 *                       type: string
 */
router.get('/audio/:bvid', optionalAuthMiddleware, bilibiliController.getAudioStream);

// ========== UP主相关 ==========

/**
 * @swagger
 * /api/bilibili/uploader/{mid}:
 *   get:
 *     tags: [B站API]
 *     summary: 获取UP主视频列表
 *     description: 获取指定UP主的视频投稿列表
 *     parameters:
 *       - in: path
 *         name: mid
 *         required: true
 *         schema:
 *           type: string
 *         description: UP主ID
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: 页码
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 20
 *         description: 每页数量
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/uploader/:mid', optionalAuthMiddleware, bilibiliController.getUploaderVideos);

// ========== 搜索 ==========

/**
 * @swagger
 * /api/bilibili/search:
 *   get:
 *     tags: [B站API]
 *     summary: 搜索B站视频
 *     description: 根据关键词搜索B站视频
 *     parameters:
 *       - in: query
 *         name: keyword
 *         required: true
 *         schema:
 *           type: string
 *         description: 搜索关键词
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: 页码
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *           default: 20
 *         description: 每页数量
 *     responses:
 *       200:
 *         description: 搜索成功
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
 *                     keyword:
 *                       type: string
 *                     videos:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           bvid:
 *                             type: string
 *                           title:
 *                             type: string
 *                           cover:
 *                             type: string
 *                           duration:
 *                             type: string
 *                           author:
 *                             type: string
 */
router.get('/search', optionalAuthMiddleware, bilibiliController.searchBilibili);

/**
 * @swagger
 * /api/bilibili/search/recent:
 *   get:
 *     tags: [B站API]
 *     summary: 获取最近搜索关键词
 *     description: 获取当前用户的最近搜索历史（去重）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: 返回数量
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/search/recent', authMiddleware, bilibiliController.getRecentSearches);

module.exports = router;
