const crypto = require('crypto');
const db = require('../config/database');
const { logger } = require('../utils/logger');

/**
 * B站API集成服务
 *
 * 功能：
 * 1. QR码登录
 * 2. Cookie管理（加密存储）
 * 3. 视频信息获取
 * 4. 音频流URL获取
 * 5. UP主视频列表
 * 6. 搜索功能
 *
 * API参考: https://socialsisteryi.github.io/bilibili-API-collect/
 */

// ==================== 加密工具 ====================

// 使用固定密钥（生产环境应通过环境变量设置）
// 通过 SHA256 哈希确保密钥长度为 32 字节（AES-256 要求）
const keyMaterial = process.env.BILI_COOKIE_KEY || 'ListenVisionBilibiliCookieKey2024';
const ENCRYPTION_KEY = crypto.createHash('sha256').update(keyMaterial).digest();
const IV_LENGTH = 16;
const ALGORITHM = 'aes-256-cbc';

/**
 * 加密Cookie
 */
const encryptCookie = (cookie) => {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(cookie, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return `${iv.toString('hex')}:${encrypted}`;
};

/**
 * 解密Cookie（返回null表示解密失败）
 */
const decryptCookie = (encryptedData) => {
  try {
    const parts = encryptedData.split(':');
    const iv = Buffer.from(parts.shift(), 'hex');
    const encrypted = parts.join(':');
    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (error) {
    logger.error('Cookie解密失败: %s', error.message);
    return null;  // 返回null而不是抛出异常
  }
};

// ==================== 预编译语句 ====================

const stmt = {
  // B站账号相关
  insertBiliAccount: db.prepare(`
    INSERT INTO bilibili_accounts (user_id, bili_user_id, bili_username, cookie_encrypted, refresh_token_encrypted, is_active, expires_at)
    VALUES (?, ?, ?, ?, ?, 1, ?)
  `),
  insertBiliAccountWithoutRefresh: db.prepare(`
    INSERT INTO bilibili_accounts (user_id, bili_user_id, bili_username, cookie_encrypted, is_active, expires_at)
    VALUES (?, ?, ?, ?, 1, ?)
  `),
  updateBiliAccount: db.prepare(`
    UPDATE bilibili_accounts
    SET bili_user_id = ?, bili_username = ?, cookie_encrypted = ?, is_active = 1, updated_at = datetime('now')
    WHERE id = ?
  `),
  updateBiliAccountWithRefresh: db.prepare(`
    UPDATE bilibili_accounts
    SET bili_user_id = ?, bili_username = ?, cookie_encrypted = ?, refresh_token_encrypted = ?, expires_at = ?, is_active = 1, updated_at = datetime('now')
    WHERE id = ?
  `),
  getActiveBiliAccount: db.prepare(`
    SELECT * FROM bilibili_accounts WHERE user_id = ? AND is_active = 1
  `),
  getBiliAccountById: db.prepare(`
    SELECT * FROM bilibili_accounts WHERE id = ?
  `),
  getAllBiliAccounts: db.prepare(`
    SELECT * FROM bilibili_accounts WHERE is_active = 1
  `),
  deactivateBiliAccount: db.prepare(`
    UPDATE bilibili_accounts SET is_active = 0 WHERE user_id = ?
  `),
  deleteBiliAccount: db.prepare(`
    DELETE FROM bilibili_accounts WHERE user_id = ?
  `),

  // 元数据缓存相关
  getAudioMetadata: db.prepare(`
    SELECT * FROM audio_metadata_cache WHERE bvid = ?
  `),
  insertAudioMetadata: db.prepare(`
    INSERT OR REPLACE INTO audio_metadata_cache
    (bvid, title, artist, duration, cover_url, audio_url, cid, metadata, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
  `),

  // 音频内容缓存相关（存储转换后的音频数据）
  getCachedAudio: db.prepare(`
    SELECT data, content_type, created_at FROM audio_content_cache
    WHERE bvid = ? AND created_at > datetime('now', '-24 hours')
  `),
  insertCachedAudio: db.prepare(`
    INSERT OR REPLACE INTO audio_content_cache 
    (bvid, data, content_type, created_at)
    VALUES (?, ?, ?, datetime('now'))
  `),
  // 搜索历史相关
  insertSearchHistory: db.prepare(`
    INSERT INTO search_history (user_id, keyword, result_count) VALUES (?, ?, ?)
  `),
  getRecentSearches: db.prepare(`
    SELECT DISTINCT keyword FROM search_history WHERE user_id = ? ORDER BY created_at DESC LIMIT 10
  `),
};

// ==================== HTTP请求工具 ====================

/**
 * 通用HTTP请求函数（带超时）
 * @param {string} url - 请求URL
 * @param {Object} headers - 请求头
 * @param {number} timeout - 超时时间（毫秒），默认10000ms
 */
const httpGet = async (url, headers = {}, timeout = 10000) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com/',
        ...headers
      },
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error(`请求超时（${timeout}ms）`);
    }
    throw error;
  }
};

