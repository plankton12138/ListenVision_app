const express = require('express');
const router = express.Router();
const playlistController = require('../controllers/playlistController');
const { authMiddleware } = require('../middleware/auth');
const { generalLimiter } = require('../middleware/rateLimiter');

/**
 * 歌单相关路由
 * Prefix: /api/playlists
 */

// ==================== 歌单管理 ====================

/**
 * @swagger
 * /api/playlists:
 *   get:
 *     tags: [歌单]
 *     summary: 获取用户所有歌单
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/', authMiddleware, playlistController.getUserPlaylists);

/**
 * @swagger
 * /api/playlists:
 *   post:
 *     tags: [歌单]
 *     summary: 创建新歌单
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *                 example: 我的歌单
 *               description:
 *                 type: string
 *                 example: 这是一个测试歌单
 *               coverUrl:
 *                 type: string
 *                 format: uri
 *     responses:
 *       201:
 *         description: 创建成功
 */
router.post('/', authMiddleware, generalLimiter, playlistController.createPlaylist);

// ==================== 特定路径路由 (必须在 /:id 之前) ====================

// 收藏快捷方法
router.post('/favorites/toggle', authMiddleware, playlistController.toggleFavorite);
router.get('/favorites/check/:bvid', authMiddleware, playlistController.checkFavorite);
router.get('/favorites', authMiddleware, playlistController.getFavorites);

// 播放队列
router.post('/now-playing', authMiddleware, playlistController.saveNowPlaying);
router.get('/now-playing', authMiddleware, playlistController.getNowPlaying);

// ==================== 动态路由 ====================

/**
 * @swagger
 * /api/playlists/{id}:
 *   get:
 *     tags: [歌单]
 *     summary: 获取歌单详情（包含items）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: sortType
 *         schema:
 *           type: string
 *           enum: [added_at_desc, added_at_asc, title_asc, title_desc, artist_asc, artist_desc, position_asc]
 *         description: 排序方式，默认为position_asc
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/:id', authMiddleware, playlistController.getPlaylistDetail);

/**
 * @swagger
 * /api/playlists/{id}/items:
 *   get:
 *     tags: [歌单]
 *     summary: 获取歌单项列表
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
 *         description: 获取成功
 */
router.get('/:id/items', authMiddleware, playlistController.getPlaylistItems);

/**
 * @swagger
 * /api/playlists/{id}:
 *   put:
 *     tags: [歌单]
 *     summary: 更新歌单信息
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 更新成功
 */
router.put('/:id', authMiddleware, playlistController.updatePlaylist);

/**
 * @swagger
 * /api/playlists/{id}:
 *   delete:
 *     tags: [歌单]
 *     summary: 删除歌单
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 删除成功
 */
router.delete('/:id', authMiddleware, playlistController.deletePlaylist);

// ==================== 歌单项管理 ====================

/**
 * @swagger
 * /api/playlists/{id}/items:
 *   post:
 *     tags: [歌单]
 *     summary: 添加音频到歌单
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
 *     responses:
 *       201:
 *         description: 添加成功
 */
router.post('/:id/items', authMiddleware, playlistController.addItem);

/**
 * @swagger
 * /api/playlists/{id}/items/{bvid}:
 *   delete:
 *     tags: [歌单]
 *     summary: 从歌单移除音频
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 移除成功
 */
router.delete('/:id/items/:bvid', authMiddleware, playlistController.removeItem);

/**
 * @swagger
 * /api/playlists/{id}/items/reorder:
 *   put:
 *     tags: [歌单]
 *     summary: 调整歌单项顺序
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - items
 *             properties:
 *               items:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     position:
 *                       type: integer
 *     responses:
 *       200:
 *         description: 调整成功
 */
router.put('/:id/items/reorder', authMiddleware, playlistController.reorderItems);

/**
 * @swagger
 * /api/playlists/{id}/sort:
 *   put:
 *     tags: [歌单]
 *     summary: 重新排序歌单项
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - sortType
 *             properties:
 *               sortType:
 *                 type: string
 *                 enum: [added_at_desc, added_at_asc, title_asc, title_desc, artist_asc, artist_desc, position_asc]
 *                 example: title_asc
 *     responses:
 *       200:
 *         description: 排序成功
 */
router.put('/:id/sort', authMiddleware, playlistController.sortItems);

/**
 * @swagger
 * /api/playlists/{id}/play:
 *   post:
 *     tags: [歌单]
 *     summary: 增加歌单播放次数
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 记录成功
 */
router.post('/:id/play', authMiddleware, playlistController.incrementPlayCount);

module.exports = router;
