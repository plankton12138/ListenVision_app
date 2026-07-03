# 下载格式切换（MP3）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 接通下载格式切换链路，让用户可选择 MP3 格式下载音频（通过 FFmpeg M4A→MP3 转码）。

**Architecture:** 重新集成 `ffmpeg_kit_flutter_min_gpl`，实现 `FfmpegService.convert()` → 在 `download_repository` 中将存储的格式字符串转为 `AudioOutputFormat` 枚举并传入 `BilibiliDownloader.download(format:)` → 修正两处硬编码的 `.mp3` 保存路径后缀。

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, ffmpeg_kit_flutter_min_gpl ^6.0.3, media_kit

## Global Constraints

- ffmpeg_kit_flutter_min_gpl: ^6.0.3（含 libmp3lame MP3 编码器）
- 仅支持 MP3 和 M4A，不添加 AAC
- FFmpeg 不可用时回退到 M4A，不抛异常
- 同步执行转换（下载已在后台 isolate）
- 遵循项目现有代码风格：AppLogger 日志、中文注释

---

### Task 1: 添加 ffmpeg_kit_flutter_min_gpl 依赖

**Files:**
- Modify: `frontend_flutter/pubspec.yaml`

**Produces:** `ffmpeg_kit_flutter_min_gpl` 包可用，可导入 `FFmpegKit` / `ReturnCode`

- [ ] **Step 1: 添加依赖声明**

在 `pubspec.yaml` 的 `dependencies` 区块末尾（`# ffmpeg_kit_flutter 已移除` 注释所在行）替换为：

```yaml
  # FFmpeg 音频格式转换（MP3 编码需要 libmp3lame，使用 min_gpl 变体）
  ffmpeg_kit_flutter_min_gpl: ^6.0.3
```

- [ ] **Step 2: 安装依赖**

```bash
cd frontend_flutter && flutter pub get
```

Expected: 成功下载并解析，无版本冲突错误。

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/pubspec.yaml frontend_flutter/pubspec.lock
git commit -m "chore: add ffmpeg_kit_flutter_min_gpl for MP3 conversion"
```

---

### Task 2: 实现 FfmpegService.convert() 和 isAvailable()

**Files:**
- Modify: `frontend_flutter/lib/services/ffmpeg_service.dart`

**Interfaces:**
- Consumes: `ffmpeg_kit_flutter_min_gpl` 包（Task 1）
- Produces:
  - `FfmpegService.convert({required String inputPath, required AudioOutputFormat outputFormat}) → Future<String>` — 返回转换后文件路径
  - `FfmpegService.isAvailable() → Future<bool>` — 检查 FFmpeg 是否可用

- [ ] **Step 1: 重写 ffmpeg_service.dart**

将文件内容替换为：

```dart
import 'dart:io';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';

import '../core/utils/app_logger.dart';

enum AudioOutputFormat {
  m4a('m4a'),
  mp3('mp3'),
  aac('aac');

  final String extension;
  const AudioOutputFormat(this.extension);
}

class FfmpegService {
  /// 将 M4A 音频转换为指定格式
  ///
  /// [inputPath] 源 M4A 文件路径
  /// [outputFormat] 目标格式（m4a 直接返回原路径，零转换）
  ///
  /// 返回转换后的文件路径，转换失败时抛出 [FfmpegException]。
  Future<String> convert({
    required String inputPath,
    required AudioOutputFormat outputFormat,
  }) async {
    // 同格式无需转换
    if (outputFormat == AudioOutputFormat.m4a) {
      return inputPath;
    }

    final outputPath = _buildOutputPath(inputPath, outputFormat);

    if (await File(outputPath).exists()) {
      AppLogger.info('FfmpegService', '输出文件已存在，跳过转换: $outputPath');
      return outputPath;
    }

    String command;
    switch (outputFormat) {
      case AudioOutputFormat.mp3:
        command = '-i "$inputPath" -codec:a libmp3lame -q:a 2 "$outputPath"';
        break;
      case AudioOutputFormat.aac:
        command = '-i "$inputPath" -codec:a aac -b:a 256k "$outputPath"';
        break;
      case AudioOutputFormat.m4a:
        return inputPath;
    }

    AppLogger.info('FfmpegService', '开始转换: $inputPath → $outputPath');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      AppLogger.info('FfmpegService', '转换完成: $outputPath');
      return outputPath;
    } else {
      final output = await session.getOutput();
      final error = 'FFmpeg 转换失败: $output';
      AppLogger.error('FfmpegService', error);
      throw FfmpegException(error);
    }
  }

  /// 取消当前转换任务
  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }

  /// 检查 FFmpeg 是否可用
  Future<bool> isAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      AppLogger.warn('FfmpegService', 'FFmpeg 不可用: $e');
      return false;
    }
  }

  String _buildOutputPath(String inputPath, AudioOutputFormat format) {
    final dir = Directory(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last;
    final nameWithoutExt = baseName.contains('.')
        ? baseName.substring(0, baseName.lastIndexOf('.'))
        : baseName;
    return '$dir${Platform.pathSeparator}$nameWithoutExt.${format.extension}';
  }
}

class FfmpegException implements Exception {
  final String message;
  FfmpegException(this.message);

