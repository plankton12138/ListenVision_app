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
 * /api/bilibili/download/{bvid}:
 *   get:
 *     tags: [B站API]
 *     summary: 下载音频文件（带元数据写入）
 *     description: |
 *       下载B站视频的音频，自动转换为标准格式并写入元数据（标题、艺术家、封面）。
 *
 *       **处理流程**：
 *       1. 获取视频信息（标题、UP主、封面）
 *       2. 下载 m4s 音频流
 *       3. FFmpeg 转换为标准 MP3/M4A
 *       4. 写入元数据到文件
 *       5. 返回转换后的文件
 *
 *       **优势**：
 *       - 转换后的文件是标准格式，元数据嵌入文件中
 *       - 重传或用其他播放器打开也能显示正确信息
 *       - 封面图片嵌入文件，无需额外下载
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
 *           enum: [mp3, m4a]
 *           default: mp3
 *         description: 输出格式
 *     responses:
 *       200:
 *         description: 音频文件（带元数据）
 *         content:
 *           audio/mpeg:
 *             type: string
 *             format: binary
 *           audio/m4a:
 *             type: string
 *             format: binary
 *         headers:
 *           Content-Disposition:
 *             description: 文件名（包含标题）
 *             schema:
 *               type: string
 *       404:
 *         description: 视频不存在或无法获取音频流
 */
router.get('/download/:bvid', optionalAuthMiddleware, bilibiliController.downloadAudioWithMetadata);

/**
 * @swagger
 * /api/bilibili/download-range/{bvid}:
 *   get:
 *     tags: [B站API]
 *     summary: 下载音频文件（支持断点续传）
 *     description: |
 *       下载B站视频的音频，支持 HTTP Range 请求实现断点续传。
 *
 *       **与 /download/{bvid} 的区别**：
 *       - 支持 Range 请求头，可实现断点续传
 *       - 返回 206 Partial Content 状态码
 *       - 包含 Content-Range, ETag, Last-Modified 响应头
 *       - 使用标准 HTTP 流式传输（非 SSE）
 *
 *       **断点续传示例**：
 *       ```
 *       // 首次请求
 *       GET /api/bilibili/download-range/BV1xx411c7mD
 *       -> 200 OK, ETag: "BV1xx411c7mD-1234567-mp3"
 *
 *       // 断点续传请求
 *       GET /api/bilibili/download-range/BV1xx411c7mD
 *       Range: bytes=500000-
 *       If-Match: "BV1xx411c7mD-1234567-mp3"
 *       -> 206 Partial Content, Content-Range: bytes 500000-1234566/1234567
 *       ```
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
 *           enum: [mp3, m4a]
 *           default: mp3
 *         description: 输出格式
 *       - in: header
 *         name: Range
 *         schema:
 *           type: string
 *           example: "bytes=0-1048575"
 *         description: 请求的字节范围（断点续传）
 *       - in: header
 *         name: If-Match
 *         schema:
 *           type: string
 *         description: ETag 验证（确保文件未更改）
 *     responses:
 *       200:
 *         description: 完整文件
 *         headers:
 *           Content-Type:
 *             schema:
 *               type: string
 *           Content-Length:
 *             schema:
 *               type: integer
 *           ETag:
 *             schema:
 *               type: string
 *           Accept-Ranges:
 *             schema:
 *               type: string
 *               example: "bytes"
 *       206:
 *         description: 部分内容（断点续传）
 *         headers:
 *           Content-Range:
 *             schema:
 *               type: string
 *               example: "bytes 500000-1234566/1234567"
 *           Content-Type:
 *             schema:
 *               type: string
 *           Content-Length:
 *             schema:
 *               type: integer
 *           ETag:
 *             schema:
 *               type: string
 *       412:
 *         description: 前置条件失败（文件已更改）
 *       416:
 *         description: 请求范围无效
 */
router.get('/download-range/:bvid', optionalAuthMiddleware, bilibiliController.downloadAudioWithRange);

// ========== 下载状态管理 ==========

/**
 * @swagger
 * /api/bilibili/download/status/:requestId:
 *   get:
 *     tags: [B站API]
 *     summary: 查询下载任务状态
 *     description: |
 *       查询下载任务的实时状态，支持断线重连后恢复。
 *
 *       **使用场景**：
 *       - SSE 连接断开后重新获取状态
 *       - 检查长时间任务是否完成
 *       - 获取详细的错误信息
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: string
 *         description: 下载请求ID
 *     responses:
 *       200:
 *         description: 任务状态
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
 *                     requestId:
 *                       type: string
 *                     bvid:
 *                       type: string
 *                     status:
 *                       type: string
 *                       enum: [pending, downloading, converting, verifying, completed, failed, canceled, timeout]
 *                     progress:
 *                       type: integer
 *                       description: 进度百分比 (0-100)
 *                     stage:
 *                       type: string
 *                       description: 当前阶段
 *                     message:
 *                       type: string
 *                       description: 状态描述
 *                     fileUrl:
 *                       type: string
 *                       description: 文件URL（完成后）
 *                     fileName:
 *                       type: string
 *                     fileSize:
 *                       type: integer
 *                     checksum:
 *                       type: string
 *                       description: 文件校验和（用于验证）
 *                     error:
 *                       type: string
 *                       description: 错误信息（失败时）
 *                     createdAt:
 *                       type: integer
 *                       description: 创建时间戳
 *                     estimatedTimeRemaining:
 *                       type: integer
 *                       description: 预计剩余时间（毫秒）
 *       404:
 *         description: 任务不存在或已过期
 */
router.get('/download/status/:requestId', optionalAuthMiddleware, bilibiliController.getDownloadStatus);

/**
 * @swagger
 * /api/bilibili/download/confirm/:requestId:
 *   post:
 *     tags: [B站API]
 *     summary: 确认下载完成并验证文件
 *     description: |
 *       客户端下载完成后调用此接口确认，并可选地提供文件校验和进行双重验证。
 *
 *       **双重验证机制**：
 *       - 客户端计算本地文件的校验和
 *       - 服务端验证校验和是否匹配
 *       - 验证通过后才标记任务真正完成
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: string
 *       - in: body
 *         name: body
 *         schema:
 *           type: object
 *           properties:
 *             checksum:
 *               type: string
 *               description: 客户端计算的文件校验和（SHA256）
 *     responses:
 *       200:
 *         description: 确认成功
 *       400:
 *         description: 校验失败
 *       404:
 *         description: 任务不存在
 */
router.post('/download/confirm/:requestId', optionalAuthMiddleware, bilibiliController.confirmDownload);

/**
 * @swagger
 * /api/bilibili/download/cancel/:requestId:
 *   delete:
 *     tags: [B站API]
 *     summary: 取消下载任务
 *     description: 取消正在进行的下载任务
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 取消成功
 *       404:
 *         description: 任务不存在
 */
router.delete('/download/cancel/:requestId', optionalAuthMiddleware, bilibiliController.cancelDownload);

/**
 * @swagger
 * /api/bilibili/download/heartbeat/:requestId:
 *   post:
 *     tags: [B站API]
 *     summary: 发送客户端心跳
 *     description: |
 *       客户端定期发送心跳，告知服务器仍在等待。
 *
 *       服务器使用此信息判断客户端是否在线：
 *       - 如果超过60秒没有心跳，认为客户端离线
 *       - 离线客户端的任务可能被清理
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 心跳接收成功
 */
router.post('/download/heartbeat/:requestId', optionalAuthMiddleware, bilibiliController.heartbeat);

module.exports = router;
