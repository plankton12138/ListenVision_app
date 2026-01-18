const playHistoryService = require('../services/playHistoryService');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 播放历史控制器
 * 处理播放历史相关请求
 */

/**
 * 记录播放
 */
const recordPlay = catchAsync(async (req, res) => {
  // 游客模式可能没有 user
  const userId = req.user ? req.user.id : null;
  const { bvid, title, artist, duration, coverUrl, progress } = req.body;

  if (!bvid) {
    throw new AppError('BVID不能为空', 400);
  }

  const metadata = { title, artist, duration, coverUrl };
  const record = playHistoryService.recordPlay(userId, bvid, metadata, progress || 0);

  return successResponse(res, record, '记录播放成功', 201);
});

/**
 * 获取播放历史
 */
const getHistory = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 50 } = req.query;

  const offset = (parseInt(page) - 1) * parseInt(limit);
  const history = playHistoryService.getHistory(userId, parseInt(limit), offset);

  return successResponse(res, history, '获取播放历史成功');
});

/**
 * 获取所有播放历史（不分页）
 */
const getAllHistory = catchAsync(async (req, res) => {
  const userId = req.user.id;

  const history = playHistoryService.getAllHistory(userId);

  return successResponse(res, history, '获取播放历史成功');
});

/**
 * 清空播放历史
 */
const clearHistory = catchAsync(async (req, res) => {
  const userId = req.user.id;

  playHistoryService.clearHistory(userId);

  return successResponse(res, { success: true }, '清空播放历史成功');
});

/**
 * 删除指定播放记录
 */
const removeHistoryItem = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { bvid } = req.params;

  playHistoryService.removeHistoryItem(userId, bvid);

  return successResponse(res, { success: true }, '删除播放记录成功');
});

/**
 * 按ID删除播放记录
 */
const removeHistoryById = catchAsync(async (req, res) => {
  const { id } = req.params;

  playHistoryService.removeHistoryById(parseInt(id));

  return successResponse(res, { success: true }, '删除播放记录成功');
});

/**
 * 获取播放历史统计
 */
const getHistoryStats = catchAsync(async (req, res) => {
  const userId = req.user.id;

  const stats = playHistoryService.getHistoryStats(userId);

  return successResponse(res, stats, '获取播放统计成功');
});

module.exports = {
  recordPlay,
  getHistory,
  getAllHistory,
  clearHistory,
  removeHistoryItem,
  removeHistoryById,
  getHistoryStats
};
