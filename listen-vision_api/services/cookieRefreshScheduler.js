const db = require('../config/database');
const { logger } = require('../utils/logger');
const bilibiliService = require('./bilibiliService');

/**
 * Cookie刷新调度器
 *
 * 功能：
 * 1. 每日定时检查所有活跃的B站绑定
 * 2. 距离过期不足7天时触发刷新
 * 3. 记录刷新结果和失败原因
 */
class CookieRefreshScheduler {
  constructor() {
    this.isRunning = false;
    this.checkIntervalMs = 24 * 60 * 60 * 1000;
    this.refreshThresholdDays = 7;
    this.timer = null;
  }

  /**
   * 启动调度器
   */
  start() {
    if (this.isRunning) {
      logger.warn('[CookieRefreshScheduler] 调度器已在运行');
      return;
    }

    this.isRunning = true;
    logger.info('[CookieRefreshScheduler] 启动Cookie刷新调度器');

    this.checkAndRefreshAll();

    this.timer = setInterval(() => {
      this.checkAndRefreshAll();
    }, this.checkIntervalMs);
  }

  /**
   * 停止调度器
   */
  stop() {
    if (!this.isRunning) return;

    this.isRunning = false;
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }

    logger.info('[CookieRefreshScheduler] 已停止Cookie刷新调度器');
  }

  /**
   * 检查并刷新所有账号
   */
  async checkAndRefreshAll() {
    try {
      logger.info('[CookieRefreshScheduler] 开始检查所有B站绑定账号');

      const accounts = db.prepare(
        'SELECT * FROM bilibili_accounts WHERE is_active = 1'
      ).all();

      let refreshed = 0;
      let skipped = 0;
      let failed = 0;

      for (const account of accounts) {
        const result = await this.checkAndRefreshAccount(account);
        if (result === 'refreshed') refreshed++;
        else if (result === 'skipped') skipped++;
        else if (result === 'failed') failed++;
      }

      logger.info(
        '[CookieRefreshScheduler] 检查完成: 刷新%d, 跳过%d, 失败%d',
        refreshed, skipped, failed
      );
    } catch (error) {
      logger.error('[CookieRefreshScheduler] 检查异常: %s', error.message);
    }
  }

  /**
   * 检查单个账号是否需要刷新
   *
   * @param {Object} account - 账号信息
   * @returns {string} 'refreshed' | 'skipped' | 'failed'
   */
  async checkAndRefreshAccount(account) {
    try {
      if (!account.expires_at) {
        return 'skipped';
      }

      const expiresAt = new Date(account.expires_at);
      const now = new Date();
      const daysLeft = (expiresAt - now) / (1000 * 60 * 60 * 24);

      if (daysLeft > this.refreshThresholdDays) {
        return 'skipped';
      }

      const success = await bilibiliService.refreshCookie(account.user_id);

      if (success) {
        return 'refreshed';
      } else {
        if (daysLeft <= 0) {
          db.prepare(
            'UPDATE bilibili_accounts SET is_active = 0 WHERE id = ?'
          ).run(account.id);
          logger.warn(
            '[CookieRefreshScheduler] 账号已过期，已停用: userId=%d',
            account.user_id
          );
        }
        return 'failed';
      }
    } catch (error) {
      logger.error(
        '[CookieRefreshScheduler] 检查账号异常: %s',
        error.message
      );
      return 'failed';
    }
  }

  /**
   * 手动触发刷新指定用户
   *
   * @param {number} userId - 用户ID
   * @returns {boolean} 是否成功
   */
  async refreshUser(userId) {
    try {
      const account = db.prepare(
        'SELECT * FROM bilibili_accounts WHERE user_id = ? AND is_active = 1'
      ).get(userId);

      if (!account) {
        logger.warn('[CookieRefreshScheduler] 用户账号不存在或已停用: userId=%d', userId);
        return false;
      }

      const result = await this.checkAndRefreshAccount(account);
      return result === 'refreshed';
    } catch (error) {
      logger.error('[CookieRefreshScheduler] 手动刷新异常: %s', error.message);
      return false;
    }
  }
}

module.exports = new CookieRefreshScheduler();