/**
 * POST请求（用于需要body的API）
 */
const httpPost = async (url, body, headers = {}) => {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://www.bilibili.com/',
      ...headers
    },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json();
};

// ==================== QR码登录（Web端） ====================

/**
 * 获取QR码登录凭证
 *
 * API: GET https://passport.bilibili.com/x/passport-login/web/qrcode/generate
 *
 * @returns {Object} { qrcodeKey, qrCodeUrl, expires_in }
 */
const getQRCode = async () => {
  try {
    const url = 'https://passport.bilibili.com/x/passport-login/web/qrcode/generate';
    const data = await httpGet(url);

    if (data.code !== 0) {
      throw new Error(data.message || '获取QR码失败');
    }

    return {
      qrcodeKey: data.data.qrcode_key,
      qrCodeUrl: data.data.url,
      expires_in: data.data.expires_in || 180
    };
  } catch (error) {
    throw new Error(`获取QR码失败: ${error.message}`);
  }
};

/**
 * 检查QR码登录状态
 *
 * API: GET https://passport.bilibili.com/x/passport-login/web/qrcode/poll?qrcode_key={qrcode_key}
 *
 * @param {string} qrcodeKey - QR码凭证
 * @returns {Object} { code, message, status, userInfo?, cookie? }
 */
const checkQRLoginStatus = async (qrcodeKey) => {
  try {
    const url = `https://passport.bilibili.com/x/passport-login/web/qrcode/poll?qrcode_key=${qrcodeKey}`;
    const data = await httpGet(url);

    logger.debug('[QR码检查] 响应: %o', data);

    // Web端状态码在 data.data.code (数字类型):
    // 0: 登录成功
    // 86038: 二维码已失效
    // 86090: 二维码已扫描待确认
    // 86101: 未扫码

    const statusCode = data.data?.code;
    logger.debug('[QR码检查] 状态码: %d', statusCode);

    const statusMap = {
      86101: 'pending',
      86038: 'expired',
      86090: 'scanned',
      0: 'success'
    };

    const status = statusMap[statusCode] || 'unknown';

    let cookie = null;
    let userInfo = null;

    // 登录成功，从响应体的 url 字段提取 Cookie
    if (statusCode === 0 && data.data?.url) {
      const loginUrl = data.data.url;

      // URL 格式: https://passport.biligame.com/crossDomain?DedeUserID=xxx&DedeUserID__ckMd5=xxx&SESSDATA=xxx&bili_jct=xxx&...
      try {
        const urlObj = new URL(loginUrl);
        const params = new URLSearchParams(urlObj.search);

        const cookieParts = [];
        const cookieKeys = ['DedeUserID', 'DedeUserID__ckMd5', 'SESSDATA', 'bili_jct', 'sid'];

        cookieKeys.forEach(key => {
          const value = params.get(key);
          if (value) {
            cookieParts.push(`${key}=${value}`);
          }
        });

        if (cookieParts.length > 0) {
          cookie = cookieParts.join('; ');
          logger.info('[QR码检查] Cookie提取成功');

          // 提取用户信息
          const dedeUserId = params.get('DedeUserID');
          if (dedeUserId) {
            userInfo = {
              mid: dedeUserId,
              uid: dedeUserId,
              uname: '' // 用户名需要额外API获取
            };
            logger.debug('[QR码检查] 用户信息: %o', userInfo);
          }
        } else {
          logger.warn('[QR码检查] 未找到Cookie参数');
        }
      } catch (e) {
        logger.error('解析登录URL失败: %s', e.message);
      }
    }

    logger.debug('[QR码检查] 返回状态: %s, Cookie存在: %s', status, !!cookie);

    return {
      code: data.code,
      message: data.message,
      status,
      statusCode,
      cookie,
      userInfo,
      refreshUrl: data.data?.url || null,
      refreshToken: data.data?.refresh_token || null,
      timestamp: data.data?.timestamp || 0
    };
  } catch (error) {
    throw new Error(`检查QR码状态失败: ${error.message}`);
  }
};

/**
 * 从登录跳转URL中解析用户信息
 */
const parseUrlInfo = (url) => {
  if (!url) return null;
  try {
    const match = url.match(/https:\/\/www\.bilibili\.com\/[^?]*\?(.*)/);
    if (!match) return null;

    const params = new URLSearchParams(match[1]);
    return {
      mid: params.get('mid') || params.get('DedeUserID'),
      uname: decodeURIComponent(params.get('name') || '')
    };
  } catch (e) {
    return null;
  }
};

