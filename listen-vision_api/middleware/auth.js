const jwt = require('jsonwebtoken');

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
      id: decoded.userId,
      username: decoded.username
    };

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
      id: decoded.userId,
      username: decoded.username
    };

    next();
  } catch (error) {
    // 静默失败，继续处理请求
    next();
  }
};

module.exports = {
  authMiddleware,
  optionalAuthMiddleware
};
