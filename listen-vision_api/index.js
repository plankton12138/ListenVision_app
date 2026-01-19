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

// API 路由
// 调试中间件：打印所有请求
app.use('/api', (req, res, next) => {
  console.log(`[DEBUG] ${req.method} ${req.originalUrl}`);
  next();
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/favorites', require('./routes/favorites'));

try {
  const bilibiliRouter = require('./routes/bilibili');
  app.use('/api/bilibili', bilibiliRouter);
  console.log('✅ Bilibili routes registered, stack length:', bilibiliRouter.stack.length);
  bilibiliRouter.stack.forEach((layer, i) => {
    if (layer.route) {
      console.log(`  - Route ${i}: ${Object.keys(layer.route.methods).join(',').toUpperCase()} ${layer.route.path}`);
    }
  });
} catch (e) {
  console.error('❌ Failed to load bilibili routes:', e.message);
}

try {
  const audioRouter = require('./routes/audio');
  app.use('/api/audio', audioRouter);
  console.log('✅ Audio routes registered');
} catch (e) {
  console.error('❌ Failed to load audio routes:', e.message);
}

// ========== Phase 2: 歌单、历史、推荐路由 ==========

try {
  const playlistsRouter = require('./routes/playlists');
  app.use('/api/playlists', playlistsRouter);
  console.log('✅ Playlists routes registered');
} catch (e) {
  console.error('❌ Failed to load playlists routes:', e.message);
}

try {
  const historyRouter = require('./routes/history');
  app.use('/api/history', historyRouter);
  console.log('✅ History routes registered');
} catch (e) {
  console.error('❌ Failed to load history routes:', e.message);
}

try {
  const recommendationsRouter = require('./routes/recommendations');
  app.use('/api/recommendations', recommendationsRouter);
  console.log('✅ Recommendations routes registered');
} catch (e) {
  console.error('❌ Failed to load recommendations routes:', e.message);
}

// ========== Phase 3: 搜索、推荐与下载路由 ==========

try {
  const searchRouter = require('./routes/search');
  app.use('/api/search', searchRouter);
  console.log('✅ Search routes registered');
} catch (e) {
  console.error('❌ Failed to load search routes:', e.message);
}

try {
  const downloadsRouter = require('./routes/downloads');
  app.use('/api/downloads', downloadsRouter);
  console.log('✅ Downloads routes registered');
} catch (e) {
  console.error('❌ Failed to load downloads routes:', e.message);
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
});

// ========== 优雅退出 ==========

const gracefulShutdown = (signal) => {
  console.log(`\n⚠️  ${signal} 信号接收，正在关闭服务器...`);

  server.close(() => {
    // 关闭数据库连接
    const db = require('./config/database');
    if (db && typeof db.close === 'function') {
      db.close();
      console.log('数据库连接已关闭');
    }
    console.log('✅ 服务器已关闭');
    process.exit(0);
  });

  // 如果 10 秒后还没关闭，强制退出
  setTimeout(() => {
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
