const userService = require('../services/userService');
const emailService = require('../services/emailService');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 认证控制器
 * 处理登录、注册、密码重置等认证相关请求
 */

/**
 * 用户注册
 */
const register = catchAsync(async (req, res) => {
  const { username, password, email } = req.body;

  // 参数验证
  if (!username || !password || !email) {
    throw new AppError('用户名、密码和邮箱不能为空', 400);
  }

  // 调用服务层
  const user = await userService.registerUser(username, password, email);

  return successResponse(res, user, '注册成功', 201);
});

/**
 * 用户登录
 */
const login = catchAsync(async (req, res) => {
  const { username, password } = req.body;

  // 参数验证
  if (!username || !password) {
    throw new AppError('用户名和密码不能为空', 400);
  }

  // 调用服务层
  const result = await userService.loginUser(username, password);

  return successResponse(res, result, '登录成功');
});

/**
 * 获取当前用户信息
 */
const getMe = catchAsync(async (req, res) => {
  // req.user 是从 authMiddleware 中附加的
  const user = await userService.getUserById(req.user.id);

  return successResponse(res, user, '获取用户信息成功');
});

/**
 * 验证 token
 */
const verifyToken = catchAsync(async (req, res) => {
  return successResponse(res, {
    user: req.user
  }, 'Token 有效');
});

/**
 * 发送密码重置验证码
 */
const sendResetCode = catchAsync(async (req, res) => {
  const { username } = req.body;

  if (!username) {
    throw new AppError('用户名不能为空', 400);
  }

  await emailService.sendResetCode(username);

  // 统一返回成功（防止用户探测）
  return successResponse(res, { success: true }, '如果用户存在，验证码已发送');
});

/**
 * 重置密码
 */
const resetPassword = catchAsync(async (req, res) => {
  const { username, code, newPassword } = req.body;

  if (!username || !code || !newPassword) {
    throw new AppError('用户名、验证码和新密码不能为空', 400);
  }

  await userService.verifyResetCodeAndResetPassword(username, code, newPassword);

  return successResponse(res, { success: true }, '密码重置成功');
});

module.exports = {
  register,
  login,
  getMe,
  verifyToken,
  sendResetCode,
  resetPassword
};
