// Mock 服务层
jest.mock('../../services/userService');
jest.mock('../../services/emailService');

const userService = require('../../services/userService');
const emailService = require('../../services/emailService');
const {
  register,
  login,
  getMe,
  verifyToken,
  sendResetCode,
  resetPassword
} = require('../../controllers/authController');
const { AppError } = require('../../middleware/errorHandler');

// 模拟请求和响应对象
const mockRequest = (body = {}, user = null) => ({
  body,
  user
});

const mockResponse = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

// 模拟 next 函数
const mockNext = jest.fn();

describe('认证控制器测试', () => {
  beforeEach(() => {
    // 重置所有 mocks
    jest.clearAllMocks();
  });

  describe('register - 用户注册', () => {
    test('成功注册新用户', async () => {
      const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com'
      };
      const mockResult = {
        token: 'mock-jwt-token',
        user: mockUser
      };

      userService.registerUser.mockResolvedValue(mockResult);

      const req = mockRequest({
        username: 'testuser',
        password: 'password123',
        email: 'test@example.com'
      });
      const res = mockResponse();

      await register(req, res, mockNext);

      expect(userService.registerUser).toHaveBeenCalledWith(
        'testuser',
        'password123',
        'test@example.com'
      );
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: '注册成功',
        data: mockResult
      });
    });

    test('缺少用户名应返回 400 错误', async () => {
      const req = mockRequest({
        password: 'password123',
        email: 'test@example.com'
      });
      const res = mockResponse();

      await register(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名、密码和邮箱不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
      expect(userService.registerUser).not.toHaveBeenCalled();
    });

    test('缺少密码应返回 400 错误', async () => {
      const req = mockRequest({
        username: 'testuser',
        email: 'test@example.com'
      });
      const res = mockResponse();

      await register(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名、密码和邮箱不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
    });

    test('缺少邮箱应返回 400 错误', async () => {
      const req = mockRequest({
        username: 'testuser',
        password: 'password123'
      });
      const res = mockResponse();

      await register(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名、密码和邮箱不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
    });

    test('用户名已存在应传递错误', async () => {
      const error = new AppError('用户名已存在', 409);
      userService.registerUser.mockRejectedValue(error);

      const req = mockRequest({
        username: 'existinguser',
        password: 'password123',
        email: 'new@example.com'
      });
      const res = mockResponse();

      // 不使用 await，因为 catchAsync 会将错误传递给 next
      register(req, res, mockNext);

      // 等待一个微任务，让 Promise settle
      await new Promise(resolve => setImmediate(resolve));

      expect(mockNext).toHaveBeenCalledWith(error);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('邮箱已存在应传递错误', async () => {
      const error = new AppError('邮箱已存在', 409);
      userService.registerUser.mockRejectedValue(error);

      const req = mockRequest({
        username: 'newuser',
        password: 'password123',
        email: 'existing@example.com'
      });
      const res = mockResponse();

      register(req, res, mockNext);

      await new Promise(resolve => setImmediate(resolve));

      expect(mockNext).toHaveBeenCalledWith(error);
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('login - 用户登录', () => {
    test('成功登录', async () => {
      const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com'
      };
      const mockResult = {
        token: 'mock-jwt-token',
        user: mockUser
      };

      userService.loginUser.mockResolvedValue(mockResult);

      const req = mockRequest({
        username: 'testuser',
        password: 'password123'
      });
      const res = mockResponse();

      await login(req, res, mockNext);

      expect(userService.loginUser).toHaveBeenCalledWith('testuser', 'password123');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: '登录成功',
        data: mockResult
      });
    });

    test('缺少用户名应返回 400 错误', async () => {
      const req = mockRequest({
        password: 'password123'
      });
      const res = mockResponse();

      await login(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名和密码不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
      expect(userService.loginUser).not.toHaveBeenCalled();
    });

    test('缺少密码应返回 400 错误', async () => {
      const req = mockRequest({
        username: 'testuser'
      });
      const res = mockResponse();

      await login(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名和密码不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
    });

    test('用户名或密码错误应传递错误', async () => {
      const error = new AppError('用户名或密码错误', 401);
      userService.loginUser.mockRejectedValue(error);

      const req = mockRequest({
        username: 'wronguser',
        password: 'wrongpass'
      });
      const res = mockResponse();

      login(req, res, mockNext);

      await new Promise(resolve => setImmediate(resolve));

      expect(mockNext).toHaveBeenCalledWith(error);
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('getMe - 获取当前用户信息', () => {
    test('成功获取用户信息', async () => {
      const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        created_at: '2024-01-01 12:00:00'
      };

      userService.getUserById.mockReturnValue(mockUser);

      const req = mockRequest({}, { id: 1 });
      const res = mockResponse();

      await getMe(req, res, mockNext);

      expect(userService.getUserById).toHaveBeenCalledWith(1);
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: '获取用户信息成功',
        data: mockUser
      });
    });

    test('用户不存在应传递错误', async () => {
      const error = new AppError('用户不存在', 404);
      userService.getUserById.mockImplementation(() => {
        throw error;
      });

      const req = mockRequest({}, { id: 999 });
      const res = mockResponse();

      getMe(req, res, mockNext);

      await new Promise(resolve => setImmediate(resolve));

      expect(mockNext).toHaveBeenCalledWith(error);
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('verifyToken - 验证 Token', () => {
    test('Token 有效应返回用户信息', async () => {
      const mockUser = {
        id: 1,
        username: 'testuser'
      };

      const req = mockRequest({}, mockUser);
      const res = mockResponse();

      await verifyToken(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Token 有效',
        data: { user: mockUser }
      });
    });

    test('Token 过期或无效由中间件处理（此处不测试）', () => {
      // Token 验证由 authMiddleware 处理，到达控制器时 token 已验证
      expect(true).toBe(true);
    });
  });

  describe('sendResetCode - 发送密码重置验证码', () => {
    test('成功发送验证码', async () => {
      emailService.sendResetCode.mockResolvedValue({ success: true });

      const req = mockRequest({
        username: 'testuser'
      });
      const res = mockResponse();

      await sendResetCode(req, res, mockNext);

      expect(emailService.sendResetCode).toHaveBeenCalledWith('testuser');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: '如果用户存在，验证码已发送',
        data: { success: true }
      });
    });

    test('缺少用户名应返回 400 错误', async () => {
      const req = mockRequest({});
      const res = mockResponse();

      await sendResetCode(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
      expect(emailService.sendResetCode).not.toHaveBeenCalled();
    });

    test('用户不存在也应返回成功（防止用户探测）', async () => {
      // emailService.sendResetCode 对不存在的用户也会返回成功
      emailService.sendResetCode.mockResolvedValue({ success: true });

      const req = mockRequest({
        username: 'nonexistent'
      });
      const res = mockResponse();

      await sendResetCode(req, res, mockNext);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: '如果用户存在，验证码已发送',
        data: { success: true }
      });
    });
  });

  describe('resetPassword - 重置密码', () => {
    test('成功重置密码', async () => {
      userService.verifyResetCodeAndResetPassword.mockResolvedValue({ success: true });

      const req = mockRequest({
        username: 'testuser',
        code: '123456',
        newPassword: 'newpassword123'
      });
      const res = mockResponse();

      await resetPassword(req, res, mockNext);

      expect(userService.verifyResetCodeAndResetPassword).toHaveBeenCalledWith(
        'testuser',
        '123456',
        'newpassword123'
      );
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: '密码重置成功',
        data: { success: true }
      });
    });

    test('缺少用户名应返回 400 错误', async () => {
      const req = mockRequest({
        code: '123456',
        newPassword: 'newpassword123'
      });
      const res = mockResponse();

      await resetPassword(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名、验证码和新密码不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
      expect(userService.verifyResetCodeAndResetPassword).not.toHaveBeenCalled();
    });

    test('缺少验证码应返回 400 错误', async () => {
      const req = mockRequest({
        username: 'testuser',
        newPassword: 'newpassword123'
      });
      const res = mockResponse();

      await resetPassword(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名、验证码和新密码不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
    });

    test('缺少新密码应返回 400 错误', async () => {
      const req = mockRequest({
        username: 'testuser',
        code: '123456'
      });
      const res = mockResponse();

      await resetPassword(req, res, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(AppError));
      expect(mockNext.mock.calls[0][0].message).toBe('用户名、验证码和新密码不能为空');
      expect(mockNext.mock.calls[0][0].statusCode).toBe(400);
    });

    test('验证码无效应传递错误', async () => {
      const error = new Error('验证码无效');
      userService.verifyResetCodeAndResetPassword.mockRejectedValue(error);

      const req = mockRequest({
        username: 'testuser',
        code: '000000',
        newPassword: 'newpassword123'
      });
      const res = mockResponse();

      resetPassword(req, res, mockNext);

      await new Promise(resolve => setImmediate(resolve));

      expect(mockNext).toHaveBeenCalledWith(error);
      expect(res.status).not.toHaveBeenCalled();
    });
  });
});
