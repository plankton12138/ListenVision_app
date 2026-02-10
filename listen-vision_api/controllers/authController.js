const userService = require('../services/userService');
const emailService = require('../services/emailService');
const bilibiliService = require('../services/bilibiliService');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 认证控制器
 * 处理登录、注册、密码重置等认证相关请求
 */

/**
 * 用户注册 - 发送验证码
 * 第一步：验证参数，发送验证码到邮箱
 */
const register = catchAsync(async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password || !email) {
    throw new AppError('用户名、密码和邮箱不能为空', 400);
  }

  if (password.length < 6) {
    throw new AppError('密码长度不能少于6位', 400);
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new AppError('邮箱格式不正确', 400);
  }

  const code = emailService.generateVerifyCode();

  await userService.createPendingRegistration(username, password, email, code);

  try {
    await emailService.sendVerificationCode(email, code);
  } catch (error) {
    userService.deletePendingRegistration(username);
    throw new AppError('验证码发送失败，请检查邮箱地址', 500);
  }

  return successResponse(res, {
    pending: true,
    email,
    expiresIn: 600
  }, '验证码已发送到邮箱', 201);
});

/**
 * 验证邮箱并完成注册
 * 第二步：验证验证码，创建用户
 */
const verifyEmail = catchAsync(async (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    throw new AppError('邮箱和验证码不能为空', 400);
  }

  const result = await userService.verifyEmailAndCreateUser(email, code);

  return successResponse(res, result, '注册成功', 201);
});

/**
 * 用户登录 - 支持 email 或 username
 */
const login = catchAsync(async (req, res) => {
  const usernameOrEmail = req.body.usernameOrEmail || req.body.username || req.body.email;
  const { password } = req.body;

  if (!usernameOrEmail || !password) {
    throw new AppError('用户名/邮箱和密码不能为空', 400);
  }

  const result = await userService.loginUser(usernameOrEmail, password);

  const bindStatus = bilibiliService.getBindStatus(result.user.id);

  return successResponse(res, {
    ...result,
    bilibiliBound: bindStatus.isBound,
    bilibiliUser: bindStatus.userInfo || null
  }, '登录成功');
});

/**
 * 获取当前用户信息
 */
const getMe = catchAsync(async (req, res) => {
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

/**
 * 注销账号
 * 删除用户及所有关联数据
 */
const deleteAccount = catchAsync(async (req, res) => {
  const userId = req.user.id;

  bilibiliService.unbindAccount(userId);

  await userService.deleteUser(userId);

  return successResponse(res, { success: true }, '账号已注销');
});

/**
 * 登出（客户端清除 token 即可，服务端无需操作）
 */
const logout = catchAsync(async (req, res) => {
  return successResponse(res, { success: true }, '登出成功');
});

module.exports = {
  register,
  verifyEmail,
  login,
  logout,
  getMe,
  verifyToken,
  sendResetCode,
  resetPassword,
  deleteAccount
};
