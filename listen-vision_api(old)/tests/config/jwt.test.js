const { generateToken, verifyToken, decodeToken } = require('../../config/jwt');

describe('JWT 工具函数测试', () => {
  const testPayload = {
    userId: 123,
    username: 'testuser'
  };

  describe('generateToken()', () => {
    test('应该生成有效的 JWT token', () => {
      const token = generateToken(testPayload);

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3); // JWT 格式: header.payload.signature
    });

    test('应该使用默认过期时间', () => {
      const token = generateToken(testPayload);
      const decoded = decodeToken(token);

      expect(decoded).toHaveProperty('exp');
      expect(decoded.userId).toBe(123);
      expect(decoded.username).toBe('testuser');
    });

    test('应该支持自定义过期时间', () => {
      const token = generateToken(testPayload, '2h');
      const decoded = decodeToken(token);

      expect(decoded).toHaveProperty('exp');
    });
  });

  describe('verifyToken()', () => {
    test('应该验证有效的 token', () => {
      const token = generateToken(testPayload);
      const decoded = verifyToken(token);

      expect(decoded.userId).toBe(123);
      expect(decoded.username).toBe('testuser');
    });

    test('应该抛出无效 token 错误', () => {
      expect(() => {
        verifyToken('invalid.token.here');
      }).toThrow();
    });

    test('应该抛出过期 token 错误', () => {
      // 创建一个已过期的 token (exp 设为过去的时间)
      const jwt = require('jsonwebtoken');
      const expiredToken = jwt.sign(
        { userId: 123, username: 'testuser' },
        process.env.JWT_SECRET,
        { expiresIn: '-1h' } // 过期时间设为 1 小时前
      );

      expect(() => {
        verifyToken(expiredToken);
      }).toThrow();
    });
  });

  describe('decodeToken()', () => {
    test('应该解码 token 而不验证签名', () => {
      const token = generateToken(testPayload);
      const decoded = decodeToken(token);

      expect(decoded.userId).toBe(123);
      expect(decoded.username).toBe('testuser');
    });

    test('应该能解码格式错误的 token（不验证）', () => {
      const decoded = decodeToken('invalid.token.format');

      expect(decoded).toBeDefined();
    });
  });
});
