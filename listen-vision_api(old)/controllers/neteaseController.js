const neteaseService = require('../services/neteaseService');
const { successResponse, errorResponse } = require('../utils/response');
const { logger } = require('../utils/logger');
const { AppError, catchAsync } = require('../middleware/errorHandler');

const getQRCode = catchAsync(async (req, res) => {
  const data = await neteaseService.getQRCode();
  successResponse(res, data, '获取二维码成功');
});

const checkQRLoginStatus = catchAsync(async (req, res) => {
  const { key } = req.body;
  if (!key) {
    throw new AppError('缺少 key 参数', 400);
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
      throw new AppError('登录成功但无法获取用户信息，请重试', 400);
    }

    // 验证用户信息完整性
    if (!userInfo.id || userInfo.id === '') {
      logger.error('用户信息不完整，缺少 ID', { userInfo });
      throw new AppError('登录成功但无法获取用户ID，请重试', 400);
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
});

const loginWithCellphone = catchAsync(async (req, res) => {
  const { phone, password, countrycode } = req.body;

  if (!phone || !password) {
    throw new AppError('缺少手机号或密码', 400);
  }

  const data = await neteaseService.loginWithCellphone(phone, password, countrycode);

  if (data.success && data.cookie) {
    const userId = req.user.id;

    // 验证用户信息完整性
    if (!data.userInfo.id || data.userInfo.id === '') {
      logger.error('手机号登录用户信息不完整', { userInfo: data.userInfo });
      throw new AppError('登录成功但无法获取用户ID，请重试', 400);
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
});

const getBindStatus = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const data = await neteaseService.getBindStatus(userId);
  successResponse(res, data);
});

const unbindAccount = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const data = await neteaseService.unbindAccount(userId);
  logger.info('用户解绑成功', { userId });
  successResponse(res, data, '解绑成功');
});

const search = catchAsync(async (req, res) => {
  const { keywords, limit, offset, type } = req.query;

  if (!keywords) {
    throw new AppError('缺少搜索关键词', 400);
  }

  const userId = req.user?.id || null;
  const data = await neteaseService.search(keywords, { limit, offset, type }, userId);
  successResponse(res, data);
});

const getSongDetail = catchAsync(async (req, res) => {
  const { ids } = req.query;

  if (!ids) {
    throw new AppError('缺少歌曲ID', 400);
  }

  const userId = req.user?.id || null;
  const data = await neteaseService.getSongDetail(ids, userId);
  successResponse(res, data);
});

const getSongUrl = catchAsync(async (req, res) => {
  const { id } = req.query;

  if (!id) {
    throw new AppError('缺少歌曲ID', 400);
  }

  const userId = req.user?.id || null;
  const data = await neteaseService.getSongUrl(id, userId);
  successResponse(res, data);
});

const getPlaylistDetail = catchAsync(async (req, res) => {
  const { id } = req.params;

  if (!id) {
    throw new AppError('缺少歌单ID', 400);
  }

  const userId = req.user?.id || null;
  const data = await neteaseService.getPlaylistDetail(id, userId);
  successResponse(res, data);
});

const getLyric = catchAsync(async (req, res) => {
  const { id } = req.params;

  if (!id) {
    throw new AppError('缺少歌曲ID', 400);
  }

  const data = await neteaseService.getLyric(id);
  successResponse(res, data);
});

const getUserPlaylist = catchAsync(async (req, res) => {
  const { uid } = req.params;

  if (!uid) {
    throw new AppError('缺少用户ID', 400);
  }

  const userId = req.user.id;
  const data = await neteaseService.getUserPlaylist(userId, uid);
  successResponse(res, data);
});

const getRecommendedPlaylists = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const data = await neteaseService.getRecommendedPlaylists(userId);
  successResponse(res, data);
});

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
