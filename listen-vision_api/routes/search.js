/**
 * 搜索路由
 *
 * Phase 3.1 - 搜索 API 端点
 */

const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { successResponse } = require('../utils/response');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const searchService = require('../services/searchService');

// ==================== 本地搜索 ====================

/**
 * @swagger
 * /api/search/local:
 *   get:
 *     tags: [搜索]
 *     summary: 本地音频元数据全文搜索（FTS5）
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: 搜索关键词
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *           maximum: 100
 *         description: 返回结果数量
 *     responses:
 *       200:
 *         description: 搜索成功
 *       400:
 *         description: 搜索关键词不能为空
 */
const localSearch = catchAsync(async (req, res) => {
  const { q: keyword, limit } = req.query;

  if (!keyword || keyword.trim().length === 0) {
    throw new AppError('搜索关键词不能为空', 400);
  }

  const limitValue = Math.min(parseInt(limit) || 20, 100);

  const results = searchService.searchAudioMetadata(keyword.trim(), limitValue);

  return successResponse(res, results, '搜索成功');
});

/**
 * @swagger
 * /api/search/suggestions:
 *   get:
 *     tags: [搜索]
 *     summary: 获取搜索建议（自动完成）
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: 搜索前缀
 *     responses:
 *       200:
 *         description: 获取成功
 */
const searchSuggestions = catchAsync(async (req, res) => {
  const { q: prefix } = req.query;

  if (!prefix || prefix.length < 1) {
    throw new AppError('搜索前缀不能为空', 400);
  }

  const suggestions = searchService.getSearchSuggestions(prefix);

  return successResponse(res, suggestions, '获取搜索建议成功');
});

/**
 * @swagger
 * /api/search/trending:
 *   get:
 *     tags: [搜索]
 *     summary: 获取热门搜索关键词
 *     responses:
 *       200:
 *         description: 获取成功
 */
const trendingKeywords = catchAsync(async (req, res) => {
  const trending = searchService.getTrendingKeywords();

  return successResponse(res, trending, '获取热门关键词成功');
});

// ==================== 搜索历史 ====================

/**
 * @swagger
 * /api/search/history:
 *   get:
 *     tags: [搜索]
 *     summary: 获取用户搜索历史
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 获取成功
 *   post:
 *     tags: [搜索]
 *     summary: 保存搜索关键词到历史记录
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - keyword
 *             properties:
 *               keyword:
 *                 type: string
 *     responses:
 *       200:
 *         description: 保存成功
 *   delete:
 *     tags: [搜索]
 *     summary: 清空搜索历史
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 清空成功
 */
const getSearchHistory = catchAsync(async (req, res) => {
  const userId = req.user ? req.user.id : null;

  const history = searchService.getSearchHistory(userId);

  return successResponse(res, history, '获取搜索历史成功');
});

/**
 * @swagger
 * /api/search/history/{keyword}:
 *   delete:
 *     tags: [搜索]
 *     summary: 删除指定搜索关键词
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
const saveSearchHistory = catchAsync(async (req, res) => {
  const { keyword } = req.body;

  if (!req.user) {
    throw new AppError('请先登录', 401);
  }

  if (!keyword || keyword.trim().length === 0) {
    throw new AppError('搜索关键词不能为空', 400);
  }

  searchService.saveSearchHistory(req.user.id, keyword.trim());

  return successResponse(res, { success: true }, '保存搜索历史成功');
});

/**
 * P1: Swagger 文档已在路由上方定义
 */
const deleteSearchKeyword = catchAsync(async (req, res) => {
  if (!req.user) {
    throw new AppError('请先登录', 401);
  }

  const { keyword } = req.params;

  searchService.deleteSearchKeyword(req.user.id, keyword);

  return successResponse(res, { success: true }, '删除搜索关键词成功');
});

const clearSearchHistory = catchAsync(async (req, res) => {
  if (!req.user) {
    throw new AppError('请先登录', 401);
  }

  searchService.clearSearchHistory(req.user.id);

  return successResponse(res, { success: true }, '清空搜索历史成功');
});

// 注册路由
router.get('/local', localSearch);
router.get('/suggestions', searchSuggestions);
router.get('/trending', trendingKeywords);
router.get('/history', authMiddleware, getSearchHistory);
router.post('/history', authMiddleware, saveSearchHistory);
router.delete('/history/:keyword', authMiddleware, deleteSearchKeyword);
router.delete('/history', authMiddleware, clearSearchHistory);

module.exports = router;
