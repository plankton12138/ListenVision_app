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

  // 记录错误日志
  console.error('Error:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    body: req.body,
    params: req.params,
    query: req.query
  });

  // MySQL 错误处理
  if (err.code === 'ER_DUP_ENTRY') {
    const message = '数据已存在';
    error = new AppError(message, 409);
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    const message = '关联数据不存在';
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
