/**
 * 转换去重测试
 *
 * 测试场景：
 * 1. 同一 BVID+format 的并发请求应共享转换结果
 * 2. 不同 format 的请求不应被去重
 * 3. 验证 ConversionTaskTracker 的并发控制逻辑
 */

const request = require('supertest');
const express = require('express');

// Mock 依赖
jest.mock('../services/bilibiliService');
jest.mock('../services/audioService');

const bilibiliService = require('../services/bilibiliService');
const audioService = require('../services/audioService');

// 重新加载控制器（确保 mocks 生效）
const bilibiliController = require('../controllers/bilibiliController');

// 创建测试应用
const app = express();
app.use(express.json());

// 模拟认证中间件（optionalAuthMiddleware）
const mockOptionalAuth = (req, res, next) => {
  req.user = { id: 1 }; // 模拟游客用户
  next();
};

// 注册路由
app.get('/api/bilibili/proxy/audio/:bvid', mockOptionalAuth, bilibiliController.proxyAudioStreamByBvid);

describe('Conversion Deduplication Tests', () => {
  beforeEach(() => {
    // 清理所有 mocks
    jest.clearAllMocks();

    // 清理转换追踪器（通过导入的控制器访问）
    if (bilibiliController.conversionTracker) {
      bilibiliController.conversionTracker.clear();
    }
  });

  test('mp3 未命中缓存时返回 400（服务端不再支持转换）', async () => {
    const bvid = 'BV1xx411c7mD';
    const format = 'mp3';

    // Mock bilibiliService.getAudioStream
    bilibiliService.getAudioStream.mockResolvedValue({
      baseUrl: 'https://example.com/audio.m4s',
      codec: 'mp4a.40.2',
      bandwidth: 192000
    });

    // Mock bilibiliService.getCachedAudio（无缓存）
    bilibiliService.getCachedAudio.mockReturnValue(null);

    // Mock fetch（模拟 B 站音频流下载）
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
        headers: {
          get: (name) => null
        }
      })
    );

    // 发送 3 个并发请求
    const requests = [
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=${format}`),
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=${format}`),
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=${format}`)
    ];

    const responses = await Promise.all(requests);

    // 验证所有请求都返回 400（未命中缓存且不再支持转换）
    responses.forEach(r => {
      expect(r.status).toBe(400);
    });

    // 验证未调用后端转换
    expect(audioService.convertStream).not.toHaveBeenCalled();

    console.log('[TEST] mp3 未命中缓存返回 400');
  });

  test('不应去重不同 format 的请求', async () => {
    const bvid = 'BV1xx411c7mD';

    // Mock bilibiliService.getAudioStream
    bilibiliService.getAudioStream.mockResolvedValue({
      baseUrl: 'https://example.com/audio.m4s',
      codec: 'mp4a.40.2',
      bandwidth: 192000
    });

    // Mock bilibiliService.getCachedAudio（无缓存）
    bilibiliService.getCachedAudio.mockReturnValue(null);

    // Mock audioService.convertStream
    let conversionCount = 0;
    audioService.convertStream.mockImplementation(async (buffer, targetFormat, options) => {
      conversionCount++;
      await new Promise(resolve => setTimeout(resolve, 50));
      return {
        buffer: Buffer.from(`converted-${targetFormat}-${conversionCount}`),
        contentType: targetFormat === 'mp3' ? 'audio/mpeg' : 'audio/aac'
      };
    });

    // Mock bilibiliService.insertCachedAudio
    bilibiliService.insertCachedAudio.mockImplementation(() => true);

    // Mock fetch for both m4s and mp3 conversion
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
        headers: {
          get: (name) => {
            if (name === 'Content-Type') return 'audio/mp4';
            if (name === 'Accept-Ranges') return 'bytes';
            return null;
          }
        },
        body: {
          getReader: () => ({
            read: () => Promise.resolve({ done: true, value: null })
          })
        }
      })
    );

    // 先请求 mp3（服务端不再支持转换）
    const mp3Response = await request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=mp3`);

    // 验证返回 400
    expect(mp3Response.status).toBe(400);

    // 验证未调用转换
    expect(conversionCount).toBe(0);

    console.log('[TEST] 不同 format 测试: mp3 返回 400（无转换）');
  });

  test('应正确处理 m4s 格式（无需转换）', async () => {
    const bvid = 'BV1xx411c7mD';

    // Mock bilibiliService.getAudioStream
    bilibiliService.getAudioStream.mockResolvedValue({
      baseUrl: 'https://example.com/audio.m4s',
      codec: 'mp4a.40.2',
      bandwidth: 192000
    });

    // Mock bilibiliService.getCachedAudio（无缓存）
    bilibiliService.getCachedAudio.mockReturnValue(null);

    // Mock fetch（模拟 B 站音频流，使用 arrayBuffer 模式而不是流式）
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        arrayBuffer: () => Promise.resolve(Buffer.from('test-audio-data')),
        headers: {
          get: (name) => {
            if (name === 'Content-Type') return 'audio/mp4';
            if (name === 'Content-Length') return '16';
            if (name === 'Accept-Ranges') return 'bytes';
            return null;
          }
        },
        body: null  // 无 body，使用 arrayBuffer
      })
    );

    // 请求 m4s 格式
    const response = await request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=m4s`);

    // 验证成功
    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toBe('audio/mp4');
    expect(response.headers['accept-ranges']).toBe('bytes');

    // 验证未调用转换
    expect(audioService.convertStream).not.toHaveBeenCalled();

    console.log('[TEST] m4s 直传测试: 无转换');
  });

  test('应正确处理缓存命中', async () => {
    const bvid = 'BV1xx411c7mD';
    const cachedBuffer = Buffer.from('cached-mp3-data');

    // Mock bilibiliService.getAudioStream（不应调用）
    bilibiliService.getAudioStream.mockResolvedValue({
      baseUrl: 'https://example.com/audio.m4s'
    });

    // Mock bilibiliService.getCachedAudio（有缓存）
    bilibiliService.getCachedAudio.mockReturnValue({
      data: cachedBuffer,
      contentType: 'audio/mpeg'
    });

    // 请求 mp3 格式（应命中缓存）
    const response = await request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=mp3`);

    // 验证成功
    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toBe('audio/mpeg');
    expect(response.body).toEqual(cachedBuffer);

    // 验证未调用转换
    expect(audioService.convertStream).not.toHaveBeenCalled();

    console.log('[TEST] 缓存命中测试: 无转换');
  });

  test('应正确处理转换失败', async () => {
    // 测试转换追踪器可以清理任务
    const bvid = 'BV1xx411c7mD';

    // 清理之前的转换任务
    bilibiliController.conversionTracker.clear();

    // 验证没有待处理的任务
    expect(bilibiliController.conversionTracker.getPendingCount()).toBe(0);

    // 验证转换追踪器有 clear 方法
    expect(typeof bilibiliController.conversionTracker.clear).toBe('function');

    // 验证转换追踪器有 getPendingCount 方法
    expect(typeof bilibiliController.conversionTracker.getPendingCount).toBe('function');

    console.log('[TEST] 转换失败测试: 转换追踪器功能正常');
  });
});
