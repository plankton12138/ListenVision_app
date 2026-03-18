const bilibiliService = require('../services/bilibiliService');
const searchHistoryService = require('../services/audio/searchHistoryService');
const { successResponse, errorResponse } = require('../utils/response');
const { logger } = require('../utils/logger');
const { AppError, catchAsync } = require('../middleware/errorHandler');

const FETCH_TIMEOUT_MS = 30000;
const FETCH_MAX_RETRIES = 3;

async function fetchWithRetry(url, options, maxRetries = FETCH_MAX_RETRIES) {
  let lastError;
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
      
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });
      
      clearTimeout(timeoutId);
      return response;
    } catch (error) {
      lastError = error;
      const isTimeout = error.name === 'AbortError';
      
      if (attempt < maxRetries - 1) {
        const delay = Math.pow(2, attempt) * 1000;
        logger.warn('BiliProxy fetch retry', {
          url: url.substring(0, 100),
          attempt: attempt + 1,
          maxRetries,
          delayMs: delay,
          error: error.message,
          isTimeout
        });
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  throw lastError;
}

// ==================== 转换任务去重 ====================

/**
 * 转换任务追踪器
 * 防止同一 BVID+format 组合被重复转换
 */
class ConversionTaskTracker {
  constructor() {
    // Map<bvid_format, { Promise, resolve, reject, startTime }>
    this.pendingTasks = new Map();
  }

  /**
   * 获取任务键
   */
  _getKey(bvid, format) {
    return `${bvid}_${format}`;
  }

  /**
   * 获取或创建转换任务
   * @param {string} bvid - 视频 ID
   * @param {string} format - 目标格式
   * @param {Function} taskFn - 执行转换的函数
   * @returns {Promise} 转换结果
   */
  async getOrExecute(bvid, format, taskFn) {
    const key = this._getKey(bvid, format);

    // 检查是否有正在进行的任务
    const existing = this.pendingTasks.get(key);
    if (existing) {
      const waitTime = Date.now() - existing.startTime;
      logger.info('BiliProxy waiting for existing conversion', {
        bvid,
        format,
        waitingMs: waitTime
      });
      return existing.promise;
    }

    // 创建新任务
    let resolve, reject;
    const promise = new Promise((res, rej) => {
      resolve = res;
      reject = rej;
    });

    this.pendingTasks.set(key, {
      promise,
      resolve,
      reject,
      startTime: Date.now()
    });

    logger.info('BiliProxy starting new conversion', { bvid, format });

    try {
      const result = await taskFn();
      resolve(result);
      return result;
    } catch (error) {
      reject(error);
      throw error;
    } finally {
      // 清理任务（延迟清理，允许快速重试）
      setTimeout(() => {
        this.pendingTasks.delete(key);
      }, 1000);
    }
  }

  /**
   * 获取正在进行的任务数量
   */
  getPendingCount() {
    return this.pendingTasks.size;
  }

  /**
   * 清理所有任务（用于测试）
   */
  clear() {
    this.pendingTasks.clear();
  }
}

// 全局实例
const conversionTracker = new ConversionTaskTracker();

/**
 * B站API控制器
 */

/**
 * 获取QR码登录凭证
 */
const getQRCode = catchAsync(async (req, res) => {
  const result = await bilibiliService.getQRCode();
  successResponse(res, result, '获取QR码成功');
});

/**
 * 检查QR码登录状态
 */
const checkQRLoginStatus = catchAsync(async (req, res) => {
  const { qrcodeKey } = req.body;

  if (!qrcodeKey) {
    throw new AppError('缺少 qrcodeKey 参数', 400);
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
});

/**
 * 获取B站账号绑定状态
 */
const getBindStatus = catchAsync(async (req, res) => {
  const status = bilibiliService.getBindStatus(req.user.id);
  successResponse(res, status);
});

/**
 * 解绑B站账号
 */
const unbindAccount = catchAsync(async (req, res) => {
  const result = bilibiliService.unbindAccount(req.user.id);
  successResponse(res, result, '解绑成功');
});

/**
 * 获取视频信息
 */
const getVideoInfo = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const info = await bilibiliService.getVideoInfo(bvid);
  successResponse(res, info);
});

