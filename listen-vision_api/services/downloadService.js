/**
 * 下载服务
 *
 * Phase 3.3 - 下载任务管理系统
 *
 * 功能：
 * 1. 创建下载任务
 * 2. 查询下载进度
 * 3. 暂停/恢复/取消下载
 * 4. 断点续传支持
 */

const db = require('../config/database');

// 预编译语句（模块初始化时编译，提高性能）
const stmt = {
  // 创建下载任务
  createTask: db.prepare(`
    INSERT INTO download_tasks (user_id, bvid, status, progress, file_size, downloaded_size, created_at, updated_at)
    VALUES (?, ?, 'pending', 0, NULL, 0, datetime('now'), datetime('now'))
  `),

  // 查询用户的所有任务
  getUserTasks: db.prepare(`
    SELECT id, bvid, status, progress, file_size, downloaded_size, error_message, created_at, updated_at
    FROM download_tasks
    WHERE user_id = ?
    ORDER BY created_at DESC
  `),

  // 根据 ID 获取任务
  getTaskById: db.prepare(`
    SELECT id, user_id, bvid, status, progress, file_size, downloaded_size, error_message, created_at, updated_at
    FROM download_tasks
    WHERE id = ?
  `),

  // 更新任务进度
  updateProgress: db.prepare(`
    UPDATE download_tasks
    SET progress = ?, downloaded_size = ?, status = 'downloading', updated_at = datetime('now')
    WHERE id = ? AND status IN ('pending', 'downloading', 'paused')
  `),

  // 暂停任务
  pauseTask: db.prepare(`
    UPDATE download_tasks
    SET status = 'paused', updated_at = datetime('now')
    WHERE id = ? AND status = 'downloading'
  `),

  // 恢复任务
  resumeTask: db.prepare(`
    UPDATE download_tasks
    SET status = 'downloading', updated_at = datetime('now')
    WHERE id = ? AND status = 'paused'
  `),

  // 完成任务
  completeTask: db.prepare(`
    UPDATE download_tasks
    SET status = 'completed', progress = 100, updated_at = datetime('now')
    WHERE id = ? AND status IN ('downloading', 'paused')
  `),

  // 任务失败
  failTask: db.prepare(`
    UPDATE download_tasks
    SET status = 'failed', error_message = ?, updated_at = datetime('now')
    WHERE id = ? AND status IN ('pending', 'downloading', 'paused')
  `),

  // 删除任务
  deleteTask: db.prepare(`
    DELETE FROM download_tasks
    WHERE id = ? AND user_id = ?
  `),

  // 清空已完成任务
  clearCompleted: db.prepare(`
    DELETE FROM download_tasks
    WHERE user_id = ? AND status = 'completed'
  `),
};

/**
 * 创建下载任务
 *
 * @param {number} userId - 用户ID
 * @param {string} bvid - 视频 ID
 * @returns {Object} 创建的任务对象
 */
const createDownloadTask = (userId, bvid) => {
  try {
    const info = stmt.createTask.run(userId, bvid);
    const taskId = info.lastInsertRowid;

    // 获取创建的任务
    const task = stmt.getTaskById.get(taskId);
    return task;
  } catch (error) {
    console.error('创建下载任务失败:', error);
    throw new Error(`创建下载任务失败: ${error.message}`);
  }
};

/**
 * 获取用户的所有下载任务
 *
 * @param {number} userId - 用户ID
 * @returns {Array} 任务列表
 */
const getUserTasks = (userId) => {
  try {
    const tasks = stmt.getUserTasks.all(userId);
    return tasks;
  } catch (error) {
    console.error('获取下载任务失败:', error);
    throw new Error(`获取下载任务失败: ${error.message}`);
  }
};

/**
 * 更新下载进度
 *
 * @param {number} taskId - 任务 ID
 * @param {number} progress - 进度百分比 (0-100)
 * @param {number} downloadedSize - 已下载大小（字节）
 * @returns {boolean} 是否更新成功
 */
const updateDownloadProgress = (taskId, progress, downloadedSize) => {
  try {
    const result = stmt.updateProgress.run(progress, downloadedSize, taskId);
    return result.changes > 0;
  } catch (error) {
    console.error('更新下载进度失败:', error);
    throw new Error(`更新下载进度失败: ${error.message}`);
  }
};

/**
 * 暂停下载任务
 *
 * @param {number} taskId - 任务 ID
 * @returns {boolean} 是否暂停成功
 */
const pauseDownloadTask = (taskId) => {
  try {
    const result = stmt.pauseTask.run(taskId);
    return result.changes > 0;
  } catch (error) {
    console.error('暂停下载任务失败:', error);
    throw new Error(`暂停下载任务失败: ${error.message}`);
  }
};

/**
 * 恢复下载任务
 *
 * @param {number} taskId - 任务 ID
 * @returns {boolean} 是否恢复成功
 */
const resumeDownloadTask = (taskId) => {
  try {
    const result = stmt.resumeTask.run(taskId);
    return result.changes > 0;
  } catch (error) {
    console.error('恢复下载任务失败:', error);
    throw new Error(`恢复下载任务失败: ${error.message}`);
  }
};

/**
 * 完成下载任务
 *
 * @param {number} taskId - 任务 ID
 * @returns {boolean} 是否完成成功
 */
const completeDownloadTask = (taskId) => {
  try {
    const result = stmt.completeTask.run(taskId);
    return result.changes > 0;
  } catch (error) {
    console.error('完成下载任务失败:', error);
    throw new Error(`完成下载任务失败: ${error.message}`);
  }
};

/**
 * 标记任务失败
 *
 * @param {number} taskId - 任务 ID
 * @param {string} errorMessage - 错误信息
 * @returns {boolean} 是否标记成功
 */
const failDownloadTask = (taskId, errorMessage) => {
  try {
    const result = stmt.failTask.run(errorMessage, taskId);
    return result.changes > 0;
  } catch (error) {
    console.error('标记任务失败出错:', error);
    throw new Error(`标记任务失败出错: ${error.message}`);
  }
};

/**
 * 删除下载任务
 *
 * @param {number} taskId - 任务 ID
 * @param {number} userId - 用户ID（安全检查）
 * @returns {boolean} 是否删除成功
 */
const deleteDownloadTask = (taskId, userId) => {
  try {
    // 验证任务所有权
    const task = stmt.getTaskById.get(taskId);
    if (!task || task.user_id !== userId) {
      throw new Error('无权限删除此任务');
    }

    const result = stmt.deleteTask.run(taskId, userId);
    return result.changes > 0;
  } catch (error) {
    console.error('删除下载任务失败:', error);
    throw new Error(`删除下载任务失败: ${error.message}`);
  }
};

/**
 * 清空已完成的任务
 *
 * @param {number} userId - 用户 ID
 * @returns {number} 删除的任务数量
 */
const clearCompletedTasks = (userId) => {
  try {
    const result = stmt.clearCompleted.run(userId);
    return result.changes;
  } catch (error) {
    console.error('清空已完成任务失败:', error);
    throw new Error(`清空已完成任务失败: ${error.message}`);
  }
};

module.exports = {
  createDownloadTask,
  getUserTasks,
  updateDownloadProgress,
  pauseDownloadTask,
  resumeDownloadTask,
  completeDownloadTask,
  failDownloadTask,
  deleteDownloadTask,
  clearCompletedTasks,
};
