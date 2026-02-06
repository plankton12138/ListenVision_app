const ffmpeg = require('fluent-ffmpeg');
const https = require('https');
const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { logger } = require('../../utils/logger');
const { AppError } = require('../../middleware/errorHandler');

// ==================== 并发控制 ====================

const MAX_CONCURRENT_CONVERSIONS = 3;
let activeConversions = 0;
const conversionQueue = [];

/**
 * 排队执行转换任务
 */
async function queueConversion(fn) {
  return new Promise((resolve, reject) => {
    const task = { fn, resolve, reject };

    if (activeConversions < MAX_CONCURRENT_CONVERSIONS) {
      activeConversions++;
      executeTask(task);
    } else {
      conversionQueue.push(task);
      logger.info('转换任务已排队，当前活跃: %d, 队列: %d', activeConversions, conversionQueue.length);
    }
  });
}

/**
 * 执行单个转换任务
 */
async function executeTask(task) {
  try {
    const result = await task.fn();
    task.resolve(result);
  } catch (error) {
    task.reject(error);
  } finally {
    activeConversions--;
    if (conversionQueue.length > 0) {
      activeConversions++;
      executeTask(conversionQueue.shift());
    }
  }
}

// ==================== 格式映射 ====================

const CODEC_MAP = {
  'mp3': 'libmp3lame',
  'aac': 'aac',
  'm4a': 'aac'
};

const FORMAT_MAP = {
  'mp3': 'mp3',
  'aac': 'adts',
  'm4a': 'adts'
};

const getCodec = (format) => CODEC_MAP[format] || 'libmp3lame';
const getFormat = (format) => FORMAT_MAP[format] || 'mp3';

// ==================== 核心转换功能 ====================

/**
 * 下载HTTP/HTTPS资源到内存
 * 支持 B站防盗链（添加完整的浏览器请求头）
 */
const downloadToBuffer = (url, headers = {}) => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const protocol = url.startsWith('https') ? https : http;
    const isBilibili = url.includes('bilivideo.com') || url.includes('bilibili.com');

    logger.info('downloadToBuffer 开始', { url: url.substring(0, 100) + '...', isBilibili });

    // B站 URL 需要特定的请求头（模拟真实浏览器请求）
    const defaultHeaders = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'cross-site',
      'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
      'Sec-Ch-Ua-Mobile': '?0',
      'Sec-Ch-Ua-Platform': '"Windows"',
    };

    // 如果是 B站资源，添加 Referer 和 Origin
    if (isBilibili) {
      defaultHeaders['Referer'] = 'https://www.bilibili.com/';
      defaultHeaders['Origin'] = 'https://www.bilibili.com';
    }

    const requestHeaders = { ...defaultHeaders, ...headers };

    const req = protocol.get(url, { headers: requestHeaders }, (res) => {
      // 处理重定向
      if (res.statusCode === 301 || res.statusCode === 302) {
        const redirectUrl = res.headers.location;
        if (redirectUrl) {
          logger.info('downloadToBuffer 重定向', { from: url.substring(0, 50), to: redirectUrl.substring(0, 50) });
          // 跟随重定向，保留请求头
          downloadToBuffer(redirectUrl, headers).then(resolve).catch(reject);
          return;
        }
      }

      if (res.statusCode !== 200) {
        logger.error('downloadToBuffer HTTP 错误', { statusCode: res.statusCode, url: url.substring(0, 100) });
        reject(new Error(`HTTP ${res.statusCode}: ${url}`));
        return;
      }

      const chunks = [];
      let downloadedBytes = 0;

      res.on('data', chunk => {
        chunks.push(chunk);
        downloadedBytes += chunk.length;
        // 每下载 1MB 记录一次进度
        if (downloadedBytes % (1024 * 1024) < chunk.length) {
          logger.debug('downloadToBuffer 下载中', { downloadedBytes: `${(downloadedBytes / 1024 / 1024).toFixed(2)} MB` });
        }
      });

      res.on('end', () => {
        const buffer = Buffer.concat(chunks);
        const duration = Date.now() - startTime;
        logger.info('downloadToBuffer 完成', {
          bytes: buffer.length,
          duration,
          speed: `${(buffer.length / 1024 / duration * 1000).toFixed(2)} KB/s`
        });
        resolve(buffer);
      });

      res.on('error', (err) => {
        logger.error('downloadToBuffer 流错误', { error: err.message });
        reject(err);
      });
    });

    req.on('error', (err) => {
      logger.error('downloadToBuffer 请求错误', { error: err.message, url: url.substring(0, 100) });
      reject(err);
    });

    req.setTimeout(30000, () => {
      logger.error('downloadToBuffer 超时', { url: url.substring(0, 100) });
      req.destroy();
      reject(new Error('Download timeout'));
    });
  });
};