  @override
  String toString() => 'FfmpegException: $message';
}
```

- [ ] **Step 2: 验证编译**

```bash
cd frontend_flutter && flutter analyze lib/services/ffmpeg_service.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/services/ffmpeg_service.dart
git commit -m "feat: implement FfmpegService with FFmpegKit for real MP3 conversion"
```

---

### Task 3: 在 download_repository 中接通格式参数

**Files:**
- Modify: `frontend_flutter/lib/data/repositories/download_repository.dart`

**Interfaces:**
- Consumes: `AudioOutputFormat` enum (Task 2), `SharedStorageService.instance.getDownloadFormat()`
- Produces: `BilibiliDownloader.download(format: AudioOutputFormat)` — 正确传入用户选择的格式

- [ ] **Step 1: 添加 import**

在 `download_repository.dart` 顶部的 import 区添加：

```dart
import '../../services/ffmpeg_service.dart';
```

- [ ] **Step 2: 在 _downloadWithBilibiliDownloader 方法签名中添加 format 参数**

将方法签名从：

```dart
  Future<void> _downloadWithBilibiliDownloader(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
  ) async {
```

改为：

```dart
  Future<void> _downloadWithBilibiliDownloader(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
    AudioOutputFormat format,
  ) async {
```

- [ ] **Step 3: 在 downloader.download() 调用中传入 format 参数**

在 `downloader.download(` 调用中添加 `format: format,`（约第 431-453 行）：

```dart
    final result = await downloader.download(
      bvid: task.bvid!,
      saveDir: saveDir,
      fileName: fileName,
      format: format,
      onProgress: (percent, stage) {
        // ... existing onProgress code unchanged ...
      },
    );
```

- [ ] **Step 4: 在 startDownload 中解析格式并传入**

在 `startDownload` 方法中（约第 251-258 行），将现有的纯日志调用改为解析枚举并传递：

替换：

```dart
      final downloadFormat = SharedStorageService.instance.getDownloadFormat();

      if (canResume) {
        AppLogger.info('DownloadRepository', '使用断点续传: 已下载 ${task.downloadedBytes} bytes');
        await _downloadWithResumable(taskId, task, cancelToken);
      } else {
        AppLogger.info('DownloadRepository', '使用 BilibiliDownloader 下载: format=$downloadFormat');
        await _downloadWithBilibiliDownloader(taskId, task, cancelToken);
      }
```

改为：

```dart
      final downloadFormatStr = SharedStorageService.instance.getDownloadFormat();
      final downloadFormat = AudioOutputFormat.values.firstWhere(
        (f) => f.extension == downloadFormatStr,
        orElse: () => AudioOutputFormat.m4a,
      );

      if (canResume) {
        AppLogger.info('DownloadRepository', '使用断点续传: 已下载 ${task.downloadedBytes} bytes');
        await _downloadWithResumable(taskId, task, cancelToken);
      } else {
        AppLogger.info('DownloadRepository',
            '使用 BilibiliDownloader 下载: format=${downloadFormat.extension}');
        await _downloadWithBilibiliDownloader(taskId, task, cancelToken, downloadFormat);
      }
```

- [ ] **Step 5: 验证编译**

```bash
cd frontend_flutter && flutter analyze lib/data/repositories/download_repository.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/data/repositories/download_repository.dart
git commit -m "feat: wire download format from settings to BilibiliDownloader"
```

---

### Task 4: 修正 savePath 后缀（硬编码 .mp3 → 动态格式）

**Files:**
- Modify: `frontend_flutter/lib/presentation/widgets/audio/audio_action_menu.dart:430-432`
- Modify: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart:515-517`

**Interfaces:**
- Consumes: `SharedStorageService.instance.getDownloadFormat()` (返回 `'m4a'` 或 `'mp3'`)

- [ ] **Step 1: 修正 audio_action_menu.dart**

在 `audio_action_menu.dart` 找到 `_handleDownload` 方法中的 savePath 构造（约第 430-432 行）：

替换：
```dart
      final downloadDir = await _getDownloadDirectory();
      final sanitizedTitle = _sanitizeTitle(title);
      final savePath = '$downloadDir$sanitizedTitle.mp3';
```

为：
```dart
      final downloadDir = await _getDownloadDirectory();
      final sanitizedTitle = _sanitizeTitle(title);
      final ext = SharedStorageService.instance.getDownloadFormat();
      final savePath = '$downloadDir$sanitizedTitle.$ext';
```

检查文件顶部是否需要添加 import：
```dart
import '../../../core/storage/shared_storage_service.dart';
```

如果该 import 已存在则不添加；否则添加。

- [ ] **Step 2: 修正 playlist_detail_page.dart**

在 `playlist_detail_page.dart` 找到 savePath 构造（约第 515-517 行）：

替换：
```dart
      final downloadDir = await _getDownloadDirectory();
      final sanitizedTitle = _sanitizeTitle(item.title as String? ?? '未知');
      final savePath = '$downloadDir$sanitizedTitle.mp3';
```

为：
```dart
      final downloadDir = await _getDownloadDirectory();
      final sanitizedTitle = _sanitizeTitle(item.title as String? ?? '未知');
      final ext = SharedStorageService.instance.getDownloadFormat();
      final savePath = '$downloadDir$sanitizedTitle.$ext';
```

检查文件顶部是否需要添加 import：
```dart
import '../../../core/storage/shared_storage_service.dart';
```

- [ ] **Step 3: 全量验证编译**

```bash
cd frontend_flutter && flutter analyze
```

Expected: 无新增 issue（全部 pre-existing）。

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/presentation/widgets/audio/audio_action_menu.dart frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart
git commit -m "fix: use dynamic download format extension in savePath instead of hardcoded .mp3"
```

---

## Self-Review

**Spec coverage:** ✅ 所有 3 个设计点均已覆盖（FFmpeg 集成 → Task 1+2，格式参数传递 → Task 3，保存路径修正 → Task 4）

**Placeholder scan:** ✅ 无 TBD/TODO/占位符，所有步骤含完整代码

**Type consistency:** ✅ `AudioOutputFormat` 从 Task 2 定义，Task 3 和 BilibiliDownloader 使用同一枚举。`getDownloadFormat()` 返回 `String` 在所有 Task 中一致处理。
