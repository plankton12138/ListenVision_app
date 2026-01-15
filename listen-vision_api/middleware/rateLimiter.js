const rateLimit = require('express-rate-limit');

/**
 * 请求限流中间件
 * 防止 API 滥用和 DDoS 攻击
 */

/**
 * 通用限流配置
 * 限制每个 IP 每小时最多 100 个请求
 */
const generalLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 小时
  max: 100,
  message: {
    success: false,
    error: '请求过于频繁，请稍后再试'
  },
  standardHeaders: true, // 返回标准的 `RateLimit-*` 头
  legacyHeaders: false, // 禁用 `X-RateLimit-*` 头
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: '请求过于频繁，请稍后再试',
      retryAfter: '1小时'
    });
  }
});

/**
 * 严格限流配置（用于敏感操作）
 * 限制每个 IP 每小时最多 10 个请求
 * 适用于：登录、注册、密码重置等
 */
const strictLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 小时
  max: 10,
  message: {
    success: false,
    error: '操作过于频繁，请 1 小时后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false, // 成功的请求也计入限制
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: '操作过于频繁，请 1 小时后再试',
      retryAfter: '1小时'
    });
  }
});

/**
 * 登录限流配置
 * 限制每个 IP 每 15 分钟最多 5 次登录尝试
 */
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分钟
  max: 5,
  message: {
    success: false,
    error: '登录尝试次数过多，请 15 分钟后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: '登录尝试次数过多，请 15 分钟后再试',
      retryAfter: '15分钟'
    });
  }
});

/**
 * 注册限流配置
 * 限制每个 IP 每天最多 3 次注册
 */
const registerLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 小时
  max: 3,
  message: {
    success: false,
    error: '注册次数过多，请明天再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: '注册次数过多，请明天再试',
      retryAfter: '24小时'
    });
  }
});

/**
 * 发送验证码限流配置
 * 限制每个 IP 每 10 分钟最多 3 次请求
 */
const sendCodeLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 分钟
  max: 3,
  message: {
    success: false,
    error: '验证码发送过于频繁，请 10 分钟后再试'
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: '验证码发送过于频繁，请 10 分钟后再试',
      retryAfter: '10分钟'
    });
  }
});

/**
 * 创建自定义限流器
 * @param {Object} options - 限流配置选项
 * @returns {Function} Express 中间件
 */
const createLimiter = (options) => {
  return rateLimit({
    windowMs: options.windowMs || 60 * 60 * 1000,
    max: options.max || 100,
    message: options.message || '请求过于频繁',
    standardHeaders: true,
    legacyHeaders: false,
    handler: options.handler || ((req, res) => {
      res.status(429).json({
        success: false,
        error: options.message || '请求过于频繁'
      });
    })
  });
};

module.exports = {
  generalLimiter,
  strictLimiter,
  loginLimiter,
  registerLimiter,
  sendCodeLimiter,
  createLimiter
};