/**
 * 获取音频流URL
 *
 * 返回音频流信息（向后兼容原有格式）：
 * - baseUrl: 音频流URL
 * - seekable: 是否支持 seek/断点续传（m4s 直传为 true）
 * - duration: 音频时长（毫秒）
 * - content_type: 内容类型
 * - supported_formats: 支持的格式列表（m4s, mp3, aac）
 */
const getAudioStream = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  // 使用登录用户的Cookie获取更高质量的音频
  const userId = req.user?.id || null;
  const audioStream = await bilibiliService.getAudioStream(bvid, null, userId);

  if (!audioStream || !audioStream.baseUrl) {
    throw new AppError('无法获取音频流URL', 404);
  }

  // 构建响应（向后兼容：保留原有字段在顶层）
  const response = {
    // 原有字段（保持向后兼容）
    baseUrl: audioStream.baseUrl || audioStream.url,
    url: audioStream.url,
    quality: audioStream.quality,
    codec: audioStream.codec,
    size: audioStream.size,
    content_type: audioStream.content_type || 'audio/mp4',
    duration: audioStream.duration || 0, // 毫秒

    // 新增能力字段（可选）
    seekable: true, // m4s 格式直传支持 seek/断点续传
    streamable: true, // 支持流式播放
    supported_formats: ['m4s', 'mp3', 'aac'],
    default_format: 'm4s',
    format_capabilities: {
      m4s: {
        seekable: true,
        description: '原始格式，支持 seek 和断点续传，推荐使用'
      },
      mp3: {
        seekable: false,
        description: '转码格式，不支持 seek，兼容性最好'
      },
      aac: {
        seekable: false,
        description: '转码格式，不支持 seek，兼容性较好'
      }
    }
  };

  successResponse(res, response);
});

/**
 * 获取UP主视频列表
 */
const getUploaderVideos = catchAsync(async (req, res) => {
  const { mid } = req.params;
  const { page = 1, pageSize = 20 } = req.query;

  if (!mid) {
    throw new AppError('缺少 mid 参数', 400);
  }

  const result = await bilibiliService.getUploaderVideos(
    mid,
    parseInt(page) || 1,
    parseInt(pageSize) || 20
  );

  successResponse(res, result);
});

/**
 * 搜索B站视频
 */