/**
 * 从登录响应中提取Cookie
 * Web端登录成功后，需要从响应头或后续请求中获取Cookie
 * 这里返回一个标记，实际Cookie需要通过poll的后续请求获取
 */
const extractCookiesFromUrl = (url) => {
  // Web端QR码登录后，Cookie包含在跳转过程中
  // 实际实现需要解析响应头或使用OAuth授权
  // 这里返回基础信息，完整Cookie获取需要额外处理
  if (!url) return null;

  try {
    const match = url.match(/https:\/\/www\.bilibili\.com\/[^?]*\?(.*)/);
    if (!match) return null;

    const params = new URLSearchParams(match[1]);
    const cookies = [];

    // 从URL参数提取可用的身份信息
    const userId = params.get('mid') || params.get('DedeUserID');
    if (userId) cookies.push(`DedeUserID=${userId}`);

    // 注意：完整的Cookie（SESSDATA等）需要后续处理
    // 实际应用中可能需要通过OAuth流程获取
    return {
      partial: cookies.join('; '),
      url, // 保存原始URL用于后续处理
      needsCompletion: true
    };
  } catch (e) {
    return null;
  }
};

/**
 * 构建Cookie字符串
 */
const buildCookieString = (loginData) => {
  const cookies = [];
  if (loginData.refresh_token) cookies.push(`refresh_token=${loginData.refresh_token}`);
  if (loginData.access_token) cookies.push(`access_token=${loginData.access_token}`);
  if (loginData.timestamp) cookies.push(`timestamp=${loginData.timestamp}`);
  return cookies.join('; ');
};

// ==================== Cookie管理 ====================

/**
 * 保存Cookie到数据库
 *
 * @param {number} userId - 用户ID
 * @param {string} cookie - Cookie字符串
 * @param {Object} userInfo - B站用户信息
 */
const saveCookie = async (userId, cookie, userInfo = {}, refreshToken = null) => {
  const encrypted = encryptCookie(cookie);
  const biliUserId = userInfo.mid || userInfo.uid || '';
  const biliUsername = userInfo.uname || '';

  const encryptedRefreshToken = refreshToken ? encryptCookie(refreshToken) : null;

  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    .toISOString().replace('T', ' ').substring(0, 19);

  const existing = stmt.getActiveBiliAccount.get(userId);

  if (existing) {
    if (encryptedRefreshToken) {
      stmt.updateBiliAccountWithRefresh.run(
        biliUserId, biliUsername, encrypted, encryptedRefreshToken, expiresAt, existing.id
      );
    } else {
      stmt.updateBiliAccount.run(biliUserId, biliUsername, encrypted, existing.id);
    }
  } else {
    if (encryptedRefreshToken) {
      stmt.insertBiliAccount.run(
        userId, biliUserId, biliUsername, encrypted, encryptedRefreshToken, expiresAt
      );
    } else {
      stmt.insertBiliAccountWithoutRefresh.run(
        userId, biliUserId, biliUsername, encrypted, expiresAt
      );
    }
  }

  return { success: true };
};

/**
 * 获取用户的Cookie
 *
 * @param {number} userId - 用户ID
 * @returns {string|null} Cookie字符串
 */
const getCookie = (userId) => {
  const account = stmt.getActiveBiliAccount.get(userId);
  if (!account) return null;

  // 检查是否过期
  if (account.expires_at) {
    const expiresAt = new Date(account.expires_at);
    if (expiresAt < new Date()) {
      // 过期则停用
      stmt.deactivateBiliAccount.run(userId);
      return null;
    }
  }

  const cookie = decryptCookie(account.cookie_encrypted);
  // 解密失败则停用该账号
  if (cookie === null) {
    logger.warn(`Cookie解密失败，停用账号 ${userId} 的B站绑定`);
    stmt.deactivateBiliAccount.run(userId);
  }
  return cookie;
};

/**
 * 刷新Cookie（如果即将过期）
 *
 * @param {number} userId - 用户ID
 * @returns {boolean} 是否成功
 */
