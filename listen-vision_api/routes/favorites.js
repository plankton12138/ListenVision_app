const express = require('express');
const router = express.Router();
const favoriteController = require('../controllers/favoriteController');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { favoriteValidators } = require('../middleware/validator');
const { generalLimiter } = require('../middleware/rateLimiter');

/**
 * 收藏相关路由
 */

/**
 * @swagger
 * /api/favorites:
 *   get:
 *     tags: [收藏]
 *     summary: 获取收藏列表
 *     description: |
 *       未登录：返回所有收藏
 *       已登录：只返回当前用户的收藏
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Favorite'
 */
router.get('/', optionalAuthMiddleware, favoriteController.getFavorites);

/**
 * @swagger
 * /api/favorites:
 *   post:
 *     tags: [收藏]
 *     summary: 添加收藏
 *     description: 为当前登录用户添加收藏
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - url
 *               - title
 *             properties:
 *               url:
 *                 type: string
 *                 format: uri
 *                 example: https://example.com/audio.mp3
 *               title:
 *                 type: string
 *                 example: 测试音频
 *     responses:
 *       201:
 *         description: 添加成功
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Favorite'
 *       400:
 *         $ref: '#/components/schemas/Error'
 *       401:
 *         $ref: '#/components/schemas/Error'
 *       409:
 *         $ref: '#/components/schemas/Error'
 */
router.post('/', authMiddleware, generalLimiter, favoriteValidators.addFavorite, favoriteController.addFavorite);

/**
 * @swagger
 * /api/favorites/{id}:
 *   get:
 *     tags: [收藏]
 *     summary: 获取单个收藏
 *     description: 根据ID获取收藏详情
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: 收藏ID
 *     responses:
 *       200:
 *         description: 获取成功
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Favorite'
 *       404:
 *         $ref: '#/components/schemas/Error'
 */
router.get('/:id', authMiddleware, favoriteValidators.getFavorite, favoriteController.getFavoriteById);

/**
 * @swagger
 * /api/favorites/{id}:
 *   put:
 *     tags: [收藏]
 *     summary: 更新收藏
 *     description: 更新收藏信息
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: 收藏ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               url:
 *                 type: string
 *                 format: uri
 *               title:
 *                 type: string
 *               username:
 *                 type: string
 *     responses:
 *       200:
 *         description: 更新成功
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Favorite'
 *       400:
 *         $ref: '#/components/schemas/Error'
 *       404:
 *         $ref: '#/components/schemas/Error'
 */
router.put('/:id', authMiddleware, favoriteValidators.updateFavorite, favoriteController.updateFavorite);

/**
 * @swagger
 * /api/favorites/{id}:
 *   delete:
 *     tags: [收藏]
 *     summary: 删除收藏
 *     description: 删除指定收藏
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: 收藏ID
 *     responses:
 *       200:
 *         description: 删除成功
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       404:
 *         $ref: '#/components/schemas/Error'
 */
router.delete('/:id', authMiddleware, favoriteValidators.getFavorite, favoriteController.deleteFavorite);

module.exports = router;
