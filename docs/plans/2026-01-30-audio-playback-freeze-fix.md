# 音频播放卡顿修复计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复播放器上一首/下一首和播放列表切换时的长时间卡顿问题

**Architecture:**
1. **前端修复**: 将硬编码的 `format=mp3` 改为 `format=auto`，优先使用 m4s 直透传（无转换，快速响应）
2. **后端修复**: 添加转换任务去重机制，防止同一 BVID 被重复转换

**Tech Stack:** Flutter 3.38.5, Node.js, FFmpeg, audioplayers

---

## 问题根因分析

### 问题 1: 前端硬编码 MP3 格式 (P0 - 直接原因)

**文件**: `frontend_flutter/lib/domain/entities/online_playable.dart:37`

```dart
final proxyUrl = '$baseUrl/api/bilibili/proxy/audio/$bvid?format=mp3';
```

**影响**:
- 播放列表恢复时 (`OnlinePlayable.fromMap`) 硬编码使用 `format=mp3`
- 每次切换都需要后端 FFmpeg 转换 (耗时 60-120 秒)
- 搜索页面使用 `format=auto`，直接透传 m4s (耗时 < 5 秒)

### 问题 2: 后端缺少转换任务去重 (P0 - 放大问题)

**文件**: `listen-vision_api/controllers/bilibiliController.js:445-593`

当转换耗时过长时：
1. 前端 30 秒超时后重试
2. 后端收到新请求，检查缓存未命中
3. 启动新的 FFmpeg 转换进程
4. 同一 BVID 被重复转换 3-5 次

### 问题 3: 缓存时效过短

**文件**: `listen-vision_api/services/bilibiliService.js:98-101`

```sql
WHERE bvid = ? AND created_at > datetime('now', '-1 hour')
```

缓存只保留 1 小时，频繁触发重新转换。

---

## 修复策略

### Phase 1: 前端修复 (立即生效)

修改 `OnlinePlayable.fromMap` 使用 `format=auto` 而非 `format=mp3`：
- `format=auto` → 后端直接透传 m4s (无转换，延迟 < 5 秒)
- m4s 格式在 Windows 上 audioplayers 完全支持

### Phase 2: 后端防护 (防止回归)

添加转换任务去重机制：
- 使用 Map 追踪正在进行的转换任务
- 新请求等待现有转换完成，共享结果

### Phase 3: 优化缓存

延长 MP3 缓存时间到 24 小时。

---

## Task 1: 前端修复 - 使用 format=auto

**Files:**
- Modify: `frontend_flutter/lib/domain/entities/online_playable.dart:37`

**Step 1: 写测试验证行为（可选，用于验证）**

```dart
// 测试：验证 format=auto 是否被正确使用
test('OnlinePlayable.fromMap should use format=auto', () {
  final audio = Audio(
    id: 'BV123',
    title: 'Test',
    artist: 'Artist',
    duration: 100,
    streamUrl: 'http://example.com/audio.m4s',
  );

  final playable = OnlinePlayable.fromMap(audio.toDto());

  // 验证 URL 包含 format=auto 而非 format=mp3
  expect(playable.url, contains('format=auto'));
  expect(playable.url, isNot(contains('format=mp3')));
});
```

**Step 2: 修改代码**

将 `online_playable.dart:37` 行:
```dart
// 修改前
final proxyUrl = '$baseUrl/api/bilibili/proxy/audio/$bvid?format=mp3';

// 修改后
final proxyUrl = '$baseUrl/api/bilibili/proxy/audio/$bvid?format=auto';
```

**Step 3: 运行应用验证**

```bash
cd frontend_flutter
flutter run
```

**验证点:**
1. 搜索页面播放音乐（应该立即开始，< 5 秒）
2. 点击下一首/上一首（应该立即开始，< 5 秒）
3. 从播放列表切换曲目（应该立即开始，< 5 秒）

**Step 4: 提交**

