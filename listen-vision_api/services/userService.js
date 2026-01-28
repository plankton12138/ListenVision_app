const bcrypt = require('bcryptjs');
const { generateToken } = require('../config/jwt');
const db = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

// 预编译语句（模块初始化时编译，提高性能）
const stmt = {
  userById: db.prepare('SELECT id, username, email, created_at FROM users WHERE id = ?'),
  userByName: db.prepare('SELECT * FROM users WHERE username = ?'),
  userByEmail: db.prepare('SELECT id FROM users WHERE email = ?'),
  userByNameForAuth: db.prepare('SELECT id, username, email, password FROM users WHERE username = ?'),
  allUsers: db.prepare('SELECT id, username, email, created_at FROM users'),
  insertUser: db.prepare('INSERT INTO users (username, password, email) VALUES (?, ?, ?)'),
  updateUser: db.prepare('UPDATE users SET username = ?, email = ? WHERE id = ?'),
  updateUserWithPassword: db.prepare('UPDATE users SET username = ?, email = ?, password = ? WHERE id = ?'),
  deleteUser: db.prepare('DELETE FROM users WHERE id = ?'),
  setResetCode: db.prepare('UPDATE users SET reset_code = ?, code_expire = ? WHERE username = ?'),
  verifyResetCode: db.prepare(`SELECT * FROM users
    WHERE username = ? AND reset_code = ? AND code_expire > datetime('now')`),
  resetPassword: db.prepare(`UPDATE users
    SET password = ?, reset_code = NULL, code_expire = NULL WHERE username = ?`),
};

// 检查用户名是否已存在
const isUsernameTaken = (username) => {
  return !!stmt.userByName.get(username);
};

// 检查邮箱是否已存在
const isEmailTaken = (email) => {
  return !!stmt.userByEmail.get(email);
};

// 用户注册
const registerUser = async (username, password, email) => {
  if (isUsernameTaken(username)) {
    throw new AppError('用户名已存在', 409);
  }
  if (isEmailTaken(email)) {
    throw new AppError('邮箱已存在', 409);
  }

  // bcrypt 哈希密码（10轮加密）
  const hashedPassword = await bcrypt.hash(password, 10);
  const result = stmt.insertUser.run(username, hashedPassword, email);

  const userId = result.lastInsertRowid;

  // 注册成功后自动生成 token，实现"注册即登录"
  const token = generateToken({ userId, username });

  return {
    token,
    user: { id: userId, username, email }
  };
};

// 用户登录
const loginUser = async (username, password) => {
  const user = stmt.userByNameForAuth.get(username);
  if (!user) {
    throw new AppError('用户名或密码错误', 401);
  }

  // 验证密码
  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new AppError('用户名或密码错误', 401);
  }

  // 生成 JWT token
  const token = generateToken({ userId: user.id, username: user.username });

  return {
    token,
    user: { id: user.id, username: user.username, email: user.email }
  };
};

// 根据 ID 获取用户信息
const getUserById = (userId) => {
  const user = stmt.userById.get(userId);
  if (!user) {
    throw new AppError('用户不存在', 404);
  }
  return user;
};

// 根据用户名获取用户信息
const getUserByUsername = (username) => {
  return stmt.userByName.get(username);
};

// 获取所有用户
const getAllUsers = () => {
  return stmt.allUsers.all();
};

// 更新用户
const updateUser = async (userId, updateData) => {
  const { username, email, password } = updateData;

  if (password) {
    const hashedPassword = await bcrypt.hash(password, 10);
    stmt.updateUserWithPassword.run(username, email, hashedPassword, userId);
  } else {
    stmt.updateUser.run(username, email, userId);
  }

  return getUserById(userId);
};

// 删除用户
const deleteUser = (userId) => {
  stmt.deleteUser.run(userId);
  return { success: true };
};

// 设置密码重置验证码
const setResetCode = (username, code, expiry) => {
  stmt.setResetCode.run(code, expiry, username);
};

// 验证重置验证码并重置密码
const verifyResetCodeAndResetPassword = async (username, code, newPassword) => {
  const user = stmt.verifyResetCode.get(username, code);
  if (!user) {
    throw new Error('验证码无效');
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);
  stmt.resetPassword.run(hashedPassword, username);

  return { success: true };
};

module.exports = {
  isUsernameTaken,
  isEmailTaken,
  registerUser,
  loginUser,
  getUserById,
  getUserByUsername,
  getAllUsers,
  updateUser,
  deleteUser,
  setResetCode,
  verifyResetCodeAndResetPassword
};