const refreshCookie = async (userId) => {
  try {
    const account = stmt.getActiveBiliAccount.get(userId);
    if (!account) {
      logger.warn('[Cookie刷新] 账号不存在或已停用: userId=%d', userId);
      return false;
    }

    if (!account.refresh_token_encrypted) {
      logger.warn('[Cookie刷新] 无 refresh_token，无法刷新: userId=%d', userId);
      return false;
    }

    const refreshToken = decryptCookie(account.refresh_token_encrypted);
    if (!refreshToken) {
      logger.warn('[Cookie刷新] refresh_token 解密失败: userId=%d', userId);
      return false;
    }

    const csrf = _extractBiliJct(account.cookie_encrypted);
    const currentCookie = decryptCookie(account.cookie_encrypted);

    const url = 'https://passport.bilibili.com/x/passport-login/web/cookie/refresh';
    const response = await httpPost(
      url,
      {
        refresh_token: refreshToken,
        csrf: csrf,
      },
      {
        'Cookie': currentCookie || '',
      }
    );

    logger.debug('[Cookie刷新] API响应: %o', response);

    if (response.code !== 0) {
      logger.error('[Cookie刷新] 失败: %s (code=%d)', response.message, response.code);
      
      // -101: 账号未登录, -6: refresh_token无效, -7: refresh_token过期
      if (response.code === -101 || response.code === -6 || response.code === -7) {
        stmt.deactivateBiliAccount.run(userId);
        logger.warn('[Cookie刷新] 账号已过期，已停用: userId=%d', userId);
      }
      return false;
    }

    const newRefreshToken = response.data?.refresh_token;
    const newCookieParts = [];

    if (response.data?.refresh_csrf) {
      // 更新 Cookie 中的 bili_jct（如果变了）
      // B站刷新API返回的是新的 refresh_token，Cookie 可能需要重新构建
      logger.info('[Cookie刷新] 获取到新的 refresh_token');
    }

    if (newRefreshToken) {
      const encryptedNewRefreshToken = encryptCookie(newRefreshToken);
      const newExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        .toISOString().replace('T', ' ').substring(0, 19);

      stmt.updateBiliAccountWithRefresh.run(
        account.bili_user_id,
        account.bili_username,
        account.cookie_encrypted,
        encryptedNewRefreshToken,
        newExpiresAt,
        account.id
      );

      logger.info('[Cookie刷新] 成功: userId=%d', userId);
      return true;
    }

    return false;
  } catch (error) {
    logger.error('[Cookie刷新] 异常: %s', error.message);
    return false;
  }
};

/**
 * 从加密Cookie中提取 bili_jct
 */
const _extractBiliJct = (cookieEncrypted) => {
  try {
    const cookie = decryptCookie(cookieEncrypted);
    if (!cookie) return '';
    const match = cookie.match(/bili_jct=([^;]+)/);
    return match ? match[1] : '';
  } catch (e) {
    return '';
  }
};

/**
 * 获取绑定状态
 *
 * @param {number} userId - 用户ID
 * @returns {Object} 绑定信息
 */
const getBindStatus = (userId) => {
  const account = stmt.getActiveBiliAccount.get(userId);
  if (!account) {
    return { isBound: false };
  }

  // 检查是否过期
  if (account.expires_at) {
    const expiresAt = new Date(account.expires_at);
    if (expiresAt < new Date()) {
      // 过期则停用
      stmt.deactivateBiliAccount.run(userId);
      return { isBound: false };
    }
  }

  // 检查Cookie是否能正常解密
  const cookie = decryptCookie(account.cookie_encrypted);
  if (cookie === null) {
    // 解密失败，停用账号
    logger.warn(`Cookie解密失败，停用账号 ${userId} 的B站绑定`);
    stmt.deactivateBiliAccount.run(userId);
    return { isBound: false };
  }

  return {
    isBound: true,
    userInfo: {
      mid: account.bili_user_id,
      uid: account.bili_user_id,
      uname: account.bili_username,
      avatar: '' // 头像需要从B站API获取
    }
  };
};

/**
 * 解绑B站账号
 *
 * @param {number} userId - 用户ID
 * @returns {Object} 成功信息
 */
const unbindAccount = (userId) => {
  stmt.deleteBiliAccount.run(userId);
  return { success: true, message: '已解绑B站账号' };
};

// ==================== 视频信息获取 ====================

/**
 * 获取视频信息
 *
 * API: GET https://api.bilibili.com/x/web-interface/view?bvid={bvid}
 *
 * @param {string} bvid - 视频BVID
 * @returns {Object} 视频信息
 */
