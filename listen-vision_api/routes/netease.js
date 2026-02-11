const express = require('express');
const router = express.Router();
const neteaseController = require('../controllers/neteaseController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');

/**
 * 网易云音乐 API 路由
 */

// ========== 登录绑定 ==========

/**
 * @route POST /api/v1/netease/qrcode
 * @desc 获取二维码登录凭证
 * @access Public
 */
router.post('/qrcode', neteaseController.getQRCode);

/**
 * @route POST /api/v1/netease/qrcode/check
 * @desc 检查二维码登录状态并完成绑定
 * @access Private
 */
router.post('/qrcode/check', authMiddleware, neteaseController.checkQRLoginStatus);

/**
 * @route POST /api/v1/netease/login/cellphone
 * @desc 手机号登录
 * @access Private
 */
router.post('/login/cellphone', authMiddleware, neteaseController.loginWithCellphone);

/**
 * @route GET /api/v1/netease/status
 * @desc 获取绑定状态
 * @access Private
 */
router.get('/status', authMiddleware, neteaseController.getBindStatus);

/**
 * @route DELETE /api/v1/netease/unbind
 * @desc 解绑账号
 * @access Private
 */
router.delete('/unbind', authMiddleware, neteaseController.unbindAccount);

// ========== 搜索 ==========

/**
 * @route GET /api/v1/netease/search
 * @desc 搜索歌曲
 * @query keywords - 搜索关键词
 * @query limit - 返回数量 (default: 30)
 * @query offset - 偏移量 (default: 0)
 * @access Public (可选认证)
 */
router.get('/search', optionalAuthMiddleware, neteaseController.search);

// ========== 歌曲相关 ==========

/**
 * @route GET /api/v1/netease/song/detail
 * @desc 获取歌曲详情
 * @query ids - 歌曲ID (多个用逗号分隔)
 * @access Public (可选认证)
 */
router.get('/song/detail', optionalAuthMiddleware, neteaseController.getSongDetail);

/**
 * @route GET /api/v1/netease/song/url
 * @desc 获取歌曲播放URL
 * @query id - 歌曲ID
 * @access Public (可选认证，登录用户可能获取更高音质)
 */
router.get('/song/url', optionalAuthMiddleware, neteaseController.getSongUrl);

/**
 * @route GET /api/v1/netease/song/lyric/:id
 * @desc 获取歌词
 * @param id - 歌曲ID
 * @access Public
 */
router.get('/song/lyric/:id', neteaseController.getLyric);

// ========== 歌单相关 ==========

/**
 * @route GET /api/v1/netease/playlist/detail/:id
 * @desc 获取歌单详情
 * @param id - 歌单ID
 * @access Public (可选认证)
 */
router.get('/playlist/detail/:id', optionalAuthMiddleware, neteaseController.getPlaylistDetail);

/**
 * @route GET /api/v1/netease/user/playlist/:uid
 * @desc 获取用户歌单
 * @param uid - 网易云用户ID
 * @access Private
 */
router.get('/user/playlist/:uid', authMiddleware, neteaseController.getUserPlaylist);

module.exports = router;
