// 加载环境变量（明确指定 .env 文件路径）
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { requestLogger, logger } = require('./utils/logger');
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

// 版本路由（优先匹配，避免与旧路由冲突）
try {
  const v1Router = require('./routes/v1');
  app.use('/api/v1', v1Router);
  logger.info('v1 API routes registered (/api/v1/*)');
} catch (e) {
  logger.error('Failed to load v1 routes:', e.message);
}

// 兼容旧路由（无版本前缀，逐步废弃）
// 请求日志记录
app.use('/api', (req, res, next) => {
  logger.debug(`${req.method} ${req.originalUrl}`);

  // 如果请求没有版本前缀，添加警告头
  if (!req.path.startsWith('/api/v') && req.path !== '/api-docs') {
    res.setHeader('X-API-Deprecation', 'true');
    res.setHeader('X-API-Migration', 'Please use /api/v1/ endpoints instead');
  }
  next();
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/favorites', require('./routes/favorites'));

try {
  const bilibiliRouter = require('./routes/bilibili');
  app.use('/api/bilibili', bilibiliRouter);
  logger.info('Bilibili routes registered, stack length:', bilibiliRouter.stack.length);
  bilibiliRouter.stack.forEach((layer, i) => {
    if (layer.route) {
      logger.debug(`  - Route ${i}: ${Object.keys(layer.route.methods).join(',').toUpperCase()} ${layer.route.path}`);
    }
  });
} catch (e) {
  logger.error('Failed to load bilibili routes:', e.message);
}

try {
  const audioRouter = require('./routes/audio');
  app.use('/api/audio', audioRouter);
  logger.info('Audio routes registered');
} catch (e) {
  logger.error('Failed to load audio routes:', e.message);
}

// ========== Phase 2: 歌单、历史、推荐路由 ==========

try {
  const playlistsRouter = require('./routes/playlists');
  app.use('/api/playlists', playlistsRouter);
  logger.info('Playlists routes registered');
} catch (e) {
  logger.error('Failed to load playlists routes:', e.message);
}

try {
  const historyRouter = require('./routes/history');
  app.use('/api/history', historyRouter);
  logger.info('History routes registered');
} catch (e) {
  logger.error('Failed to load history routes:', e.message);
}

try {
  const recommendationsRouter = require('./routes/recommendations');
  app.use('/api/recommendations', recommendationsRouter);
  logger.info('Recommendations routes registered');
} catch (e) {
  logger.error('Failed to load recommendations routes:', e.message);
}

// ========== Phase 3: 搜索、推荐与下载路由 ==========

try {
  const searchRouter = require('./routes/search');
  app.use('/api/search', searchRouter);
  logger.info('Search routes registered');
} catch (e) {
  logger.error('Failed to load search routes:', e.message);
}

// ========== 错误处理 ==========

// 404 处理
app.use(notFound);

// 统一错误处理
app.use(errorHandler);

// ========== 启动服务器 ==========

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  // 服务器启动信息（保留 console.log 用于启动时可视化）
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
  // 同时记录到日志文件
  logger.info(`Server started on port ${PORT}`);
});

// ========== 优雅退出 ==========

const gracefulShutdown = (signal) => {
  logger.info(`${signal} received, shutting down server...`);
  console.log(`\n⚠️  ${signal} 信号接收，正在关闭服务器...`);

  server.close(() => {
    // 关闭数据库连接
    const db = require('./config/database');
    if (db && typeof db.close === 'function') {
      db.close();
      logger.info('Database connection closed');
    }
    logger.info('Server shut down successfully');
    console.log('✅ 服务器已关闭');
    process.exit(0);
  });

  // 如果 10 秒后还没关闭，强制退出
  setTimeout(() => {
    logger.error('Server shutdown timeout, forcing exit');
    console.error('❌ 服务器关闭超时，强制退出');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// 未捕获的异常
process.on('uncaughtException', (err) => {
  logger.error('未捕获的异常:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('未处理的 Promise 拒绝:', reason);
});

module.exports = app;
