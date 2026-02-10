# 下载功能完全前端化迁移方案

**创建日期**: 2026-02-08
**预计工作量**: 1-2 天
**风险等级**: 低（零转换，纯 Dart 实现）
**输出格式**: M4A (AAC)

---

## 一、核心方案：零转换 + metadata_god

### 1.1 技术选型

| 组件 | 方案 | 说明 |
|------|------|------|
| **音频格式** | M4A (AAC) | B站原始格式，无需转换 |
| **元数据写入** | `metadata_god` | 纯 Dart 实现，跨平台 |
| **下载方式** | HTTP + Range | 复用现有断点续传 |

### 1.2 核心发现

1. **B站音频流格式**：DASH 返回的是 **AAC 编码的 m4s 容器**，本质是标准 AAC 音频
2. **just_audio 支持**：在 Android (ExoPlayer) 和 iOS (AVFoundation) 上**原生支持 AAC**
3. **零转换方案**：m4s 文件只需重命名为 `.m4a` 即可直接播放
4. **元数据方案**：使用 `metadata_god` 纯 Dart 库写入元数据，无需 FFmpeg

### 1.3 方案优势

| 对比项 | 原方案 (FFmpeg) | 新方案 (M4A + metadata_god) |
|--------|-----------------|------------------------------|
| 包体增加 | +50MB | +2MB |
| 下载时间 | 慢 (需转换) | 极快 (仅下载) |
| CPU 占用 | 高 | 极低 |
| 音质 | 有损 (转码) | 无损 (原始 AAC) |
| 复杂度 | 高 | 低 |
| 元数据 | ✅ 支持 | ✅ 支持 |

### 1.4 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        前端                                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │  DownloadQueue  │    │  metadata_god   │  ← 写入元数据    │
│  │   (队列管理)     │───→│  (纯 Dart)      │                  │
│  └─────────────────┘    └─────────────────┘                 │
│          │                      │                            │
│          ▼                      ▼                            │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │  B站 API 直接   │    │  文件系统操作   │                  │
│  │  HTTP 请求      │    │  m4s→m4a 重命名 │                  │
│  └─────────────────┘    └─────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      后端（极简）                            │
├─────────────────────────────────────────────────────────────┤
│  GET  /api/bilibili/video/:bvid      ← 视频信息             │
│  GET  /api/bilibili/audio/:bvid      ← 音频流URL (fnval=16) │
│  GET  /api/bilibili/proxy/audio/:bvid ← 代理音频流           │
│  POST /api/user/favorites            ← 收藏同步              │
└─────────────────────────────────────────────────────────────┘
```

---

## 二、现状分析

### 当前架构（混合模式）

| 组件 | 后端 | 前端 |
|------|------|------|
| **下载控制** | `downloadTaskStore.js` 任务状态存储 | `DownloadRepository` 下载管理 |
| **音频转换** | FFmpeg 转换 + 元数据嵌入 | - |
| **进度推送** | SSE 实时推送 | SSE 监听 |
| **断点续传** | HTTP Range 支持 | `ResumableDownloadService` |
| **并发控制** | `ConversionTaskTracker` | `DownloadSlotManager` |

### 迁移必要性

1. **FFmpeg 依赖**：后端依赖 FFmpeg，部署复杂
2. **服务器负载**：音频转换消耗 CPU 资源
3. **架构耦合**：前后端通过 SSE 紧密耦合

---

## 三、核心变更

### 3.1 后端删除（完全移除）

| 文件 | 删除内容 |
|------|----------|
| `bilibiliController.js` | `downloadAudioWithMetadata`、`downloadAudioWithRange` |
| `bilibiliController.js` | `getDownloadStatus`、`confirmDownload`、`cancelDownload`、`heartbeat` |
| `services/downloadTaskStore.js` | **整个文件删除** |
| `routes/bilibili.js` | 下载相关路由 |
| `services/audio/conversionService.js` | **整个文件删除**（FFmpeg 不再需要） |

### 3.2 后端保留（必要接口）

| 接口 | 用途 |
|------|------|
| `GET /api/bilibili/video/:bvid` | 获取视频元数据 |
| `GET /api/bilibili/audio/:bvid` | 获取音频流 URL |
| `GET /api/bilibili/proxy/audio/:bvid` | 代理音频流（防盗链，支持 Range） |
| `GET /api/bilibili/proxy/image` | 代理封面图片 |

### 3.3 前端新增/重构

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `lib/services/bilibili_downloader.dart` | **新建** | B站音频下载器（零转换方案） |
| `lib/services/metadata_writer.dart` | **新建** | 元数据写入服务 (metadata_god) |
| `lib/data/repositories/download_repository.dart` | **重构** | 移除 SSE 下载，使用新下载器 |
| `lib/services/resumable_download_service.dart` | **保留** | 继续用于断点续传 |
| `lib/models/download_task.dart` | **微调** | 移除 `requestId`、`resumeToken` 字段 |

---

## 四、详细设计

### 4.1 元数据写入服务

**新建文件**: `frontend_flutter/lib/services/metadata_writer.dart`

```dart
import 'dart:io';
import 'package:metadata_god/metadata_god.dart';
import 'package:mime/mime.dart';
import '../core/utils/app_logger.dart';

