const bcrypt = require('bcryptjs');
const { generateToken } = require('../config/jwt');
const pool = require('../config/database');

/**
 * 用户服务
 * 处理用户相关的业务逻辑
 */

/**
 * 检查用户名是否已存在
 */
const isUsernameTaken = async (username) => {
  const [results] = await pool.execute(
    'SELECT id FROM users WHERE username = ?',
    [username]
  );
  return results.length > 0;
};

/**
 * 检查邮箱是否已存在
 */
const isEmailTaken = async (email) => {
  const [results] = await pool.execute(
    'SELECT id FROM users WHERE email = ?',
    [email]
  );
  return results.length > 0;
};

/**
 * 用户注册
 */
const registerUser = async (username, password, email) => {
  // 检查用户名是否已存在
  if (await isUsernameTaken(username)) {
    throw new Error('用户名已存在');
  }

  // 检查邮箱是否已存在
  if (await isEmailTaken(email)) {
    throw new Error('邮箱已存在');
  }

  // 哈希密码
  const hashedPassword = await bcrypt.hash(password, 10);

  // 插入新用户
  const [result] = await pool.execute(
    'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
    [username, hashedPassword, email]
  );

  return {
    id: result.insertId,
    username,
    email
  };
};

/**
 * 用户登录
 */
const loginUser = async (username, password) => {
  // 查询用户
  const [results] = await pool.execute(
    'SELECT id, username, email, password FROM users WHERE username = ?',
    [username]
  );

  if (results.length === 0) {
    throw new Error('用户名或密码错误');
  }

  const user = results[0];

  // 验证密码
  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new Error('用户名或密码错误');
  }

  // 生成 JWT token
  const token = generateToken({
    userId: user.id,
    username: user.username
  });

  return {
    token,
    user: {
      id: user.id,
      username: user.username,
      email: user.email
    }
  };
};

/**
 * 根据 ID 获取用户信息
 */
const getUserById = async (userId) => {
  const [users] = await pool.execute(
    'SELECT id, username, email, created_at FROM users WHERE id = ?',
    [userId]
  );

  if (users.length === 0) {
    throw new Error('用户不存在');
  }

  return users[0];
};

/**
 * 根据用户名获取用户信息
 */
const getUserByUsername = async (username) => {
  const [users] = await pool.execute(
    'SELECT id, username, email, created_at FROM users WHERE username = ?',
    [username]
  );

  return users[0];
};

/**
 * 获取所有用户
 */
const getAllUsers = async () => {
  const [users] = await pool.execute(
    'SELECT id, username, email, created_at FROM users'
  );
  return users;
};

/**
 * 更新用户
 */
const updateUser = async (userId, updateData) => {
  const { username, email, password } = updateData;

  let query = 'UPDATE users SET username = ?, email = ?';
  let params = [username, email];

  if (password) {
    const hashedPassword = await bcrypt.hash(password, 10);
    query += ', password = ?';
    params.push(hashedPassword);
  }

  query += ' WHERE id = ?';
  params.push(userId);

  await pool.execute(query, params);

  return await getUserById(userId);
};

/**
 * 删除用户
 */
const deleteUser = async (userId) => {
  await pool.execute('DELETE FROM users WHERE id = ?', [userId]);
  return { success: true };
};

/**
 * 设置密码重置验证码
 */
const setResetCode = async (username, code, expiry) => {
  await pool.execute(
    'UPDATE users SET reset_code = ?, code_expire = ? WHERE username = ?',
    [code, expiry, username]
  );
};

/**
 * 验证重置验证码并重置密码
 */
const verifyResetCodeAndResetPassword = async (username, code, newPassword) => {
  const [users] = await pool.execute(
    `SELECT * FROM users
     WHERE username = ?
     AND reset_code = ?
     AND code_expire > NOW()`,
    [username, code]
  );

  if (users.length === 0) {
    throw new Error('验证码无效');
  }

  // 更新密码
  const hashedPassword = await bcrypt.hash(newPassword, 10);
  await pool.execute(
    `UPDATE users
     SET password = ?,
         reset_code = NULL,
         code_expire = NULL
     WHERE username = ?`,
    [hashedPassword, username]
  );

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