/**
 * 转换音频流（使用临时文件）
 */
const convertStream = async (inputBuffer, format = 'mp3', options = {}) => {
  const { bitrate = '192k', sampleRate = '44100', channels = 2 } = options;
  const codec = getCodec(format);
  const outputFormat = getFormat(format);
  const uniqueId = crypto.randomUUID();
  const tempDir = os.tmpdir();
  const inputPath = path.join(tempDir, `m4s-input-${uniqueId}.m4s`);
  const outputPath = path.join(tempDir, `mp3-output-${uniqueId}.${format}`);

  logger.info('开始转换: %s, 大小: %d bytes', uniqueId, inputBuffer.length);

  try {
    await fs.promises.writeFile(inputPath, inputBuffer);

    await queueConversion(() => new Promise((resolve, reject) => {
      const startTime = Date.now();

      ffmpeg(inputPath)
        .audioCodec(codec)
        .audioBitrate(bitrate)
        .audioFrequency(parseInt(sampleRate))
        .audioChannels(channels)
        .format(outputFormat)
        .on('start', (cmd) => logger.debug('FFmpeg 启动: %s', cmd))
        .on('end', () => {
          logger.info('转换完成: %s, 耗时: %dms', uniqueId, Date.now() - startTime);
          resolve();
        })
        .on('error', (err, stdout, stderr) => {
          logger.error('FFmpeg 错误: %s', err.message);
          reject(new AppError(`音频转换失败: ${err.message}`, 500));
        })
        .save(outputPath);
    }));

    const outputBuffer = await fs.promises.readFile(outputPath);
    const contentType = format === 'mp3' ? 'audio/mpeg' : 'audio/aac';

    return { buffer: outputBuffer, contentType };
  } finally {
    setImmediate(() => {
      try { fs.existsSync(inputPath) && fs.unlinkSync(inputPath); } catch (e) {}
      try { fs.existsSync(outputPath) && fs.unlinkSync(outputPath); } catch (e) {}
    });
  }
};

/**
 * 转换音频文件
 */
const convertFile = async (inputPath, outputPath, format = 'mp3', options = {}) => {
  const { bitrate = '192k', sampleRate = '44100', channels = 2 } = options;
  const codec = getCodec(format);
  const outputFormat = getFormat(format);

  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .audioCodec(codec)
      .audioBitrate(bitrate)
      .audioFrequency(parseInt(sampleRate))
      .audioChannels(channels)
      .format(outputFormat)
      .on('end', resolve)
      .on('error', (err) => reject(new AppError(`转换失败: ${err.message}`, 500)))
      .save(outputPath);
  });
};

/**
 * 代理并转换音频流
 */
const proxyAndConvert = async (sourceUrl, format = 'mp3', options = {}) => {
  const inputBuffer = await downloadToBuffer(sourceUrl);
  return convertStream(inputBuffer, format, options);
};

/**
 * 转换并嵌入元数据（封面、标题、艺术家）
 * @param {string} audioUrl - 音频流URL
 * @param {object} metadata - 元数据 { title, artist, coverUrl }
 * @param {string} format - 输出格式 (mp3, m4a, aac)
 * @param {object} options - 转换选项 { bitrate, sampleRate, channels }
 * @param {function} onProgress - 进度回调 (percent, stage)
 */