const searchBilibili = catchAsync(async (req, res) => {
  const { keyword } = req.query;
  const { page = 1, pageSize = 20 } = req.query;

  if (!keyword) {
    throw new AppError('缺少 keyword 参数', 400);
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
});

/**
 * 获取最近搜索历史
 */
const getRecentSearches = catchAsync(async (req, res) => {
  const { limit = 10 } = req.query;

  const keywords = bilibiliService.getRecentSearches(req.user.id);

  successResponse(res, {
    keywords: keywords.slice(0, parseInt(limit) || 10)
  });
});

/**
 * 获取搜索建议（联想词）
 */
const getSearchSuggestions = catchAsync(async (req, res) => {
  const { keyword } = req.query;

  if (!keyword) {
    throw new AppError('缺少 keyword 参数', 400);
  }

  const suggestions = await bilibiliService.getSearchSuggestions(keyword);

  successResponse(res, {
    suggestions,
    keyword
  });
});

/**
 * 清空搜索历史
 */
const clearSearchHistory = catchAsync(async (req, res) => {
  const cleared = searchHistoryService.clearSearchHistory(req.user.id);
  successResponse(res, { cleared });
});

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
 * 方式1: 通过URL参数（长URL，可能导致MPV无法处理）
 *
 * Range 支持：
 * - 直传流（m4s）：支持断点续传和 seek，透传 Range 请求头和 206 响应头
 * - 转码流（mp3/aac）：不支持 seek，返回 Accept-Ranges: none
 */
const proxyAudioStream = async (req, res) => {
  try {
    const { url, format = 'm4s' } = req.query;

    if (!url) {
      return res.status(400).json({ success: false, error: '缺少 url 参数' });
    }

    // 支持的格式
    const supportedFormats = ['m4s', 'mp3', 'aac'];
    const targetFormat = supportedFormats.includes(format) ? format : 'mp3';

    // 构建 fetch 请求头，透传 Range 请求头
    const fetchHeaders = {
      'Referer': 'https://www.bilibili.com/',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    };

    // 如果客户端发送了 Range 请求头，透传给上游
    if (req.headers.range) {
      fetchHeaders['Range'] = req.headers.range;
      logger.debug('BiliProxy range passthrough', { range: req.headers.range });
    }

    // 使用 fetch 获取音频流
    const response = await fetch(url, {
      headers: fetchHeaders
    });

    if (!response.ok) {
      return res.status(response.status).send('获取音频失败');
    }

    // 服务端不再提供格式转换（除缓存命中），建议请求 m4s 或在客户端转换
    if (targetFormat !== 'm4s') {
      return res.status(400).json({
        success: false,
        error: '服务器不再支持服务端音频转换，请请求 m4s 或在客户端执行转换'
      });
    } else {
      // 直接转发原始音频流（支持 seek 和断点续传）
      const contentType = response.headers.get('Content-Type') || 'audio/mp4';
      const contentLength = response.headers.get('Content-Length');
      const contentRange = response.headers.get('Content-Range');
      const acceptRanges = response.headers.get('Accept-Ranges');

      res.setHeader('Content-Type', contentType);
      res.setHeader('Accept-Ranges', 'bytes'); // 明确声明支持 Range

      // 如果上游返回了 206 状态码（部分内容），透传相关响应头
      if (response.status === 206) {
        if (contentRange) {
          res.setHeader('Content-Range', contentRange);
        }
        if (contentLength) {
          res.setHeader('Content-Length', contentLength);
        }
        res.status(206); // 设置 206 响应状态
        logger.debug('BiliProxy 206 passthrough', { contentRange });
      } else if (contentLength) {
        res.setHeader('Content-Length', contentLength);
      }

      // 流式转发音频数据（避免缓冲整个文件）
      if (response.body) {
        // 使用 Node.js ReadableStream 转换为 Buffer 流
        const nodeStream = require('stream');
        const { Readable } = nodeStream;

        // 将 Web ReadableStream 转换为 Node.js ReadableStream
        const reader = response.body.getReader();
        const readableStream = new Readable({
          async read() {
            const { done, value } = await reader.read();
            if (done) {
              this.push(null); // 结束流
            } else {
              this.push(Buffer.from(value));
            }
          }
        });

        readableStream.pipe(res);
      } else {
        // 回退方案：缓冲整个响应
        const buffer = await response.arrayBuffer();
        res.send(Buffer.from(buffer));
      }
    }
  } catch (error) {
    logger.error('BiliProxy proxy audio failed', { error: error.message });
    res.status(500).json({ success: false, error: `代理音频失败: ${error.message}` });
  }
};

/**
 * 智能音频代理
 *
 * 优先级：
 * 1. 检查缓存（已转换的 mp3）
 * 2. 直接透传 m4s（最高效，默认）
 * 3. 降级到 mp3 转换（兼容性）
 *
 * Range 支持：
 * - 直传流（m4s）：支持断点续传和 seek，透传 Range 请求头和 206 响应头
 * - 转码流（mp3/aac）：不支持 seek，返回 Accept-Ranges: none
 * - 缓存流：不支持 seek，返回 Accept-Ranges: none
 *
 * GET /api/bilibili/proxy/audio/:bvid?format=auto|m4s|mp3
 */
const proxyAudioStreamByBvid = async (req, res) => {
  const { bvid } = req.params;
  const { format = 'auto' } = req.query;  // ✅ 默认 'auto'，让后端智能选择

  if (!bvid) {
    return res.status(400).json({ success: false, error: '缺少 bvid 参数' });
  }

  try {
    const userId = req.user?.id;

    logger.info('BiliProxy request audio', { bvid, format, userId: userId || 'none' });

    // ✅ 步骤1：获取音频流信息
    const audioData = await bilibiliService.getAudioStream(bvid, null, userId);

    if (!audioData || !audioData.baseUrl) {
      logger.warn('BiliProxy missing audio url', { bvid, userId: userId || 'none', audioData });
      return res.status(404).json({ success: false, error: '无法获取音频流URL' });
    }

    const streamUrl = audioData.baseUrl || audioData.url;

    // ✅ 步骤2：检查 mp3 缓存（如果请求 mp3 或 auto）
    if (format === 'auto' || format === 'mp3') {
      const cached = bilibiliService.getCachedAudio(bvid);
      if (cached) {
        logger.info('BiliProxy cached mp3 hit', { bvid });
        res.setHeader('Content-Type', 'audio/mpeg');
        res.setHeader('Content-Length', cached.data.length);
        res.setHeader('Accept-Ranges', 'bytes');
        res.setHeader('Cache-Control', 'public, max-age=3600');
        res.send(cached.data);
        return;
      }
    }

    // ✅ 步骤3：根据客户端偏好选择格式
    // auto → m4s（默认最高效），客户端可指定 mp3
    const targetFormat = (format === 'auto') ? 'm4s' : format;

    if (targetFormat === 'm4s') {
      // ✅ 模式A：直接透传 m4s（真流式，无转换，支持 seek）
      logger.info('BiliProxy passthrough m4s', { bvid });

      const fetchHeaders = {
        'Referer': 'https://www.bilibili.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      };

      // 透传 Range 请求（支持 seek）
      if (req.headers.range) {
        fetchHeaders['Range'] = req.headers.range;
        logger.debug('BiliProxy range request', { range: req.headers.range });
      }

      const response = await fetchWithRetry(streamUrl, { headers: fetchHeaders });

      if (!response.ok) {
        logger.warn('BiliProxy fetch failed after retries', { 
          bvid, 
          status: response.status,
          statusText: response.statusText 
        });
        return res.status(response.status).json({ 
          success: false, 
          error: `获取音频失败 (${response.status})` 
        });
      }

      const contentType = response.headers.get('Content-Type') || 'audio/mp4';
      const contentLength = response.headers.get('Content-Length');
      const contentRange = response.headers.get('Content-Range');

      res.setHeader('Content-Type', contentType);
      res.setHeader('Accept-Ranges', 'bytes');  // ✅ 支持 seek
      res.setHeader('Cache-Control', 'public, max-age=3600');

      if (response.status === 206) {
        if (contentRange) res.setHeader('Content-Range', contentRange);
        if (contentLength) res.setHeader('Content-Length', contentLength);
        res.status(206);
        logger.debug('BiliProxy 206 response', { contentRange });
      } else if (contentLength) {
        res.setHeader('Content-Length', contentLength);
      }

      // ✅ 真正的流式转发（不等待完整下载）
      if (response.body) {
        const nodeStream = require('stream');
        const { Readable } = nodeStream;
        const reader = response.body.getReader();
        let streamError = null;

        const readableStream = new Readable({
          async read() {
            if (streamError) {
              this.destroy(streamError);
              return;
            }
            try {
              const readPromise = reader.read();
              const timeoutPromise = new Promise((_, reject) => 
                setTimeout(() => reject(new Error('Stream read timeout')), 60000)
              );
              
              const { done, value } = await Promise.race([readPromise, timeoutPromise]);
              if (done) {
                this.push(null);
              } else {
                this.push(Buffer.from(value));
              }
            } catch (error) {
              streamError = error;
              logger.warn('BiliProxy stream read error', { bvid, error: error.message });
              this.destroy(error);
            }
          }
        });

        readableStream.on('error', (err) => {
          logger.warn('BiliProxy stream error', { bvid, error: err.message });
          if (!res.headersSent) {
            res.status(500).json({ success: false, error: '音频流传输中断' });
          }
        });

        readableStream.pipe(res);
        logger.debug('BiliProxy m4s stream started', { bvid });
      } else {
        // 回退方案
        const buffer = Buffer.from(await response.arrayBuffer());
        res.send(buffer);
      }

    } else if (targetFormat === 'mp3') {
      // 如果存在缓存，则返回缓存；否则服务器不再支持服务端转换
      const cached = bilibiliService.getCachedAudio(bvid);
      if (cached) {
        logger.info('BiliProxy cached mp3 hit', { bvid });
        res.setHeader('Content-Type', cached.contentType || 'audio/mpeg');
        res.setHeader('Content-Length', cached.data.length);
        res.setHeader('Accept-Ranges', 'bytes');
        res.setHeader('Cache-Control', 'public, max-age=3600');
        res.send(cached.data);
        return;
      }

      return res.status(400).json({
        success: false,
        error: '服务器不再支持服务端音频转换（mp3），请请求 m4s 或在客户端执行转换'
      });
    } else {
    return res.status(400).json({
        success: false,
        error: `不支持的格式: ${targetFormat}`
      });
    }
  } catch (error) {
    const isNetworkError = error.name === 'AbortError' || 
                           error.code === 'ECONNREFUSED' ||
                           error.code === 'ECONNRESET' ||
                           error.message?.includes('fetch failed');
    
    if (isNetworkError) {
      logger.error('BiliProxy network error', { 
        bvid, 
        error: error.message,
        code: error.code 
      });
      return res.status(503).json({ 
        success: false, 
        error: '网络连接不稳定，请稍后重试',
        code: 'NETWORK_ERROR'
      });
    }
    
    logger.error('BiliProxy error', { error: error.message, stack: error.stack });
    res.status(500).json({ success: false, error: `代理音频失败: ${error.message}` });
  }
};

/**
 * 获取B站推荐视频
 */
const getRecommendedVideos = catchAsync(async (req, res) => {
  const { page = 1, pageSize = 20 } = req.query;
  const userId = req.user?.id || null;
  logger.info('getRecommendedVideos called', { userId, page, pageSize });

  const result = await bilibiliService.getRecommendedVideos(
    userId,
    parseInt(page) || 1,
    parseInt(pageSize) || 20
  );

  successResponse(res, result);
});

/**
 * 获取视频字幕
 * GET /api/v1/bilibili/subtitle/:bvid?cid=xxx
 */
const getSubtitle = catchAsync(async (req, res) => {
  const { bvid } = req.params;
  const { cid } = req.query;
  if (!bvid) {
    throw new AppError('缺少 bvid 参数', 400);
  }

  const userId = req.user?.id || null;
  const cidNum = cid ? parseInt(cid, 10) : null;
  logger.info('[getSubtitle] 请求字幕: bvid=%s, cid=%s, userId=%s, hasUser=%s', bvid, cidNum, userId, !!req.user);

  const result = await bilibiliService.getVideoSubtitles(bvid, userId, cidNum);
  successResponse(res, result, '获取字幕成功');
});

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
  getSearchSuggestions,
  getRecentSearches,
  clearSearchHistory,

  // 推荐
  getRecommendedVideos,

  // 字幕
  getSubtitle,

  // 代理
  proxyImage,
  proxyAudioStream,
  proxyAudioStreamByBvid
};
