const neteaseService = require('../services/neteaseService');
const { logger } = require('../utils/logger');

const getQRCode = async (req, res) => {
  try {
    const data = await neteaseService.getQRCode();
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取二维码失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const checkQRLoginStatus = async (req, res) => {
  try {
    const { key } = req.body;
    if (!key) {
      return res.status(400).json({
        success: false,
        error: '缺少 key 参数',
      });
    }

    const data = await neteaseService.checkQRLoginStatus(key);

    if (data.status === 'success' && data.cookie) {
      const userId = req.user.id;

      // 获取用户信息
      let userInfo;
      try {
        userInfo = await neteaseService.getCurrentUserInfo(data.cookie);
      } catch (error) {
        logger.error('[Netease] 获取用户信息失败: %s', error.message);
        return res.status(400).json({
          success: false,
          error: '登录成功但无法获取用户信息，请重试',
        });
      }

      // 验证用户信息完整性
      if (!userInfo.id || userInfo.id === '') {
        logger.error('[Netease] 用户信息不完整，缺少 ID: %j', userInfo);
        return res.status(400).json({
          success: false,
          error: '登录成功但无法获取用户ID，请重试',
        });
      }

      // 保存完整的账号信息
      await neteaseService.saveAccount(userId, {
        platformUserId: userInfo.id,
        platformUsername: userInfo.username,
        cookie: data.cookie,
        expiresInDays: 30,
      });

      logger.info('[Netease] 用户 %d 绑定成功 (ID: %s, 用户名: %s)',
        userId, userInfo.id, userInfo.username);

      // 返回包含用户信息的响应
      res.json({
        success: true,
        data: {
          status: data.status,
          userInfo: userInfo,
        },
      });
    } else {
      res.json({
        success: true,
        data: {
          status: data.status,
          message: data.message,
        },
      });
    }
  } catch (error) {
    logger.error('[Netease] 检查二维码状态失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const loginWithCellphone = async (req, res) => {
  try {
    const { phone, password, countrycode } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        error: '缺少手机号或密码',
      });
    }

    const data = await neteaseService.loginWithCellphone(phone, password, countrycode);

    if (data.success && data.cookie) {
      const userId = req.user.id;

      // 验证用户信息完整性
      if (!data.userInfo.id || data.userInfo.id === '') {
        logger.error('[Netease] 手机号登录用户信息不完整: %j', data.userInfo);
        return res.status(400).json({
          success: false,
          error: '登录成功但无法获取用户ID，请重试',
        });
      }

      await neteaseService.saveAccount(userId, {
        platformUserId: data.userInfo.id,
        platformUsername: data.userInfo.username,
        cookie: data.cookie,
        expiresInDays: 30,
      });

      logger.info('[Netease] 用户 %d 通过手机号绑定成功 (ID: %s)', userId, data.userInfo.id);
    }

    res.json({
      success: true,
      data: {
        userInfo: data.userInfo,
      },
    });
  } catch (error) {
    logger.error('[Netease] 手机号登录失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getBindStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = await neteaseService.getBindStatus(userId);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取绑定状态失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const unbindAccount = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = await neteaseService.unbindAccount(userId);
    logger.info('[Netease] 用户 %d 解绑成功', userId);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 解绑失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const search = async (req, res) => {
  try {
    const { keywords, limit, offset, type } = req.query;

    if (!keywords) {
      return res.status(400).json({
        success: false,
        error: '缺少搜索关键词',
      });
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.search(keywords, { limit, offset, type }, userId);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 搜索失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getSongDetail = async (req, res) => {
  try {
    const { ids } = req.query;

    if (!ids) {
      return res.status(400).json({
        success: false,
        error: '缺少歌曲ID',
      });
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.getSongDetail(ids, userId);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取歌曲详情失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getSongUrl = async (req, res) => {
  try {
    const { id } = req.query;

    if (!id) {
      return res.status(400).json({
        success: false,
        error: '缺少歌曲ID',
      });
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.getSongUrl(id, userId);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取歌曲URL失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getPlaylistDetail = async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        success: false,
        error: '缺少歌单ID',
      });
    }

    const userId = req.user?.id || null;
    const data = await neteaseService.getPlaylistDetail(id, userId);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取歌单详情失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getLyric = async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        success: false,
        error: '缺少歌曲ID',
      });
    }

    const data = await neteaseService.getLyric(id);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取歌词失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getUserPlaylist = async (req, res) => {
  try {
    const { uid } = req.params;

    if (!uid) {
      return res.status(400).json({
        success: false,
        error: '缺少用户ID',
      });
    }

    const userId = req.user.id;
    const data = await neteaseService.getUserPlaylist(userId, uid);
    res.json({
      success: true,
      data,
    });
  } catch (error) {
    logger.error('[Netease] 获取用户歌单失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
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
};
