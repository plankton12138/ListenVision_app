/**
 * 下载任务状态存储服务
 *
 * 功能：
 * 1. 存储下载任务状态（支持客户端轮询恢复）
 * 2. 超时保护（防止长时间挂起的请求）
 * 3. 双重验证支持（文件校验和）
 * 4. 客户端心跳检测
 *
 * @module services/downloadTaskStore
 */

const { logger } = require('../utils/logger');

/**
 * 任务状态枚举
 */
const TaskStatus = {
  PENDING: 'pending',       // 等待开始
  DOWNLOADING: 'downloading', // 下载音频中
  CONVERTING: 'converting',  // 转换中
  VERIFYING: 'verifying',    // 等待客户端验证
  COMPLETED: 'completed',    // 已完成
  FAILED: 'failed',          // 失败
  CANCELED: 'canceled',      // 已取消
  TIMEOUT: 'timeout',        // 超时
};

/**
 * 下载任务状态存储
 */
class DownloadTaskStore {
  constructor() {
    // Map<requestId, Task>
    this.tasks = new Map();
    // 清理定时器
    this.cleanupInterval = null;
    // 任务过期时间（毫秒）
    this.taskExpiryMs = 3600000; // 1小时
    // 心跳超时（毫秒）- 客户端超过这个时间没有心跳视为离线
    this.heartbeatTimeoutMs = 60000; // 1分钟
    // 下载超时（毫秒）- 整个下载过程的最长时间
    this.downloadTimeoutMs = 300000; // 5分钟

    this.startCleanupTimer();
  }