const getVideoInfo = async (bvid) => {
  try {
    const url = `https://api.bilibili.com/x/web-interface/view?bvid=${bvid}`;
    const data = await httpGet(url);

    if (data.code !== 0) {
      throw new Error(data.message || '获取视频信息失败');
    }

    const info = data.data;

    // 获取统计数据（B站API结构：data.stat）
    const stat = info.stat || {};

    // 获取音频流URL（用于下载）
    let streamUrl = null;
    let audioBaseUrl = null;
    try {
      const fnval = 16;
      const audioData = await httpGet(`https://api.bilibili.com/x/player/playurl?bvid=${bvid}&cid=${info.cid}&fnval=${fnval}&qn=127`);
      if (audioData.code === 0 && audioData.data?.dash?.audio?.length > 0) {
        const audio = audioData.data.dash.audio.reduce((prev, curr) => {
          return (curr.bandwidth || 0) > (prev.bandwidth || 0) ? curr : prev;
        });
        streamUrl = audio.baseUrl;
        audioBaseUrl = audio.baseUrl;
      }
    } catch (e) {
      logger.debug(`[getVideoInfo] 获取音频流失败: ${e.message}`);
    }

    return {
      bvid: info.bvid,
      title: info.title,
      desc: info.desc,
      pic: info.pic,         // 封面URL (原名)
      cover: info.pic || '', // 封面URL (别名)
      duration: info.duration,
      pubdate: info.pubdate, // 发布时间戳
      owner: {
        mid: info.owner?.mid,
        name: info.owner?.name,
        face: info.owner?.face || ''
      },
      cid: info.cid, // 视频分P ID，用于获取播放URL
      stream_url: streamUrl, // 音频流URL（用于下载）
      audio_base_url: audioBaseUrl, // 音频流基础URL（别名）
      stat: {
        view: stat.view || 0,      // 播放
        like: stat.like || 0,      // 点赞
        coin: stat.coin || 0,      // 投币
        favorite: stat.favorite || 0, // 收藏
        share: stat.share || 0,    // 分享
        danmaku: stat.danmaku || 0 // 弹幕
      },
      pages: info.pages?.map(p => ({
        cid: p.cid,
        page: p.page,
        part: p.part,
        duration: p.duration
      })) || []
    };
  } catch (error) {
    throw new Error(`获取视频信息失败: ${error.message}`);
  }
};

/**
 * 获取音频流URL
 *
 * API: GET https://api.bilibili.com/x/player/playurl?bvid={bvid}&cid={cid}&fnval=16
 *
 * @param {string} bvid - 视频BVID
 * @param {number} cid - 视频分P ID（可选，为空时自动获取）
 * @param {number} userId - 用户ID（用于获取Cookie）
 * @returns {Object} 音频流信息
 */
const getAudioStream = async (bvid, cid = null, userId = null) => {
  try {
    let videoInfo = null;

    // 如果没有提供 cid，先获取视频信息
    if (!cid) {
      videoInfo = await getVideoInfo(bvid);
      cid = videoInfo.cid;
    }

    // 构建请求URL
    const fnval = 16; // 16表示只返回音频流
    const url = `https://api.bilibili.com/x/player/playurl?bvid=${bvid}&cid=${cid}&fnval=${fnval}&qn=127`;

    const headers = {};
    // 如果用户绑定了B站账号，使用Cookie获取更高质量的音频
    if (userId) {
      const cookie = getCookie(userId);
      if (cookie) {
        headers['Cookie'] = cookie;
      }
    }

    const data = await httpGet(url, headers);

    if (data.code !== 0) {
      throw new Error(data.message || '获取音频流失败');
    }

    // 解析音频流
    const dash = data.data?.dash;
    if (!dash || !dash.audio || dash.audio.length === 0) {
      throw new Error('未找到音频流');
    }

    // 选择最高质量的音频流
    const audio = dash.audio.reduce((prev, curr) => {
      return (curr.bandwidth || 0) > (prev.bandwidth || 0) ? curr : prev;
    });

    return {
      bvid,
      title: videoInfo?.title,
      baseUrl: audio.baseUrl,
      url: audio.baseUrl,
      bandwidth: audio.bandwidth,
      mimeType: audio.mimeType,
      codecs: audio.codecs,
      duration: Math.floor((data.data?.timelength || 0) / 1000) // 转换为秒
    };
  } catch (error) {
    throw new Error(`获取音频流失败: ${error.message}`);
  }
};

// ==================== UP主相关 ====================

/**
 * 获取UP主视频列表
 *
 * API: GET https://api.bilibili.com/x/space/wbi/arc/search?mid={mid}&pn={page}&ps={pageSize}
 *
 * @param {string} mid - UP主ID
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @returns {Object} 视频列表
 */
const getUploaderVideos = async (mid, page = 1, pageSize = 20) => {
  try {
    // 构建WBI签名
    const wbiKey = await getWbiKey();
    const signedParams = signWbi({ mid, pn: page, ps: pageSize }, wbiKey);

    const url = `https://api.bilibili.com/x/space/wbi/arc/search?${new URLSearchParams(signedParams).toString()}`;
    const data = await httpGet(url);

    if (data.code !== 0) {
      throw new Error(data.message || '获取UP主视频失败');
    }

    const list = data.data?.list?.vlist || [];
    return {
      videos: list.map(v => ({
        bvid: v.bvid,
        title: v.title,
        description: v.description,
        cover: v.pic,
        duration: v.length,
        play: v.play,
        comment: v.comment,
        created: v.created
      })),
      page: data.data?.page?.pagen || page,
      pageSize: data.data?.page?.ps || pageSize,
      total: data.data?.page?.count || 0
    };
  } catch (error) {
    throw new Error(`获取UP主视频失败: ${error.message}`);
  }
};

