/**
 * 统一错误处理中间件
 *
 * 捕获所有错误并返回统一的响应格式
 *
 * 使用方法：
 * app.use(errorHandler);
 *
 * 在路由中抛出错误：
 * throw new AppError('用户不存在', 404);
 */

const { logger } = require('./../utils/logger');

/**
 * 敏感字段列表（日志脱敏用）
 */
const SENSITIVE_FIELDS = [
  'password', 'passwd', 'pwd', 'token', 'accessToken', 'refreshToken',
  'secret', 'apiKey', 'sessdata', 'bili_jct', 'cookie', 'authorization'
];

/**
 * 对象递归脱敏（处理嵌套对象）
 */
const redactObject = (obj, depth = 0) => {
  if (!obj || typeof obj !== 'object' || depth > 5) {
    return obj;
  }

  const redacted = Array.isArray(obj) ? [] : {};

  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();

    // 检查是否是敏感字段
    const isSensitive = SENSITIVE_FIELDS.some(field =>
      lowerKey.includes(field.toLowerCase())
    );

    if (isSensitive && typeof value === 'string') {
      // 保留前3个字符，其余用***替换
      redacted[key] = value.length > 3
        ? value.substring(0, 3) + '***'
        : '***';
    } else if (typeof value === 'object' && value !== null) {
      redacted[key] = redactObject(value, depth + 1);
    } else {
      redacted[key] = value;
    }
  }

  return redacted;
};

class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true; // 标记为操作错误（可预期）
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * 错误处理中间件
 */
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // 使用 Winston logger 记录错误（已脱敏）
  logger.error('Request Error', {
    message: err.message,
    url: req.originalUrl,
    method: req.method,
    // 脱敏处理敏感字段
    body: redactObject(req.body),
    params: req.params,
    query: redactObject(req.query),
    // 仅在开发环境记录堆栈
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });

  // SQLite 错误处理（better-sqlite3）
  // SQLite 错误码: https://www.sqlite.org/rescode.html
  if (err.code === 'SQLITE_CONSTRAINT' || err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
    const message = '数据已存在';
    error = new AppError(message, 409);
  }

  if (err.code === 'SQLITE_CONSTRAINT_FOREIGNKEY') {
    const message = '关联数据不存在';
    error = new AppError(message, 400);
  }

  // 通用约束错误（兼容其他 SQLITE_CONSTRAINT_* 变体）
  if (err.code && err.code.startsWith('SQLITE_CONSTRAINT') && !error.statusCode) {
    const message = '数据约束错误';
    error = new AppError(message, 400);
  }

  // JWT 错误处理
  if (err.name === 'JsonWebTokenError') {
    const message = 'Token 无效';
    error = new AppError(message, 401);
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token 已过期';
    error = new AppError(message, 401);
  }

  // 验证错误
  if (err.name === 'ValidationError') {
    const message = err.message || '参数验证失败';
    error = new AppError(message, 400);
  }

  // 默认错误响应
  const statusCode = error.statusCode || 500;
  const message = error.message || '服务器内部错误';

  // 开发环境返回堆栈信息
  const response = {
    success: false,
    error: message
  };

  if (process.env.NODE_ENV === 'development') {
    response.stack = err.stack;
  }

  res.status(statusCode).json(response);
};

/**
 * 404 处理中间件
 */
const notFound = (req, res, next) => {
  const error = new AppError(`未找到路由: ${req.originalUrl}`, 404);
  next(error);
};

/**
 * 异步错误捕获包装器
 * 用于 async/await 路由的错误处理
 *
 * 使用示例：
 * router.get('/users', catchAsync(async (req, res) => {
 *   const users = await User.findAll();
 *   res.json(users);
 * }));
 */
const catchAsync = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = {
  AppError,
  errorHandler,
  notFound,
  catchAsync
};
