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
 *
 * 返回音频流信息（向后兼容原有格式）：
 * - baseUrl: 音频流URL
 * - seekable: 是否支持 seek/断点续传（m4s 直传为 true）
 * - duration: 音频时长（毫秒）
 * - content_type: 内容类型
 * - supported_formats: 支持的格式列表（m4s, mp3, aac）
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

    if (!audioStream || !audioStream.baseUrl) {
      return res.status(404).json({
        success: false,
        error: '无法获取音频流URL'
      });
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
      console.log(`[BiliProxy] Range 请求透传: ${req.headers.range}`);
    }

    // 使用 fetch 获取音频流
    const response = await fetch(url, {
      headers: fetchHeaders
    });

    if (!response.ok) {
      return res.status(response.status).send('获取音频失败');
    }

    // 如果需要转换格式（不支持 seek）
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
      res.setHeader('Accept-Ranges', 'none'); // 转码流不支持 seek
      res.send(buffer);
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
        console.log(`[BiliProxy] 206 响应透传: ${contentRange}`);
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
    console.error(`[BiliProxy] 代理音频失败: ${error.message}`);
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

    console.log(`[BiliProxy] 请求音频: ${bvid}, 格式: ${format}, 用户: ${userId || 'none'}`);

    // ✅ 步骤1：获取音频流信息
    const audioData = await bilibiliService.getAudioStream(bvid, null, userId);

    if (!audioData || !audioData.baseUrl) {
      console.error(`[BiliProxy] 无法获取音频流URL: ${JSON.stringify(audioData)}`);
      return res.status(404).json({ success: false, error: '无法获取音频流URL' });
    }

    const streamUrl = audioData.baseUrl || audioData.url;

    // ✅ 步骤2：检查 mp3 缓存（如果请求 mp3 或 auto）
    if (format === 'auto' || format === 'mp3') {
      const cached = bilibiliService.getCachedAudio(bvid);
      if (cached) {
        console.log(`[BiliProxy] ✅ 使用缓存 mp3: ${bvid}`);
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
      console.log(`[BiliProxy] 直接透传 m4s: ${bvid}`);

      const fetchHeaders = {
        'Referer': 'https://www.bilibili.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      };

      // 透传 Range 请求（支持 seek）
      if (req.headers.range) {
        fetchHeaders['Range'] = req.headers.range;
        console.log(`[BiliProxy] Range 请求: ${req.headers.range}`);
      }

      const response = await fetch(streamUrl, { headers: fetchHeaders });

      if (!response.ok) {
        return res.status(response.status).send('获取音频失败');
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
        console.log(`[BiliProxy] 206 响应: ${contentRange}`);
      } else if (contentLength) {
        res.setHeader('Content-Length', contentLength);
      }

      // ✅ 真正的流式转发（不等待完整下载）
      if (response.body) {
        const nodeStream = require('stream');
        const { Readable } = nodeStream;
        const reader = response.body.getReader();

        const readableStream = new Readable({
          async read() {
            const { done, value } = await reader.read();
            if (done) {
              this.push(null);
            } else {
              this.push(Buffer.from(value));
            }
          }
        });

        readableStream.pipe(res);
        console.log(`[BiliProxy] m4s 流式转发开始: ${bvid}`);
      } else {
        // 回退方案
        const buffer = Buffer.from(await response.arrayBuffer());
        res.send(buffer);
      }

    } else if (targetFormat === 'mp3') {
      // ✅ 模式B：转换为 mp3（并发控制 + 缓存）
      console.log(`[BiliProxy] 转换为 mp3: ${bvid}`);

      const response = await fetch(streamUrl, {
        headers: {
          'Referer': 'https://www.bilibili.com/',
          'User-Agent': 'Mozilla/5.0'
        }
      });

      if (!response.ok) {
        return res.status(response.status).send('获取音频失败');
      }

      // 下载并转换
      const inputBuffer = Buffer.from(await response.arrayBuffer());
      const { buffer, contentType } = await require('../services/audioService').convertStream(
        inputBuffer,
        'mp3',
        { bitrate: '192k', sampleRate: '44100', channels: 2 }
      );

      // 设置响应头
      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Length', buffer.length);
      res.setHeader('Accept-Ranges', 'none');  // mp3 不支持 seek（转码后）
      res.setHeader('Cache-Control', 'public, max-age=3600');
      res.send(buffer);

      // ✅ 缓存转换结果
      bilibiliService.insertCachedAudio(bvid, buffer, 'audio/mpeg');

      console.log(`[BiliProxy] mp3 转换完成: ${bvid}, 大小: ${buffer.length} bytes`);
    } else {
      return res.status(400).json({
        success: false,
        error: `不支持的格式: ${targetFormat}`
      });
    }
  } catch (error) {
    console.error(`[BiliProxy] 错误: ${error.message}`);
    console.error(`[BiliProxy] 错误堆栈: ${error.stack}`);
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
  proxyAudioStream,
  proxyAudioStreamByBvid
};