const convertWithMetadata = async (audioUrl, metadata, format = 'mp3', options = {}, onProgress) => {
  const { bitrate = '192k', sampleRate = '44100', channels = 2 } = options;
  const uniqueId = crypto.randomUUID();
  const tempDir = os.tmpdir();
  const audioInputPath = path.join(tempDir, `audio-input-${uniqueId}.m4s`);
  const audioOutputPath = path.join(tempDir, `audio-output-${uniqueId}.${format}`);
  const coverPath = path.join(tempDir, `cover-${uniqueId}.jpg`);
  const finalOutputPath = path.join(tempDir, `final-${uniqueId}.${format}`);
  const startTime = Date.now();

  logger.info('convertWithMetadata 开始', { title: metadata.title, artist: metadata.artist, format, bitrate, sampleRate });

  try {
    // 步骤1: 下载音频流
    logger.info('convertWithMetadata 步骤1', { stage: 'downloading_audio', message: '下载音频流...' });
    onProgress && onProgress(10, 'downloading_audio');
    const audioBuffer = await downloadToBuffer(audioUrl);
    await fs.promises.writeFile(audioInputPath, audioBuffer);
    logger.info('convertWithMetadata 音频下载完成', { bytes: audioBuffer.length, path: audioInputPath });

    // 步骤2: 下载封面（如果有）
    let hasCover = false;
    if (metadata.coverUrl) {
      try {
        logger.info('convertWithMetadata 步骤2', { stage: 'downloading_cover', message: '下载封面...' });
        onProgress && onProgress(20, 'downloading_cover');
        const coverBuffer = await downloadToBuffer(metadata.coverUrl);
        await fs.promises.writeFile(coverPath, coverBuffer);
        hasCover = true;
        logger.info('convertWithMetadata 封面下载成功', { size: coverBuffer.length, path: coverPath });
      } catch (err) {
        logger.warn('convertWithMetadata 封面下载失败', { message: err.message, coverUrl: metadata.coverUrl });
      }
    } else {
      logger.info('convertWithMetadata 无封面', { message: '跳过封面下载' });
    }

    // 步骤3: 转换音频（不含封面）
    logger.info('convertWithMetadata 步骤3', { stage: 'converting', message: '开始 FFmpeg 转换...' });
    onProgress && onProgress(30, 'converting');
    const codec = getCodec(format);
    const outputFormat = getFormat(format);

    await queueConversion(() => new Promise((resolve, reject) => {
      const convertStartTime = Date.now();

      let ffmpegCmd = ffmpeg(audioInputPath)
        .audioCodec(codec)
        .audioBitrate(bitrate)
        .audioFrequency(parseInt(sampleRate))
        .audioChannels(channels)
        .format(outputFormat);

      // 添加元数据
      if (metadata.title) {
        ffmpegCmd = ffmpegCmd.outputOptions(['-metadata', `title=${metadata.title}`]);
      }
      if (metadata.artist) {
        ffmpegCmd = ffmpegCmd.outputOptions(['-metadata', `artist=${metadata.artist}`]);
      }

      onProgress && onProgress(50, 'encoding');
      logger.info('convertWithMetadata FFmpeg 开始编码', { codec, bitrate, sampleRate, channels });

      let lastProgressLog = Date.now();

      ffmpegCmd
        .on('start', (cmd) => logger.debug('convertWithMetadata FFmpeg 命令: %s', cmd))
        .on('progress', (p) => {
          const percent = 50 + Math.floor(p.percent * 0.4); // 50% -> 90%
          // 每2秒记录一次进度日志
          if (Date.now() - lastProgressLog > 2000) {
            logger.info('convertWithMetadata FFmpeg 编码进度', { percent: p.percent, frames: p.frames });
            lastProgressLog = Date.now();
          }
          onProgress && onProgress(percent, 'encoding');
        })
        .on('end', () => {
          const duration = Date.now() - convertStartTime;
          logger.info('convertWithMetadata FFmpeg 编码完成', { duration, output: audioOutputPath });
          resolve();
        })
        .on('error', (err, stdout, stderr) => {
          logger.error('convertWithMetadata FFmpeg 错误', { message: err.message, stdout, stderr });
          reject(new AppError(`音频转换失败: ${err.message}`, 500));
        })
        .save(audioOutputPath);
    }));

    // 步骤4: 如果有封面，使用 ffmpeg 添加封面和元数据
    if (hasCover) {
      logger.info('convertWithMetadata 步骤4', { stage: 'attaching_cover', message: '添加封面...' });
      onProgress && onProgress(90, 'attaching_cover');
      await attachCoverAndMetadata(audioOutputPath, coverPath, finalOutputPath, metadata, format);
    } else {
      logger.info('convertWithMetadata 步骤4', { stage: 'no_cover', message: '无封面，直接复制' });
      await fs.promises.copyFile(audioOutputPath, finalOutputPath);
    }

    // 步骤5: 读取最终文件
    logger.info('convertWithMetadata 步骤5', { stage: 'finishing', message: '读取最终文件...' });
    onProgress && onProgress(95, 'finishing');
    const outputBuffer = await fs.promises.readFile(finalOutputPath);
    const contentType = format === 'mp3' ? 'audio/mpeg' : 'audio/aac';

    onProgress && onProgress(100, 'complete');
    const totalDuration = Date.now() - startTime;
    logger.info('convertWithMetadata 完成', { bytes: outputBuffer.length, duration: totalDuration });

    return { buffer: outputBuffer, contentType };
  } catch (error) {
    const totalDuration = Date.now() - startTime;
    logger.error('convertWithMetadata 失败', { error: error.message, duration: totalDuration });
    throw error;
  } finally {
    // 清理临时文件
    setImmediate(() => {
      try { fs.existsSync(audioInputPath) && fs.unlinkSync(audioInputPath); } catch (e) {}
      try { fs.existsSync(audioOutputPath) && fs.unlinkSync(audioOutputPath); } catch (e) {}
      try { fs.existsSync(coverPath) && fs.unlinkSync(coverPath); } catch (e) {}
      try { fs.existsSync(finalOutputPath) && fs.unlinkSync(finalOutputPath); } catch (e) {}
    });
  }
};

