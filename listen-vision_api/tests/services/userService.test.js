// Mock 数据库模块 - 必须在 require userService 之前定义
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
      reset_code TEXT,
      code_expire TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `);

  return db;
});

const userService = require('../../services/userService');

// 获取 mock 的数据库实例
const db = require('../../config/database');

describe('用户服务测试', () => {
  // 在每个测试前清空用户表
  beforeEach(() => {
    db.exec('DELETE FROM users');
  });

  describe('isUsernameTaken()', () => {
    test('不存在的用户名应返回 false', () => {
      const result = userService.isUsernameTaken('nonexistent');
      expect(result).toBe(false);
    });

    test('已存在的用户名应返回 true', () => {
      // 先插入一个用户
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', 'hashedpassword');

      const result = userService.isUsernameTaken('testuser');
      expect(result).toBe(true);
    });
  });

  describe('isEmailTaken()', () => {
    test('不存在的邮箱应返回 false', () => {
      const result = userService.isEmailTaken('nonexistent@example.com');
      expect(result).toBe(false);
    });

    test('已存在的邮箱应返回 true', () => {
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', 'hashedpassword');

      const result = userService.isEmailTaken('test@example.com');
      expect(result).toBe(true);
    });
  });

  describe('registerUser()', () => {
    test('成功注册新用户', async () => {
      const result = await userService.registerUser('newuser', 'password123', 'newuser@example.com');

      expect(result).toHaveProperty('id');
      expect(result.username).toBe('newuser');
      expect(result.email).toBe('newuser@example.com');

      // 验证用户确实被插入数据库
      const user = db.prepare('SELECT * FROM users WHERE username = ?').get('newuser');
      expect(user).toBeDefined();
      expect(user.email).toBe('newuser@example.com');
    });

    test('用户名已存在应抛出错误', async () => {
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('existing', 'existing@example.com', 'hashedpassword');

      await expect(
        userService.registerUser('existing', 'password123', 'another@example.com')
      ).rejects.toThrow('用户名已存在');
    });

    test('邮箱已存在应抛出错误', async () => {
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('user1', 'existing@example.com', 'hashedpassword');

      await expect(
        userService.registerUser('newuser', 'password123', 'existing@example.com')
      ).rejects.toThrow('邮箱已存在');
    });
  });

  describe('loginUser()', () => {
    beforeEach(() => {
      // 创建测试用户（密码是 'password123' 的 bcrypt 哈希）
      const bcrypt = require('bcryptjs');
      const hashedPassword = bcrypt.hashSync('password123', 10);

      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', hashedPassword);
    });

    test('正确密码应返回 token 和用户信息', async () => {
      const result = await userService.loginUser('testuser', 'password123');

      expect(result).toHaveProperty('token');
      expect(result.user).toEqual({
        id: expect.any(Number),
        username: 'testuser',
        email: 'test@example.com'
      });
    });

    test('用户不存在应抛出错误', async () => {
      await expect(
        userService.loginUser('nonexistent', 'password123')
      ).rejects.toThrow('用户名或密码错误');
    });

    test('密码错误应抛出错误', async () => {
      await expect(
        userService.loginUser('testuser', 'wrongpassword')
      ).rejects.toThrow('用户名或密码错误');
    });
  });

  describe('getUserById()', () => {
    test('根据 ID 获取用户', () => {
      const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', 'hashedpassword');

      const user = userService.getUserById(info.lastInsertRowid);

      expect(user).toEqual({
        id: info.lastInsertRowid,
        username: 'testuser',
        email: 'test@example.com',
        created_at: expect.any(String)
      });
    });

    test('用户不存在应抛出错误', () => {
      expect(() => {
        userService.getUserById(99999);
      }).toThrow('用户不存在');
    });
  });

  describe('getUserByUsername()', () => {
    test('根据用户名获取用户', () => {
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', 'hashedpassword');

      const user = userService.getUserByUsername('testuser');

      expect(user).toBeDefined();
      expect(user.username).toBe('testuser');
      expect(user.email).toBe('test@example.com');
    });

    test('不存在的用户名应返回 undefined', () => {
      const user = userService.getUserByUsername('nonexistent');
      expect(user).toBeUndefined();
    });
  });

  describe('getAllUsers()', () => {
    test('应返回所有用户（不包含密码）', () => {
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('user1', 'user1@example.com', 'pass1');
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('user2', 'user2@example.com', 'pass2');

      const users = userService.getAllUsers();

      expect(users).toHaveLength(2);
      expect(users[0]).not.toHaveProperty('password');
      expect(users[1]).not.toHaveProperty('password');
    });

    test('空表应返回空数组', () => {
      const users = userService.getAllUsers();
      expect(users).toEqual([]);
    });
  });

  describe('updateUser()', () => {
    test('更新用户名和邮箱', async () => {
      const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('olduser', 'old@example.com', 'hashedpassword');

      const updated = await userService.updateUser(info.lastInsertRowid, {
        username: 'newuser',
        email: 'new@example.com'
      });

      expect(updated.username).toBe('newuser');
      expect(updated.email).toBe('new@example.com');
    });

    test('更新密码应哈希存储', async () => {
      const bcrypt = require('bcryptjs');
      const oldPassword = bcrypt.hashSync('oldpassword', 10);
      const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', oldPassword);

      await userService.updateUser(info.lastInsertRowid, {
        username: 'testuser',
        email: 'test@example.com',
        password: 'newpassword'
      });

      const user = db.prepare('SELECT password FROM users WHERE id = ?').get(info.lastInsertRowid);
      expect(user.password).not.toBe(oldPassword);
      expect(bcrypt.compareSync('newpassword', user.password)).toBe(true);
    });
  });

  describe('deleteUser()', () => {
    test('删除用户应返回成功', () => {
      const info = db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', 'hashedpassword');

      const result = userService.deleteUser(info.lastInsertRowid);

      expect(result).toEqual({ success: true });

      // 验证用户已被删除
      const user = db.prepare('SELECT * FROM users WHERE id = ?').get(info.lastInsertRowid);
      expect(user).toBeUndefined();
    });
  });

  describe('setResetCode()', () => {
    test('设置密码重置验证码', () => {
      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', 'hashedpassword');

      userService.setResetCode('testuser', '123456', '2024-01-01 12:00:00');

      const user = db.prepare('SELECT reset_code, code_expire FROM users WHERE username = ?')
        .get('testuser');

      expect(user.reset_code).toBe('123456');
      expect(user.code_expire).toBe('2024-01-01 12:00:00');
    });
  });

  describe('verifyResetCodeAndResetPassword()', () => {
    beforeEach(() => {
      const bcrypt = require('bcryptjs');
      const hashedPassword = bcrypt.hashSync('oldpassword', 10);

      db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
        .run('testuser', 'test@example.com', hashedPassword);
    });

    test('正确的验证码应重置密码', async () => {
      const expiry = new Date(Date.now() + 10 * 60 * 1000)
        .toISOString().replace('T', ' ')
        .substring(0, 19);

      userService.setResetCode('testuser', '123456', expiry);

      const result = await userService.verifyResetCodeAndResetPassword('testuser', '123456', 'newpassword');

      expect(result).toEqual({ success: true });

      // 验证密码已更新
      const bcrypt = require('bcryptjs');
      const user = db.prepare('SELECT password, reset_code FROM users WHERE username = ?').get('testuser');
      expect(bcrypt.compareSync('newpassword', user.password)).toBe(true);
      expect(user.reset_code).toBeNull();
    });

    test('错误的验证码应抛出错误', async () => {
      await expect(
        userService.verifyResetCodeAndResetPassword('testuser', '000000', 'newpassword')
      ).rejects.toThrow('验证码无效');
    });
  });
});
