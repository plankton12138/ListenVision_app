const crypto = require('crypto');
const db = require('../config/database');
const { logger } = require('../utils/logger');

const keyMaterial = process.env.PLATFORM_COOKIE_KEY || 'ListenVisionPlatformCookieKey2024';
const ENCRYPTION_KEY = crypto.createHash('sha256').update(keyMaterial).digest();
const IV_LENGTH = 16;
const ALGORITHM = 'aes-256-cbc';

const encrypt = (data) => {
  if (!data) return null;
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return `${iv.toString('hex')}:${encrypted}`;
};

const decrypt = (encryptedData) => {
  if (!encryptedData) return null;
  try {
    const parts = encryptedData.split(':');
    const iv = Buffer.from(parts.shift(), 'hex');
    const encrypted = parts.join(':');
    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (error) {
    logger.error('解密失败: %s', error.message);
    return null;
  }
};

const stmt = {
  insert: db.prepare(`
    INSERT INTO platform_accounts (user_id, platform, platform_user_id, platform_username, cookie_encrypted, token_encrypted, refresh_token_encrypted, is_active, expires_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
  `),
  update: db.prepare(`
    UPDATE platform_accounts
    SET platform_user_id = ?, platform_username = ?, cookie_encrypted = ?, token_encrypted = ?, refresh_token_encrypted = ?, expires_at = ?, is_active = 1, updated_at = datetime('now')
    WHERE user_id = ? AND platform = ?
  `),
  get: db.prepare(`
    SELECT * FROM platform_accounts WHERE user_id = ? AND platform = ? AND is_active = 1
  `),
  getAny: db.prepare(`
    SELECT * FROM platform_accounts WHERE user_id = ? AND platform = ?
  `),
  getAllByUser: db.prepare(`
    SELECT * FROM platform_accounts WHERE user_id = ? AND is_active = 1
  `),
  deactivate: db.prepare(`
    UPDATE platform_accounts SET is_active = 0, updated_at = datetime('now') WHERE user_id = ? AND platform = ?
  `),
  delete: db.prepare(`
    DELETE FROM platform_accounts WHERE user_id = ? AND platform = ?
  `),
};

const saveAccount = async (userId, platform, accountData) => {
  const {
    platformUserId,
    platformUsername,
    cookie,
    token,
    refreshToken,
    expiresInDays = 30,
  } = accountData;

  const encryptedCookie = cookie ? encrypt(cookie) : null;
  const encryptedToken = token ? encrypt(token) : null;
  const encryptedRefreshToken = refreshToken ? encrypt(refreshToken) : null;
  const expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000)
    .toISOString().replace('T', ' ').substring(0, 19);

  const existing = stmt.getAny.get(userId, platform);

  if (existing) {
    stmt.update.run(
      platformUserId || null,
      platformUsername || null,
      encryptedCookie,
      encryptedToken,
      encryptedRefreshToken,
      expiresAt,
      userId,
      platform
    );
    return { success: true, action: 'updated' };
  } else {
    stmt.insert.run(
      userId,
      platform,
      platformUserId || null,
      platformUsername || null,
      encryptedCookie,
      encryptedToken,
      encryptedRefreshToken,
      expiresAt
    );
    return { success: true, action: 'created' };
  }
};

const getAccount = (userId, platform) => {
  const account = stmt.get.get(userId, platform);
  if (!account) return null;

  if (account.expires_at) {
    const expiresAt = new Date(account.expires_at);
    if (expiresAt < new Date()) {
      stmt.deactivate.run(userId, platform);
      return null;
    }
  }

  const cookie = account.cookie_encrypted ? decrypt(account.cookie_encrypted) : null;
  if (account.cookie_encrypted && cookie === null) {
    logger.warn(`Cookie解密失败，停用账号 ${userId} 的 ${platform} 绑定`);
    stmt.deactivate.run(userId, platform);
    return null;
  }

  return {
    ...account,
    cookie,
    token: account.token_encrypted ? decrypt(account.token_encrypted) : null,
    refreshToken: account.refresh_token_encrypted ? decrypt(account.refresh_token_encrypted) : null,
  };
};

const getCookie = (userId, platform) => {
  const account = getAccount(userId, platform);
  return account?.cookie || null;
};

const getToken = (userId, platform) => {
  const account = getAccount(userId, platform);
  return account?.token || null;
};

const getBindStatus = (userId, platform) => {
  const account = stmt.get.get(userId, platform);
  if (!account) {
    return { isBound: false };
  }

  if (account.expires_at) {
    const expiresAt = new Date(account.expires_at);
    if (expiresAt < new Date()) {
      stmt.deactivate.run(userId, platform);
      return { isBound: false };
    }
  }

  const cookie = account.cookie_encrypted ? decrypt(account.cookie_encrypted) : null;
  if (account.cookie_encrypted && cookie === null) {
    logger.warn(`Cookie解密失败，停用账号 ${userId} 的 ${platform} 绑定`);
    stmt.deactivate.run(userId, platform);
    return { isBound: false };
  }

  // 校验 platform_user_id 是否有效
  if (!account.platform_user_id || account.platform_user_id === '') {
    logger.warn(`平台用户ID为空，停用账号 ${userId} 的 ${platform} 绑定`);
    stmt.deactivate.run(userId, platform);
    return { isBound: false };
  }

  return {
    isBound: true,
    platform,
    userInfo: {
      id: account.platform_user_id,
      username: account.platform_username,
    },
  };
};

const getAllBindings = (userId) => {
  const accounts = stmt.getAllByUser.all(userId);
  return accounts.map(account => {
    if (account.expires_at) {
      const expiresAt = new Date(account.expires_at);
      if (expiresAt < new Date()) {
        return null;
      }
    }
    return {
      platform: account.platform,
      isBound: true,
      userInfo: {
        id: account.platform_user_id,
        username: account.platform_username,
      },
    };
  }).filter(Boolean);
};

const unbindAccount = (userId, platform) => {
  stmt.delete.run(userId, platform);
  return { success: true, message: `已解绑 ${platform} 账号` };
};

const deactivateAccount = (userId, platform) => {
  stmt.deactivate.run(userId, platform);
  return { success: true };
};

module.exports = {
  encrypt,
  decrypt,
  saveAccount,
  getAccount,
  getCookie,
  getToken,
  getBindStatus,
  getAllBindings,
  unbindAccount,
  deactivateAccount,
};