/// 音频元数据
class AudioMetadata {
  final String title;
  final String artist;
  final String? album;
  final String? coverPath;

  AudioMetadata({
    required this.title,
    required this.artist,
    this.album,
    this.coverPath,
  });
}

/// 元数据写入结果
class MetadataWriteResult {
  final bool success;
  final String? error;

  MetadataWriteResult({
    required this.success,
    this.error,
  });
}

/// 使用 metadata_god 写入音频元数据
///
/// 功能：
/// 1. 写入标题、艺术家、专辑等文本元数据
/// 2. 嵌入封面图片
/// 3. 支持 M4A/MP3 格式
class MetadataWriter {
  static bool _initialized = false;

  /// 初始化 metadata_god
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await MetadataGod.initialize();
      _initialized = true;
      AppLogger.info('MetadataWriter', 'metadata_god 初始化完成');
    }
  }

  /// 写入元数据到音频文件
  ///
  /// [filePath] 音频文件路径
  /// [metadata] 元数据
  static Future<MetadataWriteResult> writeMetadata({
    required String filePath,
    required AudioMetadata metadata,
  }) async {
    try {
      await ensureInitialized();

      AppLogger.info('MetadataWriter', '开始写入元数据: $filePath');

      // 构建封面对象
      Picture? picture;
      if (metadata.coverPath != null) {
        final coverFile = File(metadata.coverPath!);
        if (await coverFile.exists()) {
          final imageData = await coverFile.readAsBytes();
          picture = Picture(
            data: imageData,
            mimeType: lookupMimeType(metadata.coverPath!) ?? 'image/jpeg',
          );
          AppLogger.info('MetadataWriter', '封面图片大小: ${imageData.length} bytes');
        }
      }

      // 写入元数据
      await MetadataGod.writeMetadata(
        filePath,
        Metadata(
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album ?? 'Bilibili',
          picture: picture,
        ),
      );

      AppLogger.info('MetadataWriter', '元数据写入成功');

      return MetadataWriteResult(success: true);
    } catch (e) {
      AppLogger.error('MetadataWriter', '元数据写入失败: $e');
      return MetadataWriteResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 读取音频文件元数据
  static Future<Metadata?> readMetadata(String filePath) async {
    try {
      await ensureInitialized();
      return await MetadataGod.readMetadata(filePath);
    } catch (e) {
      AppLogger.error('MetadataWriter', '读取元数据失败: $e');
      return null;
    }
  }
}
```

### 4.2 B站音频下载器（零转换版本）

**新建文件**: `frontend_flutter/lib/services/bilibili_downloader.dart`

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../core/utils/app_logger.dart';
import '../data/api/bilibili_api_client.dart';
import 'metadata_writer.dart';

/// 下载结果
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int? fileSize;
  final String format;

  DownloadResult({
    required this.success,
    this.filePath,
    this.error,
    this.fileSize,
    this.format = 'm4a',
  });
}

/// B站音频下载器（零转换版本）
///
/// 流程：
/// 1. 调用后端 /audio/:bvid 获取音频流 URL (fnval=16)
/// 2. 直接下载 m4s 音频文件
/// 3. 下载封面图片
/// 4. 重命名 m4s → m4a（零转换！）
/// 5. 使用 metadata_god 写入元数据
/// 6. 保存到目标路径
class BilibiliDownloader {
  final BilibiliApiClient _api;
  final Dio _dio;

  BilibiliDownloader(this._api) : _dio = Dio();

  /// 下载音频（零转换版本）
  ///
  /// [bvid] 视频 BVID
  /// [saveDir] 保存目录
  /// [fileName] 文件名（不含扩展名）
  /// [onProgress] 进度回调 (百分比, 阶段)
  Future<DownloadResult> download({
    required String bvid,
    required String saveDir,
    required String fileName,
    void Function(int percent, String stage)? onProgress,
  }) async {
    // 临时文件目录
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempM4s = '${tempDir.path}/$timestamp$bvid.m4s';
    final tempCover = '${tempDir.path}/$timestamp$bvid.jpg';

    try {
      AppLogger.info('BilibiliDownloader', '开始下载: $bvid');

      // 步骤1: 获取视频信息
      onProgress?.call(5, 'fetching_info');
      final videoInfo = await _api.getVideoInfo(bvid);

      final title = videoInfo.title;
      final artist = videoInfo.owner?.name ?? '未知艺术家';
      final coverUrl = videoInfo.cover;

      AppLogger.info('BilibiliDownloader', '获取视频信息: $title - $artist');

      // 步骤2: 获取音频流 URL（使用 fnval=16 获取纯音频流）
      onProgress?.call(10, 'fetching_audio');
      final audioStream = await _api.getAudioStream(bvid);

      if (audioStream.baseUrl == null) {
        throw Exception('无法获取音频流 URL');
      }

      final audioUrl = audioStream.baseUrl!;
      AppLogger.info('BilibiliDownloader', '获取音频流 URL: ${audioUrl.substring(0, 50)}...');

      // 步骤3: 下载 m4s 音频文件（50% 进度）
      onProgress?.call(15, 'downloading_audio');
      await _downloadFile(
        audioUrl,
        tempM4s,
        onProgress: (received, total) {
          final percent = 15 + ((received / total) * 50).toInt();
          onProgress?.call(percent.clamp(15, 65), 'downloading_audio');
        },
      );

      final m4sFile = File(tempM4s);
      final m4sSize = await m4sFile.length();
      AppLogger.info('BilibiliDownloader', '音频下载完成: $m4sSize bytes');

      // 步骤4: 重命名 m4s → m4a（零转换！）
      onProgress?.call(65, 'processing_file');
      final safeFileName = _sanitizeFileName(fileName);
      final m4aPath = p.join(saveDir, '$safeFileName.m4a');

      // 确保目标目录存在
      await Directory(saveDir).create(recursive: true);

      // 移动文件（重命名）
      await m4sFile.rename(m4aPath);
      AppLogger.info('BilibiliDownloader', '文件已重命名: $m4aPath');

      // 步骤5: 下载封面（10% 进度）
      onProgress?.call(70, 'downloading_cover');
      String? coverPath;
      if (coverUrl != null) {
        try {
          await _downloadFile(coverUrl, tempCover);
          coverPath = tempCover;
          AppLogger.info('BilibiliDownloader', '封面下载完成');
        } catch (e) {
          AppLogger.warn('BilibiliDownloader', '封面下载失败: $e');
        }
      }

      // 步骤6: 写入元数据（20% 进度）
      onProgress?.call(80, 'writing_metadata');
      final metadataResult = await MetadataWriter.writeMetadata(
        filePath: m4aPath,
        metadata: AudioMetadata(
          title: title,
          artist: artist,
          album: 'https://www.bilibili.com/video/$bvid',
          coverPath: coverPath,
        ),
      );

      if (!metadataResult.success) {
        AppLogger.warn('BilibiliDownloader', '元数据写入失败: ${metadataResult.error}');
      }

      // 步骤7: 完成
      onProgress?.call(100, 'completed');

      final finalFile = File(m4aPath);
      final finalSize = await finalFile.length();

      AppLogger.info('BilibiliDownloader', '下载完成: $m4aPath ($finalSize bytes)');

      return DownloadResult(
        success: true,
        filePath: m4aPath,
        fileSize: finalSize,
        format: 'm4a',
      );
    } catch (e) {
      AppLogger.error('BilibiliDownloader', '下载失败: $e');

      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      // 清理临时文件
      await _deleteIfExists(tempM4s);
      await _deleteIfExists(tempCover);
    }
  }

  /// 下载文件
  Future<void> _downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      options: Options(
        headers: {
          'Referer': 'https://www.bilibili.com/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ),
      onReceiveProgress: onProgress,
    );
  }

  /// 删除文件（忽略错误）
  Future<void> _deleteIfExists(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 清理文件名（移除非法字符）
  String _sanitizeFileName(String name) {
    // 移除或替换不允许的字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(invalidChars, '_').trim();
  }
}
```

### 4.3 DownloadRepository 重构

**修改**: `lib/data/repositories/download_repository.dart`

```dart
class DownloadRepository {
  // ... 现有代码 ...

  // 移除 SSE 下载方法 _downloadWithSSE
  // 移除 requestId/resumeToken 相关逻辑

  /// 开始下载（重构版本）
  Future<void> startDownload(int taskId) async {
    // ... 前置检查代码保持不变 ...

    try {
      // 检查是否支持断点续传
      final canResume = task.downloadedBytes > 0 &&
          task.etag != null;

      if (canResume) {
        // 使用断点续传下载
        await _downloadWithResumable(taskId, task, cancelToken);
      } else {
        // 使用新的 BilibiliDownloader（替代 SSE）
        await _downloadWithBilibiliDownloader(taskId, task, cancelToken);
      }

      // 下载完成逻辑保持不变 ...
    } catch (e) {
      // 错误处理逻辑保持不变 ...
    }
  }

  /// 使用 BilibiliDownloader 下载（新增）
  Future<void> _downloadWithBilibiliDownloader(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
  ) async {
    final downloader = BilibiliDownloader(_bilibiliApi);

    // 检查取消状态
    if (cancelToken.isCancelled) {
      throw TaskCanceledException();
    }

    // 生成文件名
    final fileName = task.track?.title ?? task.bvid ?? 'download';
    final saveDir = p.dirname(task.savePath);

    final result = await downloader.download(
      bvid: task.bvid!,
      saveDir: saveDir,
      fileName: fileName,
      onProgress: (percent, stage) {
        // 检查取消
        if (cancelToken.isCancelled) {
          cancelToken.cancel('用户取消');
          throw TaskCanceledException();
        }

        // 更新数据库
        _downloadTaskDao.updateProgressPercent(taskId, percent);
        _downloadTaskDao.updateProgressTimestamp(taskId, DateTime.now());

        // 更新 Track 状态
        if (task.trackId != null) {
          _trackDao.updateDownloadStatus(
            task.trackId!,
            DownloadStatus.downloading,
            percent,
          );
        }

        // 通知 UI
        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: percent,
          stage: stage,
          message: _getStageMessage(stage),
        ));
      },
    );

    if (!result.success) {
      throw Exception(result.error ?? '下载失败');
    }

    // 更新任务状态
    await _downloadTaskDao.updateDownloadPath(taskId, result.filePath!);
    await _downloadTaskDao.updateFileSize(taskId, result.fileSize!);
  }

  /// 获取阶段描述
  String _getStageMessage(String stage) {
    const messages = {
      'fetching_info': '获取视频信息',
      'fetching_audio': '获取音频流',
      'downloading_audio': '下载音频中',
      'downloading_cover': '下载封面中',
      'processing_file': '处理文件',
      'writing_metadata': '写入元数据',
      'completed': '下载完成',
    };
    return messages[stage] ?? stage;
  }
}
```

---

## 五、数据流变更

### 5.1 旧流程（SSE + FFmpeg）

```
前端                              后端
│                                 │
├─ 1. GET /download/:bvid ────────→│
│                                 ├─ 2. 获取视频信息
│                                 ├─ 3. 下载音频流
│                                 ├─ 4. FFmpeg 转换
│                                 ├─ 5. SSE 推送进度
│← 6. SSE 进度事件 ─────────────────┤
│← 7. SSE 文件数据 ─────────────────┤
│                                 │
└─ 8. POST /confirm ─────────────→│
```

### 5.2 新流程（零转换 + metadata_god）

```
前端                              后端
│                                 │
├─ 1. GET /video/:bvid ──────────→│  (仅元数据)
│← 2. 视频信息 ───────────────────┤
│                                 │
├─ 3. GET /audio/:bvid ──────────→│  (仅 URL, fnval=16)
│← 4. 音频流 URL ─────────────────┤
│                                 │
├─ 5. 直接下载 m4s ───────────────→│ (代理接口)
│← 6. m4s 数据 (Range 支持) ──────┤
│                                 │
├─ 7. 重命名 m4s → m4a            │ (零转换!)
├─ 8. metadata_god 写入元数据      │
├─ 9. 保存文件                    │
│                                 │
└─ 10. 本地完成                   │
```

---

## 六、依赖变更

### 6.1 后端移除依赖

```json
{
  "removed": [
    "fluent-ffmpeg",
    "ffmpeg-static"
  ]
}
```

### 6.2 前端新增依赖

```yaml
dependencies:
  # 元数据写入（纯 Dart，零依赖）
  metadata_god: ^1.0.0
  mime: ^1.0.0

  # 现有依赖保持不变
  dio: ^5.0.0
  path: ^1.8.0
```

### 6.3 前端移除依赖

```yaml
# 不再需要
# ffmpeg_kit_flutter: ^6.0.3  # 移除
```

---

## 七、迁移步骤

### Phase 1: 准备工作 (0.5 天)
1. 添加 `metadata_god` 依赖
2. 创建 `MetadataWriter` 服务
3. 创建 `BilibiliDownloader` 服务

### Phase 2: 重构下载逻辑 (0.5 天)
1. 重构 `DownloadRepository._downloadWithSSE` → `_downloadWithBilibiliDownloader`
2. 移除 SSE 相关代码
3. 更新 `DownloadTask` 模型

### Phase 3: 后端清理 (0.5 天)
1. 删除 `downloadTaskStore.js`
2. 删除 `conversionService.js`
3. 移除下载相关路由
4. 更新 API 文档

### Phase 4: 测试与验证 (0.5 天)
1. 单元测试：`MetadataWriter`
2. 集成测试：完整下载流程
3. UI 测试：下载页面交互
4. 音质测试：对比原方案

---

## 八、注意事项

### 8.1 metadata_god 限制

`metadata_god` 支持的平台：
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ❌ Web（不支持）

### 8.2 M4A 格式兼容性

M4A (AAC) 格式播放支持：
- ✅ Android (ExoPlayer)
- ✅ iOS (AVFoundation)
- ✅ Windows (Media Foundation)
- ✅ macOS (AVFoundation)
- ✅ Linux (GStreamer)

### 8.3 临时文件管理

```
${临时目录}/
  ├── ${timestamp}${bvid}.m4s    # 原始音频（处理后删除）
  └── ${timestamp}${bvid}.jpg    # 封面图片（处理后删除）
```

### 8.4 权限要求

Android 需要以下权限：
```xml
<uses-permission android:name="android.permission.INTERNET" />
<!-- Android 10+ 不需要存储权限，使用 Scoped Storage -->
```

---

## 九、文件变更清单

### 后端删除

| 路径 | 说明 |
|------|------|
| `listen-vision_api/services/downloadTaskStore.js` | 任务状态存储 |
| `listen-vision_api/services/audio/conversionService.js` | FFmpeg 转换 |

### 后端修改

| 路径 | 变更 |
|------|------|
| `listen-vision_api/controllers/bilibiliController.js` | 删除下载相关方法 |
| `listen-vision_api/routes/bilibili.js` | 删除下载路由 |
| `listen-vision_api/services/audio/index.js` | 移除 conversionService 导出 |

### 前端新建

| 路径 | 说明 |
|------|------|
| `frontend_flutter/lib/services/bilibili_downloader.dart` | B站下载器（零转换） |
| `frontend_flutter/lib/services/metadata_writer.dart` | 元数据写入服务 |

### 前端修改

| 路径 | 变更 |
|------|------|
| `frontend_flutter/lib/data/repositories/download_repository.dart` | 使用新下载器 |
| `frontend_flutter/lib/models/download_task.dart` | 移除 requestId，支持 m4a |
| `frontend_flutter/lib/data/api/bilibili_api_client.dart` | 移除下载方法 |
| `frontend_flutter/pubspec.yaml` | 添加 metadata_god |

---

## 十、预期收益

| 指标 | 原方案 | 新方案 | 改进 |
|------|--------|--------|------|
| 包体大小 | +50MB | +2MB | **-96%** |
| 下载时间 | 100% | 60% | **+40%** |
| CPU 占用 | 高 | 极低 | **-90%** |
| 服务器负载 | 高 | 低 | **-70%** |
| 音质 | 有损 | 无损 | **原始 AAC** |

---

## 十一、回退方案

如果 `metadata_god` 不可用（如 Web 平台），可使用降级方案：

```dart
abstract class MetadataWriter {
  static Future<MetadataWriteResult> writeMetadata(...) async {
    if (kIsWeb) {
      // Web 平台：不写入元数据，仅重命名
      return MetadataWriteResult(success: true);
    } else {
      // 移动/桌面平台：使用 metadata_god
      return await _writeWithMetadataGod(...);
    }
  }
}
```

---

**文档版本**: 2.0
**最后更新**: 2026-02-08
**更新内容**: 采用 M4A + metadata_god 零转换方案

## 五、数据流变更

### 5.1 旧流程（SSE 模式）

```
前端                              后端
│                                 │
├─ 1. GET /download/:bvid ────────→│
│                                 ├─ 2. 获取视频信息
│                                 ├─ 3. 下载音频流
│                                 ├─ 4. FFmpeg 转换
│                                 ├─ 5. SSE 推送进度
│← 6. SSE 进度事件 ─────────────────┤
│← 7. SSE 文件数据 ─────────────────┤
│                                 │
└─ 8. POST /confirm ─────────────→│
```

### 5.2 新流程（纯前端）

```
前端                              后端
│                                 │
├─ 1. GET /video/:bvid ──────────→│  (仅元数据)
│← 2. 视频信息 ───────────────────┤
│                                 │
├─ 3. GET /audio/:bvid ──────────→│  (仅 URL)
│← 4. 音频流 URL ─────────────────┤
│                                 │
├─ 5. 直接下载音频流 ──────────────→│ (代理接口)
│← 6. 音频数据 (Range 支持) ───────┤
│                                 │
├─ 7. 前端 FFmpeg 转换            │
├─ 8. 写入元数据                  │
├─ 9. 保存文件                    │
│                                 │
└─ 10. 本地完成                   │
```

---

## 六、依赖变更

### 6.1 后端移除依赖

```json
{
  "removed": [
    "fluent-ffmpeg",
    "ffmpeg-static"
  ]
}
```

### 6.2 前端新增依赖

```yaml
dependencies:
  ffmpeg_kit_flutter: ^6.0.3  # FFmpeg 前端版本
  path_provider: ^2.1.0       # 临时文件路径
  crypto: ^3.0.0              # 文件校验
```

---

## 七、迁移步骤

### Phase 1: 准备工作
1. 添加 `ffmpeg_kit_flutter` 依赖
2. 创建 `AudioConverter` 服务
3. 创建 `BilibiliDownloader` 服务

### Phase 2: 重构下载逻辑
1. 重构 `DownloadRepository._downloadWithSSE` → `_downloadWithBilibiliDownloader`
2. 移除 SSE 相关代码
3. 更新 `DownloadTask` 模型

### Phase 3: 后端清理
1. 删除 `downloadTaskStore.js`
2. 删除 `conversionService.js`
3. 移除下载相关路由
4. 更新 API 文档

### Phase 4: 测试与验证
1. 单元测试：`AudioConverter`
2. 集成测试：完整下载流程
3. UI 测试：下载页面交互

---

## 八、注意事项

### 8.1 FFmpeg 版本兼容

`ffmpeg_kit_flutter` 需要编译的架构支持：
- Android: `arm64-v8a`, `armeabi-v7a`, `x86_64`
- iOS: `arm64`, `x86_64` (模拟器)

建议使用 `ffmpeg_kit_flutter_full` 版本（包含完整功能）。

### 8.2 临时文件管理

```
${临时目录}/
  ├── download_${taskId}_audio.m4s   # 原始音频
  ├── download_${taskId}_cover.jpg   # 封面图片
  └── download_${taskId}_output.mp3  # 转换后音频
```

### 8.3 权限要求

Android 需要以下权限：
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 8.4 回退方案

如果 FFmpeg 不可用（如 Web 平台），可保留后端转换作为备选：

```dart
abstract class AudioConverter {
  static Future<ConvertResult> convertWithMetadata(...) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _convertWithFFmpeg(...);
    } else {
      return await _convertWithBackend(...); // 回退到后端
    }
  }
}
```

---

## 九、文件变更清单

### 后端删除

| 路径 | 说明 |
|------|------|
| `listen-vision_api/services/downloadTaskStore.js` | 任务状态存储 |
| `listen-vision_api/services/audio/conversionService.js` | FFmpeg 转换 |

### 后端修改

| 路径 | 变更 |
|------|------|
| `listen-vision_api/controllers/bilibiliController.js` | 删除下载相关方法 |
| `listen-vision_api/routes/bilibili.js` | 删除下载路由 |

### 前端新建

| 路径 | 说明 |
|------|------|
| `frontend_flutter/lib/services/audio_converter.dart` | FFmpeg 音频转换 |
| `frontend_flutter/lib/services/bilibili_downloader.dart` | B站下载器 |

### 前端修改

| 路径 | 变更 |
|------|------|
| `frontend_flutter/lib/data/repositories/download_repository.dart` | 使用新下载器 |
| `frontend_flutter/lib/models/download_task.dart` | 移除 requestId |
| `frontend_flutter/lib/data/api/bilibili_api_client.dart` | 移除下载方法 |
| `frontend_flutter/pubspec.yaml` | 添加 ffmpeg_kit_flutter |

---

## 十、预期收益

1. **降低服务器负载**：音频转换移至客户端，节省 CPU 资源
2. **简化部署**：后端不再需要安装 FFmpeg
3. **提高可扩展性**：下载能力随用户数线性扩展
4. **改善用户体验**：本地转换速度更快，无需等待服务器队列

---

**文档版本**: 1.0
**最后更新**: 2026-02-08
