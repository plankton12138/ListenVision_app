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

/**
 * GET /api/search/local
 *
 * 本地音频元数据全文搜索（FTS5）
 *
 * Query Parameters:
 * - q: 搜索关键词（必填）
 * - limit: 返回结果数量（可选，默认 20，最大 100）
 *
 * Response:
 * - success: true
 * - data: 搜索结果数组
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
 * GET /api/search/suggestions
 *
 * 获取搜索建议（自动完成）
 *
 * Query Parameters:
 * - q: 搜索前缀（必填）
 *
 * Response:
 * - success: true
 * - data: 建议关键词数组
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
 * GET /api/search/trending
 *
 * 获取热门搜索关键词
 *
 * Response:
 * - success: true
 * - data: 热门关键词列表（包含搜索次数）
 */
const trendingKeywords = catchAsync(async (req, res) => {
  const trending = searchService.getTrendingKeywords();

  return successResponse(res, trending, '获取热门关键词成功');
});

/**
 * GET /api/search/history
 *
 * 获取用户搜索历史
 *
 * Authentication: 可选（未登录返回全局历史，已登录返回用户历史）
 *
 * Response:
 * - success: true
 * - data: 搜索历史列表
 */
const getSearchHistory = catchAsync(async (req, res) => {
  const userId = req.user ? req.user.id : null;

  const history = searchService.getSearchHistory(userId);

  return successResponse(res, history, '获取搜索历史成功');
});

/**
 * POST /api/search/history
 *
 * 保存搜索关键词到历史记录
 *
 * Authentication: 必需
 *
 * Request Body:
 * - keyword: 搜索关键词
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
 * DELETE /api/search/history/{keyword}
 *
 * 删除指定搜索关键词
 *
 * Authentication: 必需
 */
const deleteSearchKeyword = catchAsync(async (req, res) => {
  if (!req.user) {
    throw new AppError('请先登录', 401);
  }

  const { keyword } = req.params;

  searchService.deleteSearchKeyword(req.user.id, keyword);

  return successResponse(res, { success: true }, '删除搜索关键词成功');
});

/**
 * DELETE /api/search/history
 *
 * 清空搜索历史
 *
 * Authentication: 必需
 */
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
