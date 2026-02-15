// Mock 数据库模块 - 必须在 require auth 之前定义
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');

  // 创建内存数据库用于测试
  const db = new Database(':memory:');

  // 创建测试表结构
  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  return db;
});

const { authMiddleware, optionalAuthMiddleware } = require('../../middleware/auth');
const { generateToken } = require('../../config/jwt');

// 获取 mock 的数据库实例
const db = require('../../config/database');

// 模拟请求和响应对象
const mockRequest = (headers = {}) => ({
  headers
});

const mockResponse = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

// 模拟 next 函数
const mockNext = jest.fn();

describe('认证中间件测试', () => {
  const testPayload = { userId: 123, username: 'testuser' };
  const validToken = generateToken(testPayload);

  beforeEach(() => {
    // 每个测试前重置 mock
    mockNext.mockClear();
    // 确保测试用户存在（ID = 123）
    db.exec('DELETE FROM users');
    db.prepare('INSERT INTO users (id, username, email, password) VALUES (?, ?, ?, ?)')
      .run(123, 'testuser', 'test@example.com', 'hashedpassword');
  });

  describe('authMiddleware - 必须认证', () => {
    test('缺少 Authorization 头应返回 401', () => {
      const req = mockRequest();
      const res = mockResponse();

      authMiddleware(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: '未提供认证 token'
      });
      expect(mockNext).not.toHaveBeenCalled();
    });

    test('错误的 Bearer 格式应返回 401', () => {
      const req = mockRequest({ authorization: 'InvalidFormat token' });
      const res = mockResponse();

      authMiddleware(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: 'Token 格式错误'
      });
      expect(mockNext).not.toHaveBeenCalled();
    });

    test('只有 Bearer 没有 token 应返回 401', () => {
      const req = mockRequest({ authorization: 'Bearer ' });
      const res = mockResponse();

      authMiddleware(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: 'Token 无效'  // JWT 解析空字符串返回无效错误
      });
    });

    test('无效的 token 应返回 401', () => {
      const req = mockRequest({ authorization: 'Bearer invalid.token.here' });
      const res = mockResponse();

      authMiddleware(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: 'Token 无效'
      });
      expect(mockNext).not.toHaveBeenCalled();
    });

    test('过期的 token 应返回 401', () => {
      const jwt = require('jsonwebtoken');
      const expiredToken = jwt.sign(
        { userId: 123, username: 'testuser' },
        process.env.JWT_SECRET,
        { expiresIn: '-1h' }
      );

      const req = mockRequest({ authorization: `Bearer ${expiredToken}` });
      const res = mockResponse();

      authMiddleware(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: 'Token 已过期'
      });
      expect(mockNext).not.toHaveBeenCalled();
    });

    test('有效的 token 应调用 next 并附加用户信息', () => {
      const req = mockRequest({ authorization: `Bearer ${validToken}` });
      const res = mockResponse();

      authMiddleware(req, res, mockNext);

      expect(req.user).toEqual({
        id: 123,
        username: 'testuser'
      });
      expect(mockNext).toHaveBeenCalled();
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('optionalAuthMiddleware - 可选认证', () => {
    test('没有 token 应直接调用 next', () => {
      const req = mockRequest();
      const res = mockResponse();

      optionalAuthMiddleware(req, res, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(req.user).toBeUndefined();
    });

    test('错误的 token 格式应直接调用 next', () => {
      const req = mockRequest({ authorization: 'InvalidFormat' });
      const res = mockResponse();

      optionalAuthMiddleware(req, res, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(req.user).toBeUndefined();
    });

    test('有效的 token 应附加用户信息', () => {
      const req = mockRequest({ authorization: `Bearer ${validToken}` });
      const res = mockResponse();

      optionalAuthMiddleware(req, res, mockNext);

      expect(req.user).toEqual({
        id: 123,
        username: 'testuser'
      });
      expect(mockNext).toHaveBeenCalled();
    });

    test('无效的 token 应静默失败，继续处理请求', () => {
      const req = mockRequest({ authorization: 'Bearer invalid.token' });
      const res = mockResponse();

      optionalAuthMiddleware(req, res, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(req.user).toBeUndefined();
    });
  });
});