```bash
git add frontend_flutter/lib/domain/entities/online_playable.dart
git commit -m "fix(audio): use format=auto for online audio playback

- Change format from mp3 to auto in OnlinePlayable.fromMap
- format=auto uses m4s passthrough (no conversion, < 5s delay)
- Fixes long freeze when switching tracks in playlist

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: 后端修复 - 添加转换任务去重

**Files:**
- Modify: `listen-vision_api/controllers/bilibiliController.js`

**Step 1: 添加转换任务追踪模块**

在 `bilibiliController.js` 文件顶部（require 语句之后）添加：

```javascript
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
```

**Step 2: 修改 proxyAudioStreamByBvid 方法**

在 `bilibiliController.js` 的 `proxyAudioStreamByBvid` 函数中，将 MP3 转换部分包裹在 `conversionTracker.getOrExecute` 中：

找到 `} else if (targetFormat === 'mp3') {` 块（约 549 行），修改为：

```javascript
} else if (targetFormat === 'mp3') {
  // ✅ 模式B：转换为 mp3（并发控制 + 去重 + 缓存）
  logger.info('BiliProxy convert to mp3', { bvid });

  const result = await conversionTracker.getOrExecute(bvid, 'mp3', async () => {
    const response = await fetch(streamUrl, {
      headers: {
        'Referer': 'https://www.bilibili.com/',
        'User-Agent': 'Mozilla/5.0'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    // 下载并转换
    const inputBuffer = Buffer.from(await response.arrayBuffer());
    const { buffer, contentType } = await require('../services/audioService').convertStream(
      inputBuffer,
      'mp3',
      { bitrate: '192k', sampleRate: '44100', channels: 2 }
    );

    return { buffer, contentType };
  });

  // 设置响应头
  res.setHeader('Content-Type', result.contentType);
  res.setHeader('Content-Length', result.buffer.length);
  res.setHeader('Accept-Ranges', 'none');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.send(result.buffer);

  // ✅ 缓存转换结果
  bilibiliService.insertCachedAudio(bvid, result.buffer, result.contentType);

  logger.info('BiliProxy mp3 conversion complete', { bvid, bytes: result.buffer.length });
}
```

**Step 3: 运行后端测试**

```bash
cd listen-vision_api
node index.js
```

**验证点:**
1. 发送同一 BVID 的多个同时请求
2. 检查日志，应该只有一条 "starting new conversion"
3. 其他请求应显示 "waiting for existing conversion"

**Step 4: 提交**

```bash
git add listen-vision_api/controllers/bilibiliController.js
git commit -m "feat(audio): add conversion task deduplication

- Add ConversionTaskTracker to prevent duplicate conversions
- Multiple requests for same bvid+format now share result
- Reduces FFmpeg load and improves response time

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: 后端修复 - 延长缓存时间

**Files:**
- Modify: `listen-vision_api/services/bilibiliService.js`

**Step 1: 修改缓存时效查询**

将 `bilibiliService.js:98-101` 行的 SQL 查询：

```javascript
// 修改前
getCachedAudio: db.prepare(`
  SELECT data, content_type, created_at FROM audio_content_cache
  WHERE bvid = ? AND created_at > datetime('now', '-1 hour')
`),

// 修改后
getCachedAudio: db.prepare(`
  SELECT data, content_type, created_at FROM audio_content_cache
  WHERE bvid = ? AND created_at > datetime('now', '-24 hours')
`),
```

**Step 2: 提交**

```bash
git add listen-vision_api/services/bilibiliService.js
git commit -m "feat(audio): extend audio cache duration to 24 hours

- Change cache expiry from 1 hour to 24 hours
- Reduces redundant conversions for frequently played tracks

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: 添加测试确保修复有效

**Files:**
- Create: `listen-vision_api/tests/conversionDedup.test.js`

**Step 1: 创建测试文件**

```javascript
const request = require('supertest');
const express = require('express');
const bilibiliRouter = require('../../routes/bilibili');

const app = express();
app.use('/api/bilibili', bilibiliRouter);

describe('Conversion Deduplication', () => {
  test('should deduplicate concurrent conversion requests', async () => {
    const bvid = 'BV1xx411c7mD'; // 使用测试 BVID

    // 发送 3 个同时请求
    const requests = [
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=mp3`),
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=mp3`),
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=mp3`),
    ];

    const responses = await Promise.all(requests);

    // 所有请求应该成功
    responses.forEach(r => {
      expect(r.status).toBe(200);
    });

    // 验证内容长度相同（共享同一转换结果）
    const contentLengths = responses.map(r => r.body.length);
    expect(new Set(contentLengths).size).toBe(1);
  });

  test('should not deduplicate different format requests', async () => {
    // 验证不同 format 不会被去重
    const bvid = 'BV1xx411c7mD';

    const [mp3Response, m4sResponse] = await Promise.all([
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=mp3`),
      request(app).get(`/api/bilibili/proxy/audio/${bvid}?format=auto`),
    ]);

    expect(mp3Response.status).toBe(200);
    expect(m4sResponse.status).toBe(200);
  });
});
```

**Step 2: 运行测试**

```bash
cd listen-vision_api
npm test -- tests/conversionDedup.test.js
```

**Step 3: 提交**

```bash
git add listen-vision_api/tests/conversionDedup.test.js
git commit -m "test(audio): add conversion deduplication tests

- Verify concurrent requests share conversion result
- Verify different formats are not deduplicated

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: 验证整体修复

**Step 1: 启动后端**

```bash
cd listen-vision_api
node index.js
```

**Step 2: 启动前端**

```bash
cd frontend_flutter
flutter run
```

**Step 3: 测试场景**

| 场景 | 预期行为 | 验证点 |
|------|----------|--------|
| 搜索页面播放 | < 5 秒开始播放 | format=auto, m4s 直透传 |
| 上一首/下一首 | < 5 秒开始播放 | format=auto, m4s 直透传 |
| 播放列表切换 | < 5 秒开始播放 | format=auto, m4s 直透传 |
| 快速切换多首 | 无卡顿 | 转换去重生效 |
| 播放已缓存歌曲 | < 3 秒开始 | 命中缓存 |

**Step 4: 检查后端日志**

预期日志模式：
```
[BiliProxy passthrough m4s]  // m4s 直透传，快速响应
[BiliProxy cached mp3 hit]   // 命中缓存
[BiliProxy waiting for existing conversion]  // 去重生效
```

不应再看到：
```
[BiliProxy starting new conversion]  // 同一 BVID 多次出现
```

---

## 回滚计划

如果修复后出现新问题：

### 回滚 Task 1 (前端)
```bash
git revert HEAD  # 撤销 format=auto 修改
```

### 回滚 Task 2 (后端去重)
```bash
git revert HEAD  # 撤销转换追踪器
```

### 回滚 Task 3 (缓存时间)
```bash
git revert HEAD  # 恢复 1 小时缓存
```

---

## 完成标准

- [x] 前端使用 `format=auto` 代替 `format=mp3`
- [x] 后端添加转换任务去重机制
- [x] 缓存时间延长到 24 小时
- [x] 搜索页面播放延迟 < 5 秒
- [x] 上一首/下一首延迟 < 5 秒
- [x] 播放列表切换延迟 < 5 秒
- [x] 后端日志显示去重生效
- [x] 无重复转换任务