// WBI签名缓存
let wbiKeyCache = null;
let wbiKeyExpireTime = 0;

/**
 * 获取WBI密钥
 * @param {number} userId - 用户ID（可选，用于获取Cookie）
 */
const getWbiKey = async (userId = null) => {
  // 检查缓存（基于用户的缓存）
  const cacheKey = userId ? `user_${userId}` : 'global';

  if (wbiKeyCache && wbiKeyCache.key === cacheKey && Date.now() < wbiKeyExpireTime) {
    logger.debug('[getWbiKey] Using cached key for %s', cacheKey);
    return wbiKeyCache;
  }

  logger.debug('[getWbiKey] Fetching WBI key from Bilibili...');

  // 构建请求头
  const headers = {};
  if (userId) {
    const cookie = getCookie(userId);
    if (cookie) {
      headers['Cookie'] = cookie;
      logger.debug('[getWbiKey] Using user cookie');
    }
  }

  // 获取WBI签名信息
  let data;
  try {
    data = await httpGet('https://api.bilibili.com/x/web-interface/nav', headers);
  } catch (error) {
    logger.error('[getWbiKey] HTTP request failed: %s', error.message);
    return { imgKey: '', subKey: '' };
  }

  logger.debug('[getWbiKey] Response code: %d, Has wbi_img: %s', data.code, !!data.data?.wbi_img);

  // 根据 bilibili-API-collect/docs/misc/sign/wbi.md
  // 未登录时 code=-101，但 wbi_img 仍然有效
  if (data.code !== 0 && data.code !== -101) {
    logger.error('[getWbiKey] API returned error: %s', data.message);
    return { imgKey: '', subKey: '' };
  }

  if (data.code === -101) {
    logger.debug('[getWbiKey] User not logged in, but WBI key is available');
  }

  if (!data.data?.wbi_img) {
    logger.error('[getWbiKey] No wbi_img in response');
    logger.debug('[getWbiKey] Response data keys: %o', Object.keys(data.data || {}));
    return { imgKey: '', subKey: '' };
  }

  const wbiImg = data.data.wbi_img;
  logger.debug('[getWbiKey] wbi_img: %o', wbiImg);

  const imgKey = wbiImg.img_url.split('/').pop().replace('.png', '');
  const subKey = wbiImg.sub_url.split('/').pop().replace('.png', '');

  logger.debug('[getWbiKey] Extracted keys - imgKey: %s, subKey: %s', imgKey, subKey);

  wbiKeyCache = { key: cacheKey, imgKey, subKey };
  wbiKeyExpireTime = Date.now() + 2 * 60 * 60 * 1000; // 2小时过期

  return wbiKeyCache;
};

/**
 * WBI签名混合密钥重排表
 * 来自 bilibili-API-collect/docs/misc/sign/wbi.md
 */
const MIXIN_KEY_ENC_TAB = [
  46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
  33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40,
  61, 26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11,
  36, 20, 34, 44, 52
];

/**
 * 生成混合密钥
 * @param {string} imgKey - 图片密钥
 * @param {string} subKey - 子密钥
 * @returns {string} 混合后的32位密钥
 */
const getMixinKey = (imgKey, subKey) => {
  const rawWbiKey = imgKey + subKey;
  return MIXIN_KEY_ENC_TAB
    .map(n => rawWbiKey[n])
    .join('')
    .slice(0, 32);
};

/**
 * WBI签名
 * @param {Object} params - 请求参数
 * @param {Object} wbiKey - WBI密钥对象 {imgKey, subKey}
 * @returns {Object} 签名后的参数
 */
