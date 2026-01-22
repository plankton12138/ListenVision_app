const bilibiliService = require('../services/bilibiliService');
const { successResponse } = require('../utils/response');

/**
 * B站API控制器
 */

/**
 * 获取QR码登录凭证
 */
const getQRCode = async (req, res) => {
  try {
    const result = await bilibiliService.getQRCode();
    successResponse(res, result, '获取QR码成功');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 检查QR码登录状态
 */
const checkQRLoginStatus = async (req, res) => {
  try {
    const { qrcodeKey } = req.body;

    if (!qrcodeKey) {
      return res.status(400).json({
        success: false,
        error: '缺少 qrcodeKey 参数'
      });
    }

    const result = await bilibiliService.checkQRLoginStatus(qrcodeKey);

    // 使用 result.statusCode (QR码状态码) 而不是 result.code (API调用状态码)
    // statusCode: 0=成功, 86101=未扫码, 86090=已扫描, 86038=已过期
    if (result.statusCode === 0) {
      // 登录成功，保存Cookie（如果有）
      if (result.cookie && req.user) {
        await bilibiliService.saveCookie(req.user.id, result.cookie, result.userInfo);
      }
      successResponse(res, {
        status: 'success',
        userInfo: result.userInfo
      }, '登录成功');
    } else if (result.statusCode === 86038) {
      // QR码已过期
      successResponse(res, { status: 'expired' }, 'QR码已过期');
    } else if (result.statusCode === 86090) {
      // 已扫描待确认
      successResponse(res, { status: 'scanned' }, '已扫描，请确认');
    } else {
      // 未扫码或其他状态
      successResponse(res, { status: 'pending' }, '等待扫码');
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取B站账号绑定状态
 */
const getBindStatus = async (req, res) => {
  try {
    const status = bilibiliService.getBindStatus(req.user.id);
    successResponse(res, status);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 解绑B站账号
 */
const unbindAccount = async (req, res) => {
  try {
    const result = bilibiliService.unbindAccount(req.user.id);
    successResponse(res, result, '解绑成功');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取视频信息
 */
const getVideoInfo = async (req, res) => {
  try {
    const { bvid } = req.params;

    if (!bvid) {
      return res.status(400).json({
        success: false,
        error: '缺少 bvid 参数'
      });
    }

    const info = await bilibiliService.getVideoInfo(bvid);
    successResponse(res, info);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取音频流URL
 */
const getAudioStream = async (req, res) => {
  try {
    const { bvid } = req.params;

    if (!bvid) {
      return res.status(400).json({
        success: false,
        error: '缺少 bvid 参数'
      });
    }

    // 使用登录用户的Cookie获取更高质量的音频
    const userId = req.user?.id || null;
    const audioStream = await bilibiliService.getAudioStream(bvid, null, userId);

    successResponse(res, audioStream);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取UP主视频列表
 */
const getUploaderVideos = async (req, res) => {
  try {
    const { mid } = req.params;
    const { page = 1, pageSize = 20 } = req.query;

    if (!mid) {
      return res.status(400).json({
        success: false,
        error: '缺少 mid 参数'
      });
    }

    const result = await bilibiliService.getUploaderVideos(
      mid,
      parseInt(page) || 1,
      parseInt(pageSize) || 20
    );

    successResponse(res, result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 搜索B站视频
 */
const searchBilibili = async (req, res) => {
  try {
    const { keyword } = req.query;
    const { page = 1, pageSize = 20 } = req.query;

    if (!keyword) {
      return res.status(400).json({
        success: false,
        error: '缺少 keyword 参数'
      });
    }

    // 使用登录用户的ID（如果有）
    const userId = req.user?.id || null;

    const result = await bilibiliService.searchBilibili(
      keyword,
      parseInt(page) || 1,
      parseInt(pageSize) || 20,
      userId
    );

    successResponse(res, result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取最近搜索历史
 */
const getRecentSearches = async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const keywords = bilibiliService.getRecentSearches(req.user.id);

    successResponse(res, {
      keywords: keywords.slice(0, parseInt(limit) || 10)
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 代理图片（解决封面防盗链）
 */
const proxyImage = async (req, res) => {
  try {
    const { url } = req.query;

    if (!url) {
      return res.status(400).send('缺少 url 参数');
    }

    // 使用 fetch 获取图片
    const response = await fetch(url, {
      headers: {
        'Referer': 'https://www.bilibili.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    if (!response.ok) {
      return res.status(response.status).send('获取图片失败');
    }

    // 设置正确的 Content-Type
    const contentType = response.headers.get('Content-Type') || 'image/jpeg';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400'); // 缓存24小时

    // 转发图片数据
    const buffer = await response.arrayBuffer();
    res.send(Buffer.from(buffer));
  } catch (error) {
    res.status(500).send(`代理图片失败: ${error.message}`);
  }
};

/**
 * 代理音频流（解决防盗链，可选格式转换）
 */
const proxyAudioStream = async (req, res) => {
  try {
    const { url, format = 'm4s' } = req.query;

    if (!url) {
      return res.status(400).json({ success: false, error: '缺少 url 参数' });
    }

    // 支持的格式
    const supportedFormats = ['m4s', 'mp3', 'aac'];
    const targetFormat = supportedFormats.includes(format) ? format : 'm4s';

    // 使用 fetch 获取音频流
    const response = await fetch(url, {
      headers: {
        'Referer': 'https://www.bilibili.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    if (!response.ok) {
      return res.status(response.status).send('获取音频失败');
    }

    // 如果需要转换格式
    if (targetFormat !== 'm4s') {
      const audioService = require('../services/audioService');
      const inputBuffer = await response.arrayBuffer();

      console.log(`[Audio] Converting audio from m4s to ${targetFormat}...`);

      const { buffer, contentType } = await audioService.convertStream(
        Buffer.from(inputBuffer),
        targetFormat,
        { bitrate: '192k', sampleRate: '44100', channels: 2 }
      );

      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Length', buffer.length);
      res.send(buffer);
    } else {
      // 直接转发原始音频流
      const contentType = response.headers.get('Content-Type') || 'audio/mp4';
      res.setHeader('Content-Type', contentType);
      res.setHeader('Accept-Ranges', 'bytes');

      // 转发音频流
      const buffer = await response.arrayBuffer();
      res.send(Buffer.from(buffer));
    }
  } catch (error) {
    res.status(500).json({ success: false, error: `代理音频失败: ${error.message}` });
  }
};

module.exports = {
  // QR码登录
  getQRCode,
  checkQRLoginStatus,

  // 账号绑定
  getBindStatus,
  unbindAccount,

  // 视频信息
  getVideoInfo,
  getAudioStream,
  getUploaderVideos,

  // 搜索
  searchBilibili,
  getRecentSearches,

  // 代理
  proxyImage,
  proxyAudioStream
};
