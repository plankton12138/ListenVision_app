/**
 * 下载路由
 *
 * Phase 3.3 - 下载管理 API 端点
 */

const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { successResponse } = require('../utils/response');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const downloadService = require('../services/downloadService');
const audioService = require('../services/audioService');

/**
 * POST /api/downloads
 *
 * 创建新的下载任务
 *
 * Authentication: 必需
 *
 * Request Body:
 * - bvid: 视频 ID（必填）
 *
 * Response:
 * - success: true
 * - data: 创建的任务对象
 */
const createTask = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { bvid } = req.body;

  if (!bvid || bvid.trim().length === 0) {
    throw new AppError('bvid 不能为空', 400);
  }

  // 验证 bvid 有效性（检查是否存在于元数据缓存）
  const metadata = audioService.getAudioMetadata(bvid);
  if (!metadata) {
    throw new AppError('视频不存在或元数据未缓存', 404);
  }

  // 创建下载任务
  const task = downloadService.createDownloadTask(userId, bvid);

  return successResponse(res, task, '创建下载任务成功', 201);
});

/**
 * GET /api/downloads
 *
 * 获取当前用户的所有下载任务
 *
 * Authentication: 必需
 *
 * Query Parameters:
 * - status: 可选，筛选任务状态（pending, downloading, paused, completed, failed）
 *
 * Response:
 * - success: true
 * - data: 任务列表
 */
const getUserTasks = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { status } = req.query;

  const allTasks = downloadService.getUserTasks(userId);

  // 根据状态筛选
  const filteredTasks = status
    ? allTasks.filter(t => t.status === status)
    : allTasks;

  return successResponse(res, filteredTasks, '获取下载任务成功');
});

/**
 * GET /api/downloads/:id
 *
 * 获取指定下载任务的详细信息
 *
 * Authentication: 必需
 *
 * Response:
 * - success: true
 * - data: 任务详情
 */
const getTaskById = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  const tasks = downloadService.getUserTasks(userId);
  const task = tasks.find(t => t.id === parseInt(id));

  if (!task) {
    throw new AppError('任务不存在', 404);
  }

  return successResponse(res, task, '获取任务详情成功');
});

/**
 * PUT /api/downloads/:id/pause
 *
 * 暂停下载任务
 *
 * Authentication: 必需
 *
 * Response:
 * - success: true
 * - message: 暂停成功
 */
const pauseTask = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  const tasks = downloadService.getUserTasks(userId);
  const task = tasks.find(t => t.id === parseInt(id));

  if (!task) {
    throw new AppError('任务不存在', 404);
  }

  if (task.status !== 'downloading') {
    throw new AppError('只有下载中的任务才能暂停', 400);
  }

  downloadService.pauseDownloadTask(task.id);

  return successResponse(res, { success: true }, '暂停下载成功');
});

/**
 * PUT /api/downloads/:id/resume
 *
 * 恢复下载任务
 *
 * Authentication: 必需
 *
 * Response:
 * - success: true
 * - message: 恢复成功
 */
const resumeTask = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  const tasks = downloadService.getUserTasks(userId);
  const task = tasks.find(t => t.id === parseInt(id));

  if (!task) {
    throw new AppError('任务不存在', 404);
  }

  if (task.status !== 'paused') {
    throw new AppError('只有暂停的任务才能恢复', 400);
  }

  downloadService.resumeDownloadTask(task.id);

  return successResponse(res, { success: true }, '恢复下载成功');
});

/**
 * PUT /api/downloads/:id/complete
 *
 * 标记任务为已完成
 *
 * Authentication: 必需
 *
 * Response:
 * - success: true
 * - message: 完成成功
 */
const completeTask = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  const tasks = downloadService.getUserTasks(userId);
  const task = tasks.find(t => t.id === parseInt(id));

  if (!task) {
    throw new AppError('任务不存在', 404);
  }

  downloadService.completeDownloadTask(task.id);

  return successResponse(res, { success: true }, '标记任务完成成功');
});

/**
 * DELETE /api/downloads/:id
 *
 * 删除下载任务
 *
 * Authentication: 必需
 *
 * Response:
 * - success: true
 * - message: 删除成功
 */
const deleteTask = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  downloadService.deleteDownloadTask(parseInt(id), userId);

  return successResponse(res, { success: true }, '删除任务成功');
});

/**
 * DELETE /api/downloads/completed
 *
 * 清空所有已完成的任务
 *
 * Authentication: 必需
 *
 * Response:
 * - success: true
 * - message: 清空成功
 */
const clearCompleted = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const count = downloadService.clearCompletedTasks(userId);

  return successResponse(res, { clearedCount: count }, `清空了 ${count} 个已完成任务`);
});

/**
 * PUT /api/downloads/:id/progress
 *
 * 更新下载进度
 *
 * Authentication: 必需
 *
 * Request Body:
 * - progress: 进度百分比 (0-100)
 * - downloadedSize: 已下载大小（字节，可选）
 *
 * Response:
 * - success: true
 * - message: 更新成功
 */
const updateProgress = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;
  const { progress, downloadedSize } = req.body;

  if (typeof progress !== 'number' || progress < 0 || progress > 100) {
    throw new AppError('进度值必须在 0-100 之间', 400);
  }

  const tasks = downloadService.getUserTasks(userId);
  const task = tasks.find(t => t.id === parseInt(id));

  if (!task) {
    throw new AppError('任务不存在', 404);
  }

  if (task.status !== 'pending' && task.status !== 'downloading' && task.status !== 'paused') {
    throw new AppError('只有未开始或进行中或暂停的任务才能更新进度', 400);
  }

  downloadService.updateDownloadProgress(task.id, progress, downloadedSize || null);

  return successResponse(res, { success: true }, '更新下载进度成功');
});

// 注册路由
router.post('/', authMiddleware, createTask);
router.get('/', authMiddleware, getUserTasks);
router.get('/:id', authMiddleware, getTaskById);
router.put('/:id/pause', authMiddleware, pauseTask);
router.put('/:id/resume', authMiddleware, resumeTask);
router.put('/:id/complete', authMiddleware, completeTask);
router.put('/:id/progress', authMiddleware, updateProgress);
router.delete('/:id', authMiddleware, deleteTask);
router.delete('/completed', authMiddleware, clearCompleted);

module.exports = router;