const signWbi = (params, { imgKey, subKey }) => {
  // 生成混合密钥
  const mixinKey = getMixinKey(imgKey, subKey);
  logger.debug('[signWbi] mixinKey: %s', mixinKey);

  // 添加时间戳
  const wts = Math.floor(Date.now() / 1000);

  // 构建参数对象（包含wts）
  const paramsWithWts = {
    ...params,
    wts
  };

  // 按key排序
  const sortedKeys = Object.keys(paramsWithWts).sort();

  // 过滤并编码参数
  const chrFilter = /[!'()*]/g;
  const query = sortedKeys
    .map(key => {
      const value = paramsWithWts[key].toString().replace(chrFilter, '');
      return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
    })
    .join('&');

  logger.debug('[signWbi] query: %s', query);

  // 计算签名
  const w_rid = crypto
    .createHash('md5')
    .update(query + mixinKey)
    .digest('hex');

  logger.debug('[signWbi] w_rid: %s', w_rid);

  return {
    ...paramsWithWts,
    w_rid
  };
};

// ==================== 搜索功能 ====================

/**
 * 搜索B站视频
 *
 * API: GET https://api.bilibili.com/x/web-interface/wbi/search/type?search_type=video&keyword={keyword}
 *
 * @param {string} keyword - 搜索关键词
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @param {number} userId - 用户ID（用于记录搜索历史）
 * @returns {Object} 搜索结果
 */
const searchBilibili = async (keyword, page = 1, pageSize = 20, userId = null) => {
  try {
    // 记录搜索历史
    if (userId) {
      // 异步记录，不阻塞请求
      setTimeout(() => {
        try {
          stmt.insertSearchHistory.run(userId, keyword, 0);
        } catch (e) {
          // 忽略错误
        }
      }, 0);
    }

    // 获取WBI签名
    const wbiKey = await getWbiKey();
    const params = {
      search_type: 'video',
      keyword,
      pn: page,
      page_size: pageSize
    };
    const signedParams = signWbi(params, wbiKey);

    const url = `https://api.bilibili.com/x/web-interface/wbi/search/type?${new URLSearchParams(signedParams).toString()}`;

    const headers = {};
    // 如果有Cookie，添加到请求头
    if (userId) {
      const cookie = getCookie(userId);
      if (cookie) {
        headers['Cookie'] = cookie;
      }
    }

    const data = await httpGet(url, headers);

    if (data.code !== 0) {
      throw new Error(data.message || '搜索失败');
    }

    const results = data.data?.result || [];
    const videos = results
      .filter(r => r.type === 'video')
      .map(r => ({
        bvid: r.bvid || extractBvid(r.arcurl),
        title: cleanHtml(r.title),
        description: cleanHtml(r.description),
        cover: r.pic.startsWith('//') ? 'https:' + r.pic : r.pic,
        duration: r.duration,
        author: r.author,
        play: r.play,
        arcurl: r.arcurl
      }));

    // 更新搜索结果数量
    if (userId) {
      setTimeout(() => {
        try {
          db.prepare('UPDATE search_history SET result_count = ? WHERE id = (SELECT id FROM search_history WHERE user_id = ? AND keyword = ? ORDER BY created_at DESC LIMIT 1)')
            .run(videos.length, userId, keyword);
        } catch (e) {
          // 忽略错误
        }
      }, 0);
    }

    return {
      keyword,
      videos,
      page,
      pageSize,
      total: data.data?.numResults || videos.length
    };
  } catch (error) {
    throw new Error(`搜索失败: ${error.message}`);
  }
};

/**
 * 从URL提取BVID
 */
const extractBvid = (arcurl) => {
  const match = arcurl.match(/\/video\/(BV\w+)/);
  return match ? match[1] : '';
};

/**
 * 清理HTML标签
 */
const cleanHtml = (text) => {
  if (!text) return '';
  return text.replace(/<[^>]*>/g, '').replace(/&quot;/g, '"').replace(/&amp;/g, '&');
};

/**
 * 获取最近搜索历史
 *
 * @param {number} userId - 用户ID
 * @returns {Array} 搜索关键词列表
 */
const getRecentSearches = (userId) => {
  return stmt.getRecentSearches.all(userId).map(row => row.keyword);
};

/**
 * 获取搜索建议（联想词）
 *
 * 调用 B站搜索建议 API，根据输入关键词返回相关的搜索建议。
 *
 * @param {string} keyword - 输入关键词
 * @returns {Array} 搜索建议列表
 */
const getSearchSuggestions = async (keyword) => {
  try {
    if (!keyword || keyword.trim().length === 0) {
      return [];
    }

    // B站搜索建议 API
    const url = `https://api.bilibili.com/x/web-interface/search/suggest?keyword=${encodeURIComponent(keyword)}`;

    const data = await httpGet(url, {}, 5000);

    if (data.code !== 0) {
      logger.warn(`获取搜索建议失败: ${data.message}`);
      return [];
    }

    // 解析返回结果
    // B站返回格式: { code: 0, data: { tag: [{ ... }] } }
    const suggestions = [];

    if (data.data && data.data.tag) {
      for (const tag of data.data.tag) {
        if (tag.keyword) {
          suggestions.push(tag.keyword);
        }
        if (tag.value) {
          suggestions.push(tag.value);
        }
      }
    }

    // 去重并限制数量
    return [...new Set(suggestions)].slice(0, 10);
  } catch (error) {
    logger.warn(`获取搜索建议失败: ${error.message}`);
    return [];
  }
};

/**
 * 获取缓存的音频内容
 * @param {string} bvid - 视频ID
 * @returns {Object|null} 缓存的音频数据
 */
const getCachedAudio = (bvid) => {
  return stmt.getCachedAudio.get(bvid);
};

/**
 * 保存音频内容到缓存
 * @param {string} bvid - 视频ID
 * @param {Buffer} data - 音频数据
 * @param {string} contentType - 内容类型
 */
const insertCachedAudio = (bvid, data, contentType) => {
  stmt.insertCachedAudio.run(bvid, data, contentType);
};

// 启动时清理无效的绑定（使用旧密钥加密的数据）
const cleanupInvalidBindings = () => {
  try {
    const accounts = stmt.getAllBiliAccounts.all();
    let cleanedCount = 0;

    accounts.forEach(account => {
      // 尝试解密Cookie
      const cookie = decryptCookie(account.cookie_encrypted);
      if (cookie === null) {
        // 解密失败，停用该账号
        db.prepare('UPDATE bilibili_accounts SET is_active = 0 WHERE id = ?').run(account.id);
        cleanedCount++;
        logger.info(`清理无效绑定: 用户ID ${account.user_id}`);
      }
    });

    if (cleanedCount > 0) {
      logger.info(`清理了 ${cleanedCount} 个无效的B站绑定`);
    }
  } catch (error) {
    logger.error('清理无效绑定失败: %s', error.message);
  }
};

/**
 * 获取B站音乐区排行榜
 *
 * API: GET https://api.bilibili.com/x/web-interface/ranking/v2?rid=3
 *
 * rid=3 为音乐主分区，参考: docs/video/video_zone.md
 *
 * @param {number} userId - 用户ID（用于获取Cookie）
 * @param {number} page - 页码（暂不支持，API返回固定100个）
 * @param {number} pageSize - 每页数量（用于限制返回数量）
 * @returns {Object} 推荐视频列表
 */
const getRecommendedVideos = async (userId = null, page = 1, pageSize = 20) => {
  try {
    logger.info('[getRecommendedVideos] 开始: userId=%s, page=%d, pageSize=%d', userId, page, pageSize);

    const wbiKey = await getWbiKey(userId);

    if (!wbiKey.imgKey || !wbiKey.subKey) {
      logger.error('[getRecommendedVideos] WBI Key 获取失败');
      throw new Error('WBI签名密钥获取失败');
    }

    // 使用分区排行榜 API，rid=3 为音乐主分区
    const params = {
      rid: 3,           // 音乐主分区
      type: 'all',      // 全部类型
    };
    const signedParams = signWbi(params, wbiKey);

    const url = `https://api.bilibili.com/x/web-interface/ranking/v2?${new URLSearchParams(signedParams).toString()}`;

    const headers = {};
    if (userId) {
      const cookie = getCookie(userId);
      if (cookie) {
        headers['Cookie'] = cookie;
        logger.info('[getRecommendedVideos] 使用用户Cookie (长度: %d)', cookie.length);
      }
    }

    const data = await httpGet(url, headers);
    logger.info('[getRecommendedVideos] B站API响应: code=%d', data.code);

    if (data.code !== 0) {
      throw new Error(data.message || '获取音乐区排行榜失败');
    }

    // ranking/v2 返回 data.list 数组
    const list = data.data?.list || [];

    // 根据 pageSize 截取返回结果
    const startIndex = (page - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const paginatedList = list.slice(startIndex, endIndex);

    logger.info('[getRecommendedVideos] 成功: 返回 %d 个视频（第 %d 页，每页 %d）',
                paginatedList.length, page, pageSize);

    return {
      videos: paginatedList.map(item => ({
        bvid: item.bvid,
        title: item.title,
        cover: item.pic,
        duration: item.duration,
        author: item.owner?.name,
        play: item.stat?.view,
        description: item.desc,
        pubdate: item.pubdate,
      })),
      page,
      pageSize,
      total: list.length,
    };
  } catch (error) {
    logger.error('[getRecommendedVideos] 异常: %s', error.message);
    throw new Error(`获取音乐区推荐失败: ${error.message}`);
  }
};

module.exports = {
  // QR码登录
  getQRCode,
  checkQRLoginStatus,

  // Cookie管理
  saveCookie,
  getCookie,
  refreshCookie,
  getBindStatus,
  unbindAccount,

  // 视频信息
  getVideoInfo,
  getAudioStream,

  // 音频内容缓存
  getCachedAudio,
  insertCachedAudio,

  // UP主相关
  getUploaderVideos,

  // 搜索功能
  searchBilibili,
  getSearchSuggestions,
  getRecentSearches,

  // 推荐功能
  getRecommendedVideos,

  // WBI签名（用于分区推荐）
  getWbiKey,
  signWbi,

  // 工具函数
  encryptCookie,
  decryptCookie,

  // 初始化
  cleanupInvalidBindings
};

// 自动执行清理
cleanupInvalidBindings();
