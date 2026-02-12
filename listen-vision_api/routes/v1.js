const express = require('express');
const router = express.Router();
const { logger } = require('../utils/logger');

/**
 * API v1 路由
 *
 * 统一管理 v1 版本的所有 API 端点
 * 路径格式: /api/v1/*
 *
 * 认证说明：
 * - 大部分端点需要 JWT Bearer Token
 * - 游客端点不需要认证
 */

// ==================== 认证相关（游客/用户） ====================

/**
 * @route   POST /api/v1/auth/register
 * @desc    用户注册
 * @access  Public
 */
router.use('/auth', require('./auth'));

/**
 * @route   POST /api/v1/auth/login
 * @route   GET  /api/v1/auth/me
 * @route   POST /api/v1/auth/send-code
 * @route   POST /api/v1/auth/verify-code
 * @route   POST /api/v1/auth/reset-pwd
 * @access  Public / Private
 */

// ==================== 用户相关 ====================

/**
 * @route   GET    /api/v1/users
 * @route   GET    /api/v1/users/:id
 * @route   PUT    /api/v1/users/:id
 * @access  Private
 */
router.use('/users', require('./users'));

// ==================== 歌单相关 ====================

/**
 * @route   GET    /api/v1/playlists
 * @route   POST   /api/v1/playlists
 * @route   GET    /api/v1/playlists/:id
 * @route   PUT    /api/v1/playlists/:id
 * @route   DELETE /api/v1/playlists/:id
 * @route   POST   /api/v1/playlists/:id/items
 * @route   DELETE /api/v1/playlists/:id/items/:bvid
 * @route   POST   /api/v1/playlists/favorites/toggle
 * @route   GET    /api/v1/playlists/favorites/check/:bvid
 * @access  Private
 */
router.use('/playlists', require('./playlists'));

// ==================== 播放历史相关 ====================

/**
 * @route   GET    /api/v1/history
 * @route   POST   /api/v1/history
 * @route   DELETE /api/v1/history
 * @route   DELETE /api/v1/history/:id
 * @access  Private
 */
router.use('/history', require('./history'));

// ==================== 搜索相关 ====================

/**
 * @route   GET /api/v1/search/local
 * @route   GET /api/v1/search/suggestions
 * @route   GET /api/v1/search/trending
 * @route   GET /api/v1/search/history
 * @access  Private
 */
router.use('/search', require('./search'));

// ==================== 推荐相关 ====================

/**
 * @route   GET /api/v1/recommendations/hot-playlists
 * @route   GET /api/v1/recommendations/rank
 * @route   GET /api/v1/recommendations/personalized
 * @access  Private
 */
router.use('/recommendations', require('./recommendations'));

// ==================== B站相关 ====================

/**
 * @route   POST /api/v1/bilibili/qrcode
 * @route   POST /api/v1/bilibili/qrcode/check
 * @route   DELETE /api/v1/bilibili/unbind
 * @route   GET /api/v1/bilibili/status
 * @route   GET /api/v1/bilibili/video/:bvid
 * @route   GET /api/v1/bilibili/audio/:bvid
 * @route   GET /api/v1/bilibili/uploader/:mid
 * @route   GET /api/v1/bilibili/search
 * @route   GET /api/v1/bilibili/search/recent
 * @route   GET /api/v1/bilibili/proxy/image
 * @route   GET /api/v1/bilibili/proxy/audio
 * @access  Private (需要 B站账号绑定)
 */
router.use('/bilibili', (req, res, next) => {
  logger.debug('Bilibili route accessed', {
    method: req.method,
    path: req.path,
    originalUrl: req.originalUrl
  });
  next();
}, require('./bilibili'));

// ==================== 网易云音乐相关 ====================

/**
 * @route   POST /api/v1/netease/qrcode
 * @route   POST /api/v1/netease/qrcode/check
 * @route   POST /api/v1/netease/login/cellphone
 * @route   GET /api/v1/netease/status
 * @route   DELETE /api/v1/netease/unbind
 * @route   GET /api/v1/netease/search
 * @route   GET /api/v1/netease/song/detail
 * @route   GET /api/v1/netease/song/url
 * @route   GET /api/v1/netease/song/lyric/:id
 * @route   GET /api/v1/netease/playlist/detail/:id
 * @route   GET /api/v1/netease/user/playlist/:uid
 * @access  Public/Private (部分需要登录)
 */
router.use('/netease', require('./netease'));

// ==================== 音频元数据相关 ====================

/**
 * @route   GET    /api/v1/audio/metadata
 * @route   GET    /api/v1/audio/metadata/:bvid
 * @route   POST   /api/v1/audio/metadata/:bvid/refresh
 * @route   DELETE /api/v1/audio/metadata/:bvid
 * @route   POST   /api/v1/audio/metadata/batch
 * @route   GET    /api/v1/audio/stream/:bvid
 * @route   GET    /api/v1/audio/search/history
 * @route   GET    /api/v1/audio/search/recent
 * @route   DELETE /api/v1/audio/search/history
 * @route   DELETE /api/v1/audio/search/:keyword
 * @route   GET    /api/v1/audio/stats
 * @route   POST   /api/v1/audio/clean
 * @access  Private
 */
router.use('/audio', require('./audio'));

// ==================== 收藏相关说明 ====================
// 收藏功能已迁移至 /api/v1/playlists/favorites/* 端点
// - GET    /api/v1/playlists/favorites       - 获取收藏列表
// - POST   /api/v1/playlists/favorites/toggle - 切换收藏状态
// - GET    /api/v1/playlists/favorites/check/:bvid - 检查是否已收藏

module.exports = router;
