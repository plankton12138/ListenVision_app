const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middleware/auth');
const { authValidators } = require('../middleware/validator');
const { registerLimiter, loginLimiter, sendCodeLimiter } = require('../middleware/rateLimiter');

/**
 * 认证相关路由
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     tags: [认证]
 *     summary: 用户注册 - 发送验证码
 *     description: 验证参数后发送验证码到邮箱，返回待验证状态
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - email
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 minLength: 3
 *                 maxLength: 20
 *                 example: testuser
 *               email:
 *                 type: string
 *                 format: email
 *                 example: test@example.com
 *               password:
 *                 type: string
 *                 minLength: 6
 *                 example: password123
 *     responses:
 *       201:
 *         description: 验证码已发送
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         pending:
 *                           type: boolean
 *                         email:
 *                           type: string
 *                         expiresIn:
 *                           type: integer
 *       400:
 *         $ref: '#/components/schemas/Error'
 *       409:
 *         $ref: '#/components/schemas/Error'
 */
router.post('/register', registerLimiter, authController.register);

/**
 * @swagger
 * /api/auth/verify-email:
 *   post:
 *     tags: [认证]
 *     summary: 验证邮箱并完成注册
 *     description: 验证邮箱验证码，创建用户账号
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - code
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: test@example.com
 *               code:
 *                 type: string
 *                 minLength: 6
 *                 maxLength: 6
 *                 example: '123456'
 *     responses:
 *       201:
 *         description: 注册成功
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/LoginResponse'
 *       400:
 *         $ref: '#/components/schemas/Error'
 */
router.post('/verify-email', registerLimiter, authController.verifyEmail);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     tags: [认证]
 *     summary: 用户登录
 *     description: 使用用户名和密码登录，返回 JWT Token
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 example: testuser
 *               password:
 *                 type: string
 *                 example: password123
 *     responses:
 *       200:
 *         description: 登录成功
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/LoginResponse'
 *       400:
 *         $ref: '#/components/schemas/Error'
 *       401:
 *         $ref: '#/components/schemas/Error'
 */
router.post('/login', loginLimiter, authValidators.login, authController.login);

/**
 * @swagger
 * /api/auth/send-code:
 *   post:
 *     tags: [认证]
 *     summary: 发送密码重置验证码
 *     description: 向用户邮箱发送 6 位验证码
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *             properties:
 *               username:
 *                 type: string
 *                 example: testuser
 *     responses:
 *       200:
 *         description: 验证码已发送（无论用户是否存在都返回成功）
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 */
router.post('/send-code', sendCodeLimiter, authValidators.sendResetCode, authController.sendResetCode);

/**
 * @swagger
 * /api/auth/reset-pwd:
 *   post:
 *     tags: [认证]
 *     summary: 重置密码
 *     description: 使用验证码重置用户密码
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - code
 *               - newPassword
 *             properties:
 *               username:
 *                 type: string
 *                 example: testuser
 *               code:
 *                 type: string
 *                 minLength: 6
 *                 maxLength: 6
 *                 example: '123456'
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *                 example: newpassword123
 *     responses:
 *       200:
 *         description: 密码重置成功
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         $ref: '#/components/schemas/Error'
 */
router.post('/reset-pwd', authValidators.resetPassword, authController.resetPassword);

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     tags: [认证]
 *     summary: 获取当前用户信息
 *     description: 获取当前登录用户的详细信息
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
 *                       $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/schemas/Error'
 *       404:
 *         $ref: '#/components/schemas/Error'
 */
router.get('/me', authMiddleware, authController.getMe);

/**
 * @swagger
 * /api/auth/verify-token:
 *   get:
 *     tags: [认证]
 *     summary: 验证 Token 有效性
 *     description: 检查 Token 是否有效
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Token 有效
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         $ref: '#/components/schemas/Error'
 */
router.get('/verify-token', authMiddleware, authController.verifyToken);

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     tags: [认证]
 *     summary: 用户登出
 *     description: 登出当前用户（客户端清除token即可）
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 登出成功
 */
router.post('/logout', authMiddleware, authController.logout);

/**
 * @swagger
 * /api/auth/refresh:
 *   post:
 *     tags: [认证]
 *     summary: 刷新 Token
 *     description: 使用 refresh token 获取新的 access token
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: 用于刷新的 refresh token
 *             required:
 *               - refreshToken
 *     responses:
 *       200:
 *         description: Token 刷新成功
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
 *                     token:
 *                       type: string
 *                       description: 新的 access token
 *                     refreshToken:
 *                       type: string
 *                       description: 原 refresh token
 *       400:
 *         $ref: '#/components/schemas/Error'
 *       401:
 *         $ref: '#/components/schemas/Error'
 */
router.post('/refresh', authController.refresh);

/**
 * @swagger
 * /api/auth/account:
 *   delete:
 *     tags: [认证]
 *     summary: 注销账号
 *     description: 永久删除用户账号及所有关联数据
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 账号已注销
 *       401:
 *         $ref: '#/components/schemas/Error'
 */
router.delete('/account', authMiddleware, authController.deleteAccount);

module.exports = router;
