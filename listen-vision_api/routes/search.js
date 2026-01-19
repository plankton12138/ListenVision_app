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

// 注册路由
router.get('/local', localSearch);
router.get('/suggestions', searchSuggestions);
router.get('/trending', trendingKeywords);
router.get('/history', authMiddleware, getSearchHistory);

module.exports = router;
