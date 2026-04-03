const jwt = require('jsonwebtoken');

/**
 * JWT 配置和工具函数
 */

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || 'refresh-secret-key-change-in-production';
const REFRESH_TOKEN_EXPIRES_IN = process.env.REFRESH_TOKEN_EXPIRES_IN || '30d';

/**
 * 生成 access token（短期）
 * @param {Object} payload - 要编码的数据（通常包含 userId, username 等）
 * @param {String} expiresIn - 过期时间（可选，默认使用配置文件中的值）
 * @returns {String} JWT token
 */
const generateToken = (payload, expiresIn = JWT_EXPIRES_IN) => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
};

/**
 * 生成 refresh token（长期）
 * @param {Object} payload - 要编码的数据（通常包含 userId）
 * @param {String} expiresIn - 过期时间（可选，默认 30 天）
 * @returns {String} Refresh token
 */
const generateRefreshToken = (payload, expiresIn = REFRESH_TOKEN_EXPIRES_IN) => {
  return jwt.sign(payload, REFRESH_TOKEN_SECRET, { expiresIn });
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
 * 验证 refresh token
 * @param {String} token - Refresh token
 * @returns {Object} 解码后的 payload
 */
const verifyRefreshToken = (token) => {
  return jwt.verify(token, REFRESH_TOKEN_SECRET);
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
  generateRefreshToken,
  verifyToken,
  verifyRefreshToken,
  decodeToken
};
