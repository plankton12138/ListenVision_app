const platformService = require('./platformService');
const { logger } = require('../utils/logger');

const NETEASE_API_BASE = process.env.NETEASE_API_BASE || 'https://163api.qijieya.cn';
const PLATFORM = 'netease';

const httpGet = async (url, headers = {}, timeout = 10000) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        ...headers,
      },
      signal: controller.signal,
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

const httpPost = async (url, body, headers = {}, timeout = 10000) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        ...headers,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
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

const buildUrl = (endpoint, params = {}) => {
  const url = new URL(`${NETEASE_API_BASE}${endpoint}`);
  url.searchParams.set('timestamp', Date.now().toString());
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      url.searchParams.set(key, value.toString());
    }
  });
  return url.toString();
};

const getQRCode = async () => {
  try {
    const keyData = await httpGet(buildUrl('/login/qr/key'));

    if (keyData.code !== 200) {
      throw new Error(keyData.message || '获取二维码Key失败');
    }

    const key = keyData.data.unikey;
    const qrData = await httpGet(buildUrl('/login/qr/create', { key, qrimg: 'true' }));

    if (qrData.code !== 200) {
      throw new Error(qrData.message || '获取二维码失败');
    }

    return {
      key,
      qrimg: qrData.data.qrimg,
      qrurl: qrData.data.qrurl,
    };
  } catch (error) {
    throw new Error(`获取二维码失败: ${error.message}`);
  }
};

const checkQRLoginStatus = async (key) => {
  try {
    const data = await httpGet(buildUrl('/login/qr/check', { key }));

    logger.debug('[Netease] QR check 原始响应: %j', {
      code: data.code,
      cookieType: Array.isArray(data.cookie) ? 'array' : typeof data.cookie,
      cookieLength: Array.isArray(data.cookie) ? data.cookie.length : (data.cookie ? data.cookie.length : 0),
    });

    const statusMap = {
      800: 'expired',
      801: 'pending',
      802: 'scanned',
      803: 'success',
    };

    const status = statusMap[data.code] || 'unknown';

    let cookie = data.cookie || null;
    if (Array.isArray(cookie)) {
      logger.debug('[Netease] Cookie 是数组格式，原始值: %j', cookie);
      cookie = cookie.map(c => c.split(';')[0]).join('; ');
      logger.debug('[Netease] Cookie 转换后: %s', cookie);
    } else if (cookie) {
      logger.debug('[Netease] Cookie 是字符串格式: %s', cookie.substring(0, 100) + '...');
    }

    return {
      code: data.code,
      status,
      message: data.message || data.msg || '',
      cookie,
    };
  } catch (error) {
    throw new Error(`检查二维码状态失败: ${error.message}`);
  }
};

/**
 * 获取当前登录用户信息
 * @param {string} cookie - 登录后的 Cookie
 * @returns {Promise<{id: string, username: string, avatar: string}>} 用户信息
 */
const getCurrentUserInfo = async (cookie) => {
  try {
    logger.debug('[Netease] /user/account 请求 Cookie: %s', cookie ? cookie.substring(0, 100) + '...' : 'null');

    const data = await httpGet(buildUrl('/user/account'), {
      'Cookie': cookie,
    });

    logger.debug('[Netease] /user/account 完整响应: %j', data);

    // 处理不同可能的返回结构
    // 结构1: { code: 200, profile: {...} }
    // 结构2: { code: 200, account: {...}, profile: {...} }
    let profile = data.profile;
    let account = data.account;

    if (!profile && data.bindings) {
      // 尝试从其他字段获取
      profile = data;
    }

    if (!profile && !account) {
      throw new Error(`无法获取用户资料，响应: ${JSON.stringify(data).substring(0, 200)}`);
    }

    // 优先使用 profile，否则使用 account
    const userId = profile?.userId || account?.id;
    const nickname = profile?.nickname || profile?.nickName || account?.userName;
    const avatar = profile?.avatarUrl || profile?.avatarImgUrl;

    if (!userId) {
      throw new Error(`无法获取用户ID，响应: ${JSON.stringify(data).substring(0, 200)}`);
    }

    return {
      id: userId.toString(),
      username: nickname || '',
      avatar: avatar || '',
    };
  } catch (error) {
    logger.error('[Netease] 获取用户信息失败: %s', error.message);
    throw new Error(`获取用户信息失败: ${error.message}`);
  }
};

const loginWithCellphone = async (phone, password, countrycode = '86') => {
  try {
    const data = await httpGet(buildUrl('/login/cellphone', { phone, password, countrycode }));

    if (data.code !== 200) {
      throw new Error(data.message || data.msg || '登录失败');
    }

    return {
      success: true,
      userInfo: {
        id: data.profile?.userId?.toString() || data.account?.id?.toString(),
        username: data.profile?.nickname || '',
        avatar: data.profile?.avatarUrl || '',
      },
      cookie: data.cookie || null,
    };
  } catch (error) {
    throw new Error(`手机号登录失败: ${error.message}`);
  }
};

const saveAccount = async (userId, accountData) => {
  return platformService.saveAccount(userId, PLATFORM, accountData);
};

const getCookie = (userId) => {
  return platformService.getCookie(userId, PLATFORM);
};

const getAccount = (userId) => {
  return platformService.getAccount(userId, PLATFORM);
};

const getBindStatus = (userId) => {
  return platformService.getBindStatus(userId, PLATFORM);
};

