const neteaseService = require('../services/neteaseService');
const { successResponse, errorResponse } = require('../utils/response');
const { logger } = require('../utils/logger');

const getQRCode = async (req, res) => {
  try {
    const data = await neteaseService.getQRCode();
    successResponse(res, data, '获取二维码成功');
  } catch (error) {
    logger.error('获取二维码失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const checkQRLoginStatus = async (req, res) => {
  try {
    const { key } = req.body;
    if (!key) {
      return errorResponse(res, '缺少 key 参数', 400);
    }

    const data = await neteaseService.checkQRLoginStatus(key);

    if (data.status === 'success' && data.cookie) {
      const userId = req.user.id;

      // 获取用户信息
      let userInfo;
      try {
        userInfo = await neteaseService.getCurrentUserInfo(data.cookie);
      } catch (error) {
        logger.error('获取用户信息失败', { error: error.message });
        return errorResponse(res, '登录成功但无法获取用户信息，请重试', 400);
      }

      // 验证用户信息完整性
      if (!userInfo.id || userInfo.id === '') {
        logger.error('用户信息不完整，缺少 ID', { userInfo });
        return errorResponse(res, '登录成功但无法获取用户ID，请重试', 400);
      }

      // 保存完整的账号信息
      await neteaseService.saveAccount(userId, {
        platformUserId: userInfo.id,
        platformUsername: userInfo.username,
        cookie: data.cookie,
        expiresInDays: 30,
      });

      logger.info('用户绑定成功', {
        userId,
        platformUserId: userInfo.id,
        platformUsername: userInfo.username
      });

      // 返回包含用户信息的响应
      successResponse(res, {
        status: data.status,
        userInfo: userInfo,
      }, '绑定成功');
    } else {
      successResponse(res, {
        status: data.status,
        message: data.message,
      });
    }
  } catch (error) {
    logger.error('检查二维码状态失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const loginWithCellphone = async (req, res) => {
  try {
    const { phone, password, countrycode } = req.body;

    if (!phone || !password) {
      return errorResponse(res, '缺少手机号或密码', 400);
    }

    const data = await neteaseService.loginWithCellphone(phone, password, countrycode);

    if (data.success && data.cookie) {
      const userId = req.user.id;

      // 验证用户信息完整性
      if (!data.userInfo.id || data.userInfo.id === '') {
        logger.error('手机号登录用户信息不完整', { userInfo: data.userInfo });
        return errorResponse(res, '登录成功但无法获取用户ID，请重试', 400);
      }

      await neteaseService.saveAccount(userId, {
        platformUserId: data.userInfo.id,
        platformUsername: data.userInfo.username,
        cookie: data.cookie,
        expiresInDays: 30,
      });

      logger.info('用户通过手机号绑定成功', { userId, platformUserId: data.userInfo.id });
    }

    successResponse(res, {
      userInfo: data.userInfo,
    }, '登录成功');
  } catch (error) {
    logger.error('手机号登录失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getBindStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = await neteaseService.getBindStatus(userId);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取绑定状态失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const unbindAccount = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = await neteaseService.unbindAccount(userId);
    logger.info('用户解绑成功', { userId });
    successResponse(res, data, '解绑成功');
  } catch (error) {
    logger.error('解绑失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const search = async (req, res) => {
  try {
    const { keywords, limit, offset, type } = req.query;

    if (!keywords) {
      return errorResponse(res, '缺少搜索关键词', 400);
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.search(keywords, { limit, offset, type }, userId);
    successResponse(res, data);
  } catch (error) {
    logger.error('搜索失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getSongDetail = async (req, res) => {
  try {
    const { ids } = req.query;

    if (!ids) {
      return errorResponse(res, '缺少歌曲ID', 400);
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.getSongDetail(ids, userId);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取歌曲详情失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getSongUrl = async (req, res) => {
  try {
    const { id } = req.query;

    if (!id) {
      return errorResponse(res, '缺少歌曲ID', 400);
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.getSongUrl(id, userId);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取歌曲URL失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getPlaylistDetail = async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return errorResponse(res, '缺少歌单ID', 400);
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.getPlaylistDetail(id, userId);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取歌单详情失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getLyric = async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return errorResponse(res, '缺少歌曲ID', 400);
    }

    const data = await neteaseService.getLyric(id);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取歌词失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getUserPlaylist = async (req, res) => {
  try {
    const { uid } = req.params;

    if (!uid) {
      return errorResponse(res, '缺少用户ID', 400);
    }

    const userId = req.user.id;
    const data = await neteaseService.getUserPlaylist(userId, uid);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取用户歌单失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

const getRecommendedPlaylists = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = await neteaseService.getRecommendedPlaylists(userId);
    successResponse(res, data);
  } catch (error) {
    logger.error('获取每日推荐歌单失败', { error: error.message });
    errorResponse(res, error.message, 500);
  }
};

module.exports = {
  getQRCode,
  checkQRLoginStatus,
  loginWithCellphone,
  getBindStatus,
  unbindAccount,
  search,
  getSongDetail,
  getSongUrl,
  getPlaylistDetail,
  getLyric,
  getUserPlaylist,
  getRecommendedPlaylists,
};