  /**
   * 启动清理定时器
   */
  startCleanupTimer() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }

    // 每30秒清理一次过期任务
    this.cleanupInterval = setInterval(() => {
      this.cleanupExpiredTasks();
    }, 30000);

    logger.info('DownloadTaskStore 清理定时器已启动');
  }

  /**
   * 清理过期任务
   */
  cleanupExpiredTasks() {
    const now = Date.now();
    let cleanedCount = 0;

    for (const [requestId, task] of this.tasks.entries()) {
      // 检查是否过期
      if (task.expiresAt && now > task.expiresAt) {
        this.tasks.delete(requestId);
        cleanedCount++;
        logger.debug('DownloadTaskStore 清理过期任务', { requestId, status: task.status });
        continue;
      }

      // 检查下载超时（对于未完成的任务）
      if (task.createdAt && now - task.createdAt > this.downloadTimeoutMs) {
        if (task.status !== TaskStatus.COMPLETED &&
            task.status !== TaskStatus.FAILED &&
            task.status !== TaskStatus.CANCELED) {
          task.status = TaskStatus.TIMEOUT;
          task.error = '下载超时：服务器处理时间过长';
          task.completedAt = now;
          logger.warn('DownloadTaskStore 任务超时', { requestId, bvid: task.bvid });
        }
      }

      // 检查客户端心跳（对于未完成的任务）
      if (task.lastHeartbeat && now - task.lastHeartbeat > this.heartbeatTimeoutMs) {
        task.clientConnected = false;
        logger.debug('DownloadTaskStore 客户端离线', { requestId, lastHeartbeat: task.lastHeartbeat });
      }
    }

    if (cleanedCount > 0) {
      logger.info('DownloadTaskStore 清理完成', { cleanedCount, remainingTasks: this.tasks.size });
    }
  }

  /**
   * 生成唯一请求ID
   */
  generateRequestId(bvid) {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 9);
    return `${bvid}_${timestamp}_${random}`;
  }

  /**
   * 创建下载任务
   */
  createTask(bvid, format = 'mp3', options = {}) {
    const requestId = this.generateRequestId(bvid);
    const now = Date.now();

    const task = {
      // 基础信息
      requestId,
      bvid,
      format,
      status: TaskStatus.PENDING,
      createdAt: now,
      expiresAt: now + this.taskExpiryMs,
      lastUpdate: now,
      lastHeartbeat: now,
      clientConnected: true,

      // 进度信息
      progress: 0,
      stage: 'pending',

      // 文件信息（完成后填充）
      fileUrl: null,
      fileName: null,
      fileSize: null,
      contentType: null,
      checksum: null,

      // 错误信息
      error: null,
      failedAt: null,

      // 验证信息
      verified: false,
      confirmedAt: null,

      // 额外选项
      options,
    };

    this.tasks.set(requestId, task);
    logger.info('DownloadTaskStore 创建任务', { requestId, bvid, format });

    return task;
  }

  /**
   * 获取任务
   */
  getTask(requestId) {
    return this.tasks.get(requestId);
  }

  /**
   * 通过 BVID 获取任务（返回最新的）
   */
  getTaskByBvid(bvid) {
    let latestTask = null;
    let latestTime = 0;

    for (const task of this.tasks.values()) {
      if (task.bvid === bvid && task.createdAt > latestTime) {
        latestTask = task;
        latestTime = task.createdAt;
      }
    }

    return latestTask;
  }

  /**
   * 更新任务进度
   */
  updateProgress(requestId, progress, stage, message) {
    const task = this.tasks.get(requestId);
    if (!task) {
      logger.warn('DownloadTaskStore 更新进度失败：任务不存在', { requestId });
      return false;
    }

    task.progress = progress;
    task.stage = stage;
    task.lastUpdate = Date.now();
    task.message = message;

    return true;
  }

  /**
   * 更新任务状态
   */
  updateStatus(requestId, status, error = null) {
    const task = this.tasks.get(requestId);
    if (!task) {
      logger.warn('DownloadTaskStore 更新状态失败：任务不存在', { requestId });
      return false;
    }

    task.status = status;
    task.lastUpdate = Date.now();

    if (error) {
      task.error = error;
    }

    if (status === TaskStatus.COMPLETED) {
      task.completedAt = Date.now();
      task.expiresAt = Date.now() + 1800000; // 完成后30分钟过期
    } else if (status === TaskStatus.FAILED || status === TaskStatus.CANCELED) {
      task.completedAt = Date.now();
      task.expiresAt = Date.now() + 300000; // 失败后5分钟过期
    }

    return true;
  }

  /**
   * 标记任务完成，等待验证
   */
  markCompleted(requestId, fileInfo) {
    const task = this.tasks.get(requestId);
    if (!task) {
      logger.warn('DownloadTaskStore 标记完成失败：任务不存在', { requestId });
      return false;
    }

    task.status = TaskStatus.VERIFYING;
    task.progress = 95;
    task.stage = 'verifying';

    // 文件信息
    task.fileUrl = fileInfo.fileUrl || null;
    task.fileName = fileInfo.fileName || null;
    task.fileSize = fileInfo.fileSize || null;
    task.contentType = fileInfo.contentType || null;
    task.checksum = fileInfo.checksum || null;

    task.lastUpdate = Date.now();

    logger.info('DownloadTaskStore 任务完成待验证', {
      requestId,
      fileName: task.fileName,
      fileSize: task.fileSize,
      checksum: task.checksum
    });

    return true;
  }

  /**
   * 客户端确认下载完成
   */
  confirmDownload(requestId, actualChecksum = null) {
    const task = this.tasks.get(requestId);
    if (!task) {
      logger.warn('DownloadTaskStore 确认失败：任务不存在', { requestId });
      return { success: false, error: '任务不存在' };
    }

    // 如果提供了校验和，验证是否匹配
    if (task.checksum && actualChecksum && task.checksum !== actualChecksum) {
      logger.error('DownloadTaskStore 校验失败', {
        requestId,
        expected: task.checksum,
        actual: actualChecksum
      });
      return {
        success: false,
        error: '文件校验失败',
        expectedChecksum: task.checksum,
        actualChecksum
      };
    }

    task.status = TaskStatus.COMPLETED;
    task.verified = true;
    task.confirmedAt = Date.now();
    task.progress = 100;
    task.expiresAt = Date.now() + 1800000; // 确认后保留30分钟

    logger.info('DownloadTaskStore 任务已确认', { requestId });

    return { success: true, task };
  }

  /**
   * 客户端心跳
   */
  heartbeat(requestId) {
    const task = this.tasks.get(requestId);
    if (!task) {
      return false;
    }

    task.lastHeartbeat = Date.now();
    task.clientConnected = true;

    return true;
  }

  /**
   * 取消任务
   */
  cancelTask(requestId) {
    const task = this.tasks.get(requestId);
    if (!task) {
      return { success: false, error: '任务不存在' };
    }

    // 已完成的任务不能取消
    if (task.status === TaskStatus.COMPLETED) {
      return { success: false, error: '任务已完成，无法取消' };
    }

    task.status = TaskStatus.CANCELED;
    task.completedAt = Date.now();
    task.expiresAt = Date.now() + 300000;

    logger.info('DownloadTaskStore 任务已取消', { requestId });

    return { success: true, task };
  }

  /**
   * 删除任务
   */
  deleteTask(requestId) {
    const deleted = this.tasks.delete(requestId);
    if (deleted) {
      logger.info('DownloadTaskStore 任务已删除', { requestId });
    }
    return deleted;
  }

  /**
   * 获取任务统计
   */
  getStats() {
    const stats = {
      total: this.tasks.size,
      byStatus: {},
      clientConnected: 0,
      pending: 0,
    };

    for (const task of this.tasks.values()) {
      // 按状态统计
      stats.byStatus[task.status] = (stats.byStatus[task.status] || 0) + 1;

      // 客户端连接数
      if (task.clientConnected && task.status !== TaskStatus.COMPLETED) {
        stats.clientConnected++;
      }

      // 等待中的任务
      if (task.status === TaskStatus.PENDING) {
        stats.pending++;
      }
    }

    return stats;
  }

  /**
   * 清空所有任务（用于测试）
   */
  clear() {
    this.tasks.clear();
    logger.info('DownloadTaskStore 已清空所有任务');
  }

  /**
   * 关闭存储
   */
  shutdown() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    logger.info('DownloadTaskStore 已关闭');
  }
}

// 导出单例
const downloadTaskStore = new DownloadTaskStore();

module.exports = {
  downloadTaskStore,
  DownloadTaskStore,
  TaskStatus,
};
