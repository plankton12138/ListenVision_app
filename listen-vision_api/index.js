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
}

// ========== 错误处理 ==========

// 404 处理
app.use(notFound);

// 统一错误处理
app.use(errorHandler);

// ========== 启动服务器 ==========

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log('\n========================================');
  console.log('  ListenVision API Server');
  console.log('========================================');
  console.log(`  Status: Running`);
  console.log(`  Port: ${PORT}`);
  console.log(`  Env: ${process.env.NODE_ENV || 'development'}`);
  console.log(`  Time: ${new Date().toLocaleString('zh-CN')}`);
  console.log('========================================');
  console.log(`  API Docs: http://localhost:${PORT}/api-docs`);
  console.log(`  Health: http://localhost:${PORT}/health`);
  console.log('========================================\n');
  logger.info(`Server started on port ${PORT}`);
});

// ========== 优雅退出 ==========

const gracefulShutdown = (signal) => {
  logger.info(`${signal} received, shutting down server...`);
  console.log(`\n⚠️  ${signal} 信号接收，正在关闭服务器...`);

  server.close(() => {
    const db = require('./config/database');
    if (db && typeof db.close === 'function') {
      db.close();
      logger.info('Database connection closed');
    }
    logger.info('Server shut down successfully');
    console.log('✅ 服务器已关闭');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Server shutdown timeout, forcing exit');
    console.error('❌ 服务器关闭超时，强制退出');
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
