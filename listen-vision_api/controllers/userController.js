const userService = require('../services/userService');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 用户控制器
 * 处理用户管理相关请求
 */

/**
 * 获取所有用户
 */
const getAllUsers = catchAsync(async (req, res) => {
  const users = await userService.getAllUsers();

  return successResponse(res, users, '获取用户列表成功');
});

/**
 * 根据 ID 获取用户
 */
const getUserById = catchAsync(async (req, res) => {
  const { id } = req.params;

  const user = await userService.getUserById(id);

  return successResponse(res, user, '获取用户成功');
});

/**
 * 更新用户
 */
const updateUser = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { username, email, password } = req.body;

  if (!username || !email) {
    throw new AppError('用户名和邮箱不能为空', 400);
  }

  const updateData = { username, email };
  if (password) {
    updateData.password = password;
  }

  const user = await userService.updateUser(id, updateData);

  return successResponse(res, user, '更新用户成功');
});

/**
 * 删除用户
 */
const deleteUser = catchAsync(async (req, res) => {
  const { id } = req.params;

  await userService.deleteUser(id);

  return successResponse(res, { success: true }, '删除用户成功');
});

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser
};
