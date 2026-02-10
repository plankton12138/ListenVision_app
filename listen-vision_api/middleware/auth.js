const jwt = require('jsonwebtoken');
const { logger } = require('../utils/logger');
const db = require('../config/database');

const stmt = {
  userById: db.prepare('SELECT id, username FROM users WHERE id = ?'),
};

/**
 * JWT 认证中间件
 * 验证请求头中的 Authorization token
 *
 * 使用方法:
 * router.get('/protected', authMiddleware, (req, res) => { ... });
 *
 * 客户端请求格式:
 * headers: { Authorization: 'Bearer <token>' }
 */
const authMiddleware = async (req, res, next) => {
  try {
    // 1. 从请求头获取 token
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        error: '未提供认证 token'
      });
    }

    // 2. 解析 Bearer token
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return res.status(401).json({
        success: false,
        error: 'Token 格式错误'
      });
    }

    const token = parts[1];

    // 3. 验证 token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 4. 将用户信息附加到请求对象
    req.user = {
      id: parseInt(decoded.userId, 10),  // 确保是整数
      username: decoded.username
    };

    // 5. 验证用户是否存在于数据库
    const user = stmt.userById.get(req.user.id);
    if (!user) {
      logger.warn('Token 中的用户不存在: userId=%s', req.user.id);
      return res.status(401).json({
        success: false,
        error: '用户不存在或已被删除，请重新登录'
      });
    }

    next();
  } catch (error) {
    // 处理不同类型的 JWT 错误
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token 已过期'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Token 无效'
      });
    }

    // 其他错误
    return res.status(500).json({
      success: false,
      error: '认证失败'
    });
  }
};

/**
 * 可选的认证中间件
 * 如果提供了 token 则验证，没有提供也不报错
 * 用于某些可以游客访问但登录用户有额外功能的接口
 */
const optionalAuthMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return next();
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return next();
    }

    const token = parts[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = {
      id: parseInt(decoded.userId, 10),  // 确保是整数
      username: decoded.username
    };

    // 验证用户是否存在于数据库
    const user = stmt.userById.get(req.user.id);
    if (!user) {
      logger.debug('[OptionalAuth] 用户不存在，跳过认证: userId=%s', req.user.id);
      req.user = null;
    }

    next();
  } catch (error) {
    // 可选认证失败，记录日志但继续处理请求
    logger.debug('[OptionalAuth] Token验证失败，跳过认证: %s', error.message);
    next();
  }
};

module.exports = {
  authMiddleware,
  optionalAuthMiddleware
};