const unbindAccount = (userId) => {
  return platformService.unbindAccount(userId, PLATFORM);
};

const search = async (keywords, options = {}) => {
  const { limit = 30, offset = 0, type = 1 } = options;

  try {
    const data = await httpGet(buildUrl('/search', { keywords, limit, offset, type }));

    if (data.code !== 200) {
      throw new Error(data.message || '搜索失败');
    }

    const result = data.result || {};
    const songs = result.songs || [];

    return {
      keywords,
      songs: songs.map(song => ({
        id: song.id,
        name: song.name,
        artist: song.artists?.map(a => a.name).join(', ') || '',
        album: song.album?.name || '',
        cover: song.album?.artist?.picUrl || song.album?.picUrl || '',
        duration: song.duration,
      })),
      songCount: result.songCount || songs.length,
    };
  } catch (error) {
    throw new Error(`搜索失败: ${error.message}`);
  }
};

const getSongDetail = async (ids, userId = null) => {
  const idStr = Array.isArray(ids) ? ids.join(',') : ids.toString();

  const headers = {};
  if (userId) {
    const cookie = getCookie(userId);
    if (cookie) {
      headers['Cookie'] = cookie;
    }
  }

  try {
    const data = await httpGet(buildUrl('/song/detail', { ids: idStr }), headers);

    if (data.code !== 200) {
      throw new Error(data.message || '获取歌曲详情失败');
    }

    const songs = data.songs || [];

    return {
      songs: songs.map(song => ({
        id: song.id,
        name: song.name,
        artist: song.ar?.map(a => a.name).join(', ') || '',
        album: song.al?.name || '',
        cover: song.al?.picUrl || '',
        duration: song.dt,
      })),
    };
  } catch (error) {
    throw new Error(`获取歌曲详情失败: ${error.message}`);
  }
};

const getSongUrl = async (id, userId = null) => {
  const headers = {};
  if (userId) {
    const cookie = getCookie(userId);
    if (cookie) {
      headers['Cookie'] = cookie;
    }
  }

  try {
    const data = await httpGet(buildUrl('/song/url', { id }), headers);

    if (data.code !== 200) {
      throw new Error(data.message || '获取歌曲URL失败');
    }

    const urlData = data.data?.[0];

    if (!urlData || !urlData.url) {
      return {
        id,
        url: null,
        message: '无法获取播放链接，可能需要VIP或版权限制',
      };
    }

    return {
      id,
      url: urlData.url,
      size: urlData.size,
      type: urlData.type,
      br: urlData.br,
    };
  } catch (error) {
    throw new Error(`获取歌曲URL失败: ${error.message}`);
  }
};

const getPlaylistDetail = async (id, userId = null) => {
  const headers = {};
  if (userId) {
    const cookie = getCookie(userId);
    if (cookie) {
      headers['Cookie'] = cookie;
    }
  }

  try {
    const data = await httpGet(buildUrl('/playlist/detail', { id }), headers);

    if (data.code !== 200) {
      throw new Error(data.message || '获取歌单详情失败');
    }

    const playlist = data.playlist;

    return {
      id: playlist.id,
      name: playlist.name,
      cover: playlist.coverImgUrl,
      description: playlist.description,
      playCount: playlist.playCount,
      trackCount: playlist.trackCount,
      creator: {
        id: playlist.creator?.userId,
        name: playlist.creator?.nickname,
        avatar: playlist.creator?.avatarUrl,
      },
      tracks: (playlist.tracks || []).map(track => ({
        id: track.id,
        name: track.name,
        artist: track.ar?.map(a => a.name).join(', ') || '',
        album: track.al?.name || '',
        cover: track.al?.picUrl || '',
        duration: track.dt,
      })),
    };
  } catch (error) {
    throw new Error(`获取歌单详情失败: ${error.message}`);
  }
};

const getLyric = async (id) => {
  try {
    const data = await httpGet(buildUrl('/lyric', { id }));

    if (data.code !== 200) {
      throw new Error(data.message || '获取歌词失败');
    }

    return {
      id,
      lyric: data.lrc?.lyric || '',
      tlyric: data.tlyric?.lyric || '',
    };
  } catch (error) {
    throw new Error(`获取歌词失败: ${error.message}`);
  }
};

const getUserPlaylist = async (userId, uid) => {
  const headers = {};
  const cookie = getCookie(userId);
  if (cookie) {
    headers['Cookie'] = cookie;
  }

  try {
    const data = await httpGet(buildUrl('/user/playlist', { uid }), headers);

    if (data.code !== 200) {
      throw new Error(data.message || '获取用户歌单失败');
    }

    const playlists = data.playlist || [];

    return {
      playlists: playlists.map(pl => ({
        id: pl.id,
        name: pl.name,
        cover: pl.coverImgUrl,
        description: pl.description,
        playCount: pl.playCount,
        trackCount: pl.trackCount,
      })),
    };
  } catch (error) {
    throw new Error(`获取用户歌单失败: ${error.message}`);
  }
};

module.exports = {
  PLATFORM,
  getQRCode,
  checkQRLoginStatus,
  getCurrentUserInfo,
  loginWithCellphone,
  saveAccount,
  getCookie,
  getAccount,
  getBindStatus,
  unbindAccount,
  search,
  getSongDetail,
  getSongUrl,
  getPlaylistDetail,
  getLyric,
  getUserPlaylist,
};
