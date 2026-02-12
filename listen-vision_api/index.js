// 加载环境变量（明确指定 .env 文件路径）
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { requestLogger } = require('./middleware/logger');
const { logger } = require('./utils/logger');
const { generalLimiter } = require('./middleware/rateLimiter');
const swaggerSpecs = require('./config/swagger');

// ========== 环境变量校验 ==========
const requiredEnvVars = ['JWT_SECRET', 'DATABASE_PATH'];
const missingEnvVars = requiredEnvVars.filter(key => !process.env[key]);

if (missingEnvVars.length > 0) {
  logger.error('❌ 缺少必需的环境变量:');
  missingEnvVars.forEach(key => logger.error(`   - ${key}`));
  logger.error('\n请在 .env 文件中配置上述变量，参考 .env.example');
  process.exit(1);
}

logger.info('✅ 环境变量校验通过');

// 创建 Express 应用
const app = express();

// ========== 中间件配置 ==========

// CORS 跨域
app.use(cors());

// JSON 解析
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// HTTP 请求日志
app.use(requestLogger);

// 通用限流（所有API）
app.use('/api/', generalLimiter);

// ========== 路由配置 ==========

// 健康检查（不限流）
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'ListenVision API is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API 文档 (Swagger)
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'ListenVision API 文档',
  swaggerOptions: {
    persistAuthorization: true,
    docExpansion: 'none',
    filter: true,
    showRequestDuration: true
  }
}));

// ========== API 路由配置 ==========

// v1 API 路由（唯一版本）
try {
  const v1Router = require('./routes/v1');
  app.use('/api/v1', v1Router);
  logger.info('v1 API routes registered (/api/v1/*)');
} catch (e) {
  logger.error('Failed to load v1 routes:', e.message);
  logger.error('Stack trace:', e.stack);
}

// ========== 错误处理 ==========

// 404 处理
app.use(notFound);

// 统一错误处理
app.use(errorHandler);

// ========== 启动服务器 ==========

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  logger.info('========================================');
  logger.info('  ListenVision API Server');
  logger.info('========================================');
  logger.info(`  Status: Running`);
  logger.info(`  Port: ${PORT}`);
  logger.info(`  Env: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`  Time: ${new Date().toLocaleString('zh-CN')}`);
  logger.info('========================================');
  logger.info(`  API Docs: http://localhost:${PORT}/api-docs`);
  logger.info(`  Health: http://localhost:${PORT}/health`);
  logger.info('========================================');
  logger.info(`Server started on port ${PORT}`);

  const cookieRefreshScheduler = require('./services/cookieRefreshScheduler');
  cookieRefreshScheduler.start();
});

// ========== 优雅退出 ==========

const gracefulShutdown = (signal) => {
  logger.info(`${signal} received, shutting down server...`);
  logger.warn(`⚠️  ${signal} 信号接收，正在关闭服务器...`);

  server.close(() => {
    const db = require('./config/database');
    if (db && typeof db.close === 'function') {
      db.close();
      logger.info('Database connection closed');
    }
    logger.info('Server shut down successfully');
    logger.info('✅ 服务器已关闭');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Server shutdown timeout, forcing exit');
    logger.error('❌ 服务器关闭超时，强制退出');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  logger.error('未捕获的异常:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('未处理的 Promise 拒绝:', reason);
});

module.exports = app;