/**
 * 添加封面和元数据到音频文件
 */
const attachCoverAndMetadata = (audioPath, coverPath, outputPath, metadata, format) => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    logger.info('attachCoverAndMetadata 开始', { audioPath, coverPath, outputPath, format });

    // 封面添加失败时，使用无封面的版本
    const fallback = () => {
      logger.warn('attachCoverAndMetadata 降级到无封面版本', { audioPath, outputPath });
      fs.promises.copyFile(audioPath, outputPath)
        .then(() => {
          logger.info('attachCoverAndMetadata 降级完成', { outputPath });
          resolve();
        })
        .catch((err) => {
          logger.error('attachCoverAndMetadata 降级失败', { error: err.message });
          reject(err);
        });
    };

    // 构建 FFmpeg 命令（封面作为第二个输入，音频作为第一个）
    // MP3 格式需要音频在前，封面在后
    let cmd = ffmpeg(audioPath)
      .input(coverPath)
      .outputOptions([
        '-map', '0:0', '-map', '1:0',  // 映射音频和封面
        '-c', 'copy',                  // 复制流，不重新编码
        '-id3v2_version', '3',         // MP3 需要 ID3v2.3
      ]);

    // MP3 格式使用 ID3v2 元数据
    if (format === 'mp3') {
      if (metadata.title) {
        cmd = cmd.outputOptions(`-metadata=title=${metadata.title}`);
      }
      if (metadata.artist) {
        cmd = cmd.outputOptions(`-metadata=artist=${metadata.artist}`);
      }
      // 使用单引号包裹包含空格的值
      cmd = cmd.outputOptions('-metadata:s:v=title=Album\\ cover');
      cmd = cmd.outputOptions('-metadata:s:v=comment=Cover\\(front\\)');
    }

    cmd.on('start', (c) => {
      logger.info('attachCoverAndMetadata FFmpeg 启动', { command: c });
    })
      .on('end', () => {
        const duration = Date.now() - startTime;
        logger.info('attachCoverAndMetadata 完成', { outputPath, duration });
        resolve();
      })
      .on('error', (err, stdout, stderr) => {
        const duration = Date.now() - startTime;
        logger.error('attachCoverAndMetadata 失败', {
          error: err.message,
          duration,
          stdout: stdout ? stdout.substring(0, 500) : '',
          stderr: stderr ? stderr.substring(0, 1000) : ''
        });
        fallback();
      })
      .save(outputPath);
  });
};

/**
 * 设置FFmpeg路径
 */
const setFFmpegPath = (ffmpegPath) => {
  ffmpeg.setFfmpegPath(ffmpegPath);
};

/**
 * 获取FFmpeg版本信息
 */
const getFFmpegVersion = async () => {
  return new Promise((resolve) => {
    ffmpeg.getAvailableFilters((filters) => {
      resolve(`FFmpeg available, ${filters.length} filters`);
    });
  });
};

module.exports = {
  downloadToBuffer,
  convertStream,
  convertFile,
  convertWithMetadata,
  proxyAndConvert,
  setFFmpegPath,
  getFFmpegVersion,
  getCodec,
  getFormat
};
