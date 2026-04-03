/**
 * HTTP 请求日志中间件
 *
 * 职责：记录所有 HTTP 请求的详细信息
 * 使用 Winston logger 进行日志记录
 */

const winston = require('winston');
const path = require('path');

// 日志格式
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
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

// HTTP 请求日志 logger
const httpLogger = winston.createLogger({
  level: 'http',
  format: logFormat,
  defaultMeta: { service: 'listen-vision-api' },
  transports: [
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/http.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 10
    })
  ]
});

// 开发环境输出到控制台
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

module.exports = { requestLogger, httpLogger };
