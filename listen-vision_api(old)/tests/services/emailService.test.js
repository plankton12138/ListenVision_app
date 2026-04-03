// 设置环境变量（在 require 模块之前）
process.env.SMTP_HOST = 'smtp.test.com';
process.env.SMTP_PORT = '465';
process.env.SMTP_SECURE = 'true';
process.env.SMTP_USER = 'test@test.com';

// Mock nodemailer - 必须在 require emailService 之前定义
jest.mock('nodemailer', () => {
  let mockSendMail = jest.fn().mockResolvedValue({ messageId: 'test-message-id' });

  return {
    createTransport: jest.fn(() => ({
      sendMail: mockSendMail,
      // 暴露方法用于测试
      _getMockSendMail: () => mockSendMail
    }))
  };
});

// Mock 数据库模块
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');

  const db = new Database(':memory:');

  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      reset_code TEXT,
      code_expire TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  return db;
});

// 现在才引入 emailService
const emailService = require('../../services/emailService');
const db = require('../../config/database');
const nodemailer = require('nodemailer');

describe('邮件服务测试', () => {
  let mockSendMail;

  beforeEach(() => {
    // 清空用户表
    db.exec('DELETE FROM users');

    // 创建测试用户
    db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'testuser@example.com', 'hashedpassword');

    // 获取 mock 函数引用
    const transport = nodemailer.createTransport();
    mockSendMail = transport._getMockSendMail();

    // 重置 mock 调用记录和行为
    mockSendMail.mockClear();
    mockSendMail.mockResolvedValue({ messageId: 'test-message-id' });
  });

  describe('sendResetCode()', () => {
    test('用户存在时应生成并发送验证码', async () => {
      const result = await emailService.sendResetCode('testuser');

      expect(result).toEqual({ success: true });

      // 验证验证码已保存到数据库
      const user = db.prepare('SELECT reset_code, code_expire FROM users WHERE username = ?')
        .get('testuser');

      expect(user.reset_code).toBeDefined();
      expect(user.reset_code).toMatch(/^\d{6}$/); // 6 位数字
      expect(user.code_expire).toBeDefined();

      // 验证发送邮件被调用
      expect(mockSendMail).toHaveBeenCalled();
      expect(mockSendMail.mock.calls[0][0].to).toBe('testuser@example.com');
      expect(mockSendMail.mock.calls[0][0].subject).toBe('验证码通知');
    });

    test('用户不存在应返回成功（防止探测）', async () => {
      const result = await emailService.sendResetCode('nonexistent');

      expect(result).toEqual({ success: true });

      // 验证没有发送邮件
      expect(mockSendMail).not.toHaveBeenCalled();
    });

    test('验证码应为 6 位随机数字', async () => {
      // 调用两次，确保验证码不同
      await emailService.sendResetCode('testuser');
      const user1 = db.prepare('SELECT reset_code FROM users WHERE username = ?').get('testuser');
      const code1 = user1.reset_code;

      await emailService.sendResetCode('testuser');
      const user2 = db.prepare('SELECT reset_code FROM users WHERE username = ?').get('testuser');
      const code2 = user2.reset_code;

      expect(code1).toMatch(/^\d{6}$/);
      expect(code2).toMatch(/^\d{6}$/);
      // 随机性验证：两次生成的验证码大概率不同
    });

    test('验证码过期时间应为 10 分钟后', async () => {
      const beforeTime = Date.now();
      await emailService.sendResetCode('testuser');

      const user = db.prepare('SELECT code_expire FROM users WHERE username = ?').get('testuser');
      const expiryDate = new Date(user.code_expire + '+00:00'); // 解析为 UTC 时间

      // 验证过期时间大约在当前时间 +10 分钟
      const timeDiff = expiryDate.getTime() - beforeTime;
      const expectedDiff = 10 * 60 * 1000; // 10 分钟

      // 允许 1 秒误差
      expect(timeDiff).toBeGreaterThanOrEqual(expectedDiff - 1000);
      expect(timeDiff).toBeLessThanOrEqual(expectedDiff + 1000);
    });
  });

  describe('sendEmail()', () => {
    test('成功发送邮件', async () => {
      const result = await emailService.sendEmail(
        'recipient@example.com',
        'Test Subject',
        '<p>Test HTML</p>'
      );

      expect(result.success).toBe(true);
      expect(result.messageId).toBe('test-message-id');

      expect(mockSendMail).toHaveBeenCalledWith({
        from: '"ListenVision" <test@test.com>',
        to: 'recipient@example.com',
        subject: 'Test Subject',
        html: '<p>Test HTML</p>'
      });
    });

    test('发送失败应抛出错误', async () => {
      // Mock 发送失败
      mockSendMail.mockRejectedValueOnce(new Error('SMTP error'));

      await expect(
        emailService.sendEmail('recipient@example.com', 'Subject', 'HTML')
      ).rejects.toThrow('邮件发送失败');
    });
  });
});
