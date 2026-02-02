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
 */
const downloadToBuffer = (url) => {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    const req = protocol.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}: ${url}`));
        return;
      }
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    });
    req.on('error', reject);
    req.setTimeout(30000, () => {
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
  proxyAndConvert,
  setFFmpegPath,
  getFFmpegVersion,
  getCodec,
  getFormat
};
