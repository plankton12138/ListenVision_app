const jwt = require('jsonwebtoken');

/**
 * JWT 配置和工具函数
 */

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * 生成 JWT token
 * @param {Object} payload - 要编码的数据（通常包含 userId, username 等）
 * @param {String} expiresIn - 过期时间（可选，默认使用配置文件中的值）
 * @returns {String} JWT token
 */
const generateToken = (payload, expiresIn = JWT_EXPIRES_IN) => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
};

/**
 * 验证 JWT token
 * @param {String} token - JWT token
 * @returns {Object} 解码后的 payload
 */
const verifyToken = (token) => {
  return jwt.verify(token, JWT_SECRET);
};

/**
 * 解码 JWT token（不验证签名，仅用于读取数据）
 * @param {String} token - JWT token
 * @returns {Object} 解码后的 payload
 */
const decodeToken = (token) => {
  return jwt.decode(token);
};

module.exports = {
  generateToken,
  verifyToken,
  decodeToken
};
