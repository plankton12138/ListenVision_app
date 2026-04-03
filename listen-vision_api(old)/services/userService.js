const bcrypt = require('bcryptjs');
const { generateToken } = require('../config/jwt');
const db = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

// 预编译语句（模块初始化时编译，提高性能）
const stmt = {
  userById: db.prepare('SELECT id, username, email, email_verified, created_at FROM users WHERE id = ?'),
  userByName: db.prepare('SELECT * FROM users WHERE username = ?'),
  userByEmail: db.prepare('SELECT id, username FROM users WHERE email = ?'),
  userByNameForAuth: db.prepare('SELECT id, username, email, password FROM users WHERE username = ?'),
  allUsers: db.prepare('SELECT id, username, email, created_at FROM users'),
  insertUser: db.prepare('INSERT INTO users (username, password, email, email_verified) VALUES (?, ?, ?, ?)'),
  updateUser: db.prepare('UPDATE users SET username = ?, email = ? WHERE id = ?'),
  updateUserWithPassword: db.prepare('UPDATE users SET username = ?, email = ?, password = ? WHERE id = ?'),
  deleteUser: db.prepare('DELETE FROM users WHERE id = ?'),
  setResetCode: db.prepare('UPDATE users SET reset_code = ?, code_expire = ? WHERE username = ?'),
  verifyResetCode: db.prepare(`SELECT * FROM users
    WHERE username = ? AND reset_code = ? AND code_expire > datetime('now')`),
  resetPassword: db.prepare(`UPDATE users
    SET password = ?, reset_code = NULL, code_expire = NULL WHERE username = ?`),
  // 待验证注册相关
  pendingRegByEmail: db.prepare('SELECT * FROM pending_registrations WHERE email = ?'),
  pendingRegByCode: db.prepare(`SELECT * FROM pending_registrations
    WHERE email = ? AND verify_code = ? AND code_expire > datetime('now')`),
  insertPendingReg: db.prepare(`INSERT INTO pending_registrations
    (username, email, password, verify_code, code_expire) VALUES (?, ?, ?, ?, ?)`),
  deletePendingReg: db.prepare('DELETE FROM pending_registrations WHERE email = ?'),
  deletePendingRegByUsername: db.prepare('DELETE FROM pending_registrations WHERE username = ?'),
  setEmailVerified: db.prepare('UPDATE users SET email_verified = 1 WHERE id = ?'),
};

// 检查用户名是否已存在
const isUsernameTaken = (username) => {
  return !!stmt.userByName.get(username);
};

// 检查邮箱是否已存在
const isEmailTaken = (email) => {
  return !!stmt.userByEmail.get(email);
};

// 用户注册（旧方法，保留兼容）
const registerUser = async (username, password, email) => {
  if (isUsernameTaken(username)) {
    throw new AppError('用户名已存在', 409);
  }
  if (isEmailTaken(email)) {
    throw new AppError('邮箱已存在', 409);
  }

  // bcrypt 哈希密码（10轮加密）
  const hashedPassword = await bcrypt.hash(password, 10);
  const result = stmt.insertUser.run(username, hashedPassword, email, 1);

  const userId = result.lastInsertRowid;

  // 注册成功后自动生成 token，实现"注册即登录"
  const token = generateToken({ userId, username });

  return {
    token,
    user: { id: userId, username, email }
  };
};

// 创建待验证注册记录
const createPendingRegistration = async (username, password, email, verifyCode, expiryMinutes = 10) => {
  if (isUsernameTaken(username)) {
    throw new AppError('用户名已存在', 409);
  }
  if (isEmailTaken(email)) {
    throw new AppError('邮箱已存在', 409);
  }

  // 检查是否有待验证记录
  const existing = stmt.pendingRegByEmail.get(email);
  if (existing) {
    // 删除旧的待验证记录
    stmt.deletePendingReg.run(email);
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const expiry = new Date(Date.now() + expiryMinutes * 60 * 1000)
    .toISOString().replace('T', ' ').substring(0, 19);

  stmt.insertPendingReg.run(username, email, hashedPassword, verifyCode, expiry);

  return { email, expiresIn: expiryMinutes * 60 };
};

// 验证邮箱并完成注册
const verifyEmailAndCreateUser = async (email, verifyCode) => {
  const pending = stmt.pendingRegByCode.get(email, verifyCode);

  if (!pending) {
    throw new AppError('验证码无效或已过期', 400);
  }

  // 再次检查用户名和邮箱是否被占用（防止并发）
  if (isUsernameTaken(pending.username)) {
    stmt.deletePendingReg.run(email);
    throw new AppError('用户名已被占用', 409);
  }
  if (isEmailTaken(email)) {
    stmt.deletePendingReg.run(email);
    throw new AppError('邮箱已被占用', 409);
  }

  // 创建用户
  const result = stmt.insertUser.run(pending.username, pending.password, email, 1);
  const userId = result.lastInsertRowid;

  // 删除待验证记录
  stmt.deletePendingReg.run(email);

  // 生成 tokens
  const { generateToken, generateRefreshToken } = require('../config/jwt');
  const token = generateToken({ userId, username: pending.username });
  const refreshToken = generateRefreshToken({ userId });

  return {
    token,
    refreshToken,
    user: { id: userId, username: pending.username, email }
  };
};

// 删除待验证注册记录（按用户名）
const deletePendingRegistration = (username) => {
  stmt.deletePendingRegByUsername.run(username);
};

// 用户登录 - 支持 username 或 email
const loginUser = async (usernameOrEmail, password) => {
  // 先尝试用 username 查找
  let user = stmt.userByNameForAuth.get(usernameOrEmail);

  // 如果没找到，尝试用 email 查找
  if (!user) {
    const result = stmt.userByEmail.get(usernameOrEmail);
    if (result) {
      user = stmt.userByNameForAuth.get(result.username);
    }
  }

  if (!user) {
    throw new AppError('用户名或密码错误', 401);
  }

  // 验证密码
  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new AppError('用户名或密码错误', 401);
  }

  // 生成 JWT tokens
  const { generateToken, generateRefreshToken } = require('../config/jwt');
  const token = generateToken({ userId: user.id, username: user.username });
  const refreshToken = generateRefreshToken({ userId: user.id });

  return {
    token,
    refreshToken,
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
    throw new AppError('验证码无效', 400);
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);
  stmt.resetPassword.run(hashedPassword, username);

  return { success: true };
};

module.exports = {
  isUsernameTaken,
  isEmailTaken,
  registerUser,
  createPendingRegistration,
  verifyEmailAndCreateUser,
  deletePendingRegistration,
  loginUser,
  getUserById,
  getUserByUsername,
  getAllUsers,
  updateUser,
  deleteUser,
  setResetCode,
  verifyResetCodeAndResetPassword
};
