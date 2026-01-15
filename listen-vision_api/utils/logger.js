const winston = require('winston');
const path = require('path');

/**
 * Winston 日志系统
 *
 * 日志级别：
 * - error: 错误信息
 * - warn: 警告信息
 * - info: 一般信息
 * - http: HTTP 请求日志
 * - debug: 调试信息
 */

// 定义日志格式
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

// 控制台格式（开发环境）
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} [${level}]: ${message}`;
    if (Object.keys(meta).length > 0 && meta.stack) {
      msg += `\n${meta.stack}`;
    }
    return msg;
  })
);

// 创建 logger 实例
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  defaultMeta: { service: 'listen-vision-api' },
  transports: [
    // 错误日志文件
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    // 所有日志文件
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5
    })
  ]
});

// 开发环境添加控制台输出
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: consoleFormat
  }));
}

// 生产环境添加单独的 HTTP 日志
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.File({
    filename: path.join(__dirname, '../logs/http.log'),
    level: 'http',
    maxsize: 5242880,
    maxFiles: 10
  }));
}

/**
 * HTTP 请求日志中间件
 */
const httpLogger = winston.createLogger({
  level: 'http',
  format: logFormat,
  defaultMeta: { service: 'listen-vision-api' },
  transports: [
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/http.log'),
      maxsize: 5242880,
      maxFiles: 10
    })
  ]
});

// 开发环境也输出 HTTP 日志到控制台
if (process.env.NODE_ENV !== 'production') {
  httpLogger.add(new winston.transports.Console({
    format: consoleFormat
  }));
}

/**
 * Express 中间件：记录 HTTP 请求
 */
const requestLogger = (req, res, next) => {
  const startTime = Date.now();

  // 记录请求
  httpLogger.http('Incoming request', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });

  // 监听响应完成
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    httpLogger.http('Request completed', {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`
    });
  });

  next();
};

module.exports = {
  logger,
  httpLogger,
  requestLogger
};
