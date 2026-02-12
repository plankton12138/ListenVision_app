const express = require('express');
const router = express.Router();
const bilibiliController = require('../controllers/bilibiliController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { successResponse, errorResponse } = require('../utils/response');
const { logger } = require('../utils/logger');

// 调试日志
logger.debug('Loading bilibili routes', { stackLength: router.stack.length });

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
 * /api/bilibili/search/suggest:
 *   get:
 *     tags: [B站API]
 *     summary: 获取搜索建议（联想词）
 *     description: 根据输入关键词返回B站搜索建议
 *     parameters:
 *       - in: query
 *         name: keyword
 *         required: true
 *         schema:
 *           type: string
 *         description: 输入关键词
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/search/suggest', bilibiliController.getSearchSuggestions);

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

/**
 * @swagger
 * /api/bilibili/search/recent:
 *   delete:
 *     tags: [B站API]
 *     summary: 清空搜索历史
 *     description: 清空当前用户的搜索历史
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 清空成功
 */
router.delete('/search/recent', authMiddleware, bilibiliController.clearSearchHistory);

/**
 * @swagger
 * /api/bilibili/proxy/image:
 *   get:
 *     tags: [B站API]
 *     summary: 代理图片（解决封面防盗链）
 *     parameters:
 *       - in: query
 *         name: url
 *         required: true
 *         schema:
 *           type: string
 *         description: 图片URL
 *     responses:
 *       200:
 *         description: 图片数据
 *         content:
 *           image/*:
 *             type: string
 *             format: binary
 */
router.get('/proxy/image', optionalAuthMiddleware, bilibiliController.proxyImage);

/**
 * @swagger
 * /api/bilibili/proxy/audio:
 *   get:
 *     tags: [B站API]
 *     summary: 代理音频流（解决防盗链，可选格式转换）
 *     parameters:
 *       - in: query
 *         name: url
 *         required: true
 *         schema:
 *           type: string
 *         description: 音频流URL
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [m4s, mp3, aac]
 *           default: m4s
 *         description: 输出格式 (m4s=原始, mp3=转换为MP3, aac=转换为AAC)
 *     responses:
 *       200:
 *         description: 音频流
 *         content:
 *           audio/mp4:
 *             type: string
 *             format: binary
 *           audio/mpeg:
 *             type: string
 *             format: binary
 *           audio/aac:
 *             type: string
 *             format: binary
 */
router.get('/proxy/audio', optionalAuthMiddleware, bilibiliController.proxyAudioStream);

/**
 * @swagger
 * /api/bilibili/proxy/audio/{bvid}:
 *   get:
 *     tags: [B站API]
 *     summary: 代理音频流通过BVID（推荐，短URL）
 *     parameters:
 *       - in: path
 *         name: bvid
 *         required: true
 *         schema:
 *           type: string
 *         description: 视频BVID
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [m4s, mp3, aac]
 *           default: m4s
 *         description: 输出格式 (m4s=原始, mp3=转换为MP3, aac=转换为AAC)
 *     responses:
 *       200:
 *         description: 音频流
 *         content:
 *           audio/mp4:
 *             type: string
 *             format: binary
 *           audio/mpeg:
 *             type: string
 *             format: binary
 *           audio/aac:
 *             type: string
 *             format: binary
 */
router.get('/proxy/audio/:bvid', optionalAuthMiddleware, bilibiliController.proxyAudioStreamByBvid);

/**
 * @swagger
 * /api/bilibili/recommend:
 *   get:
 *     tags: [B站API]
 *     summary: 获取B站音乐区推荐
 *     description: 获取B站音乐区的个性化推荐视频
 *     parameters:
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
router.get('/recommend', (req, res, next) => {
  logger.debug('Recommend route hit', {
    query: req.query,
    userId: req.user?.id
  });
  next();
}, optionalAuthMiddleware, bilibiliController.getRecommendedVideos);

/**
 * @swagger
 * /api/bilibili/refresh-cookie:
 *   post:
 *     tags: [B站API]
 *     summary: 手动刷新Cookie
 *     description: 手动触发当前用户的B站Cookie刷新
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 刷新成功
 *       400:
 *         description: 刷新失败或无需刷新
 */
router.post('/refresh-cookie', authMiddleware, async (req, res) => {
  try {
    const cookieRefreshScheduler = require('../services/cookieRefreshScheduler');
    const success = await cookieRefreshScheduler.refreshUser(req.user.id);

    if (success) {
      successResponse(res, { success: true }, 'Cookie刷新成功');
    } else {
      errorResponse(res, 'Cookie刷新失败或无需刷新', 400);
    }
  } catch (error) {
    errorResponse(res, error.message, 500);
  }
});

// 注意：下载功能已迁移到前端，以下路由已移除
// - /download/:bvid (SSE 下载)
// - /download-range/:bvid (断点续传)
// - /download/status/:requestId (状态查询)
// - /download/confirm/:requestId (确认下载)
// - /download/heartbeat/:requestId (心跳)

module.exports = router;
