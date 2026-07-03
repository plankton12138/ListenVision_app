# 下载音频格式切换 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在设置页面新增下载音频格式选择（默认 m4a / MP3），全局生效，下载时根据设置分流到不同的下载路径。

**Architecture:** 三层改动 — 存储层新增键和方法，UI 层新增格式选择卡片，Repository 层读取设置并分流 `BilibiliDownloader`（m4a）或 `DownloadService`（mp3）。

**Tech Stack:** Flutter / Dart, SharedPreferences, Riverpod

---

### Task 1: 存储层 — 新增 downloadFormat 键和存取方法

**Files:**
- Modify: `frontend_flutter/lib/core/constants/storage_constants.dart:57`
- Modify: `frontend_flutter/lib/core/storage/shared_storage_service.dart:279`

- [ ] **Step 1: 新增存储键常量**

`frontend_flutter/lib/core/constants/storage_constants.dart`，在 `playQuality` 行之后添加：

```dart
  /// 下载音频格式
  static const String downloadFormat = 'download_format';
```

- [ ] **Step 2: 新增存取方法**

`frontend_flutter/lib/core/storage/shared_storage_service.dart`，在类末尾 `}` 之前添加：

```dart
  // ==================== 下载相关快捷方法 ====================

  /// 保存下载音频格式
  Future<bool> setDownloadFormat(String format) => setString(StorageKeys.downloadFormat, format);

  /// 获取下载音频格式（默认 m4a）
  String getDownloadFormat() => getString(StorageKeys.downloadFormat) ?? 'm4a';
```

- [ ] **Step 3: 运行静态分析验证**

```bash
cd frontend_flutter && flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/core/constants/storage_constants.dart frontend_flutter/lib/core/storage/shared_storage_service.dart
git commit -m "feat: 新增下载音频格式存储键和存取方法"
```

---

### Task 2: 设置 UI — 新增格式选择卡片

**Files:**
- Modify: `frontend_flutter/lib/presentation/views/system/settings_page.dart`

- [ ] **Step 1: 添加 import**

在 `settings_page.dart` 顶部 imports 区域，`import '../../viewmodels/system/theme_viewmodel.dart';` 之后添加：

```dart
import '../../../core/storage/shared_storage_service.dart';
```

- [ ] **Step 2: 添加格式选择卡片方法**

在 `_SettingsPageState` 类中，`_buildDarkModeCard` 方法之后添加：

```dart
  /// 下载音频格式选择卡片
  Widget _buildDownloadFormatCard(BuildContext context) {
    final storage = SharedStorageService.instance;
    final currentFormat = storage.getDownloadFormat();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '下载音质',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                currentFormat == 'mp3' ? 'MP3 格式（跨平台兼容）' : '默认格式（M4A，零转换）',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Switch(
            value: currentFormat == 'mp3',
            onChanged: (isMp3) {
              storage.setDownloadFormat(isMp3 ? 'mp3' : 'm4a');
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: 将卡片插入 body 列表**

在 `build()` 方法中，`_buildDarkModeCard` 之后插入：

```dart
          const SizedBox(height: 16),
          _buildDownloadFormatCard(context),
```

完整上下文（`build()` 方法中）：
```dart
          _buildDarkModeCard(context, themeMode: themeMode),
          const SizedBox(height: 16),
          _buildDownloadFormatCard(context),
          const SizedBox(height: 16),
```

- [ ] **Step 4: 运行静态分析验证**

```bash
cd frontend_flutter && flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add frontend_flutter/lib/presentation/views/system/settings_page.dart
git commit -m "feat: 设置页新增下载音频格式选择卡片"
```

---

### Task 3: 下载分流 — Repository 根据格式选择下载路径

**Files:**
- Modify: `frontend_flutter/lib/data/repositories/download_repository.dart`

- [ ] **Step 1: 添加 imports**

在现有 imports 顶部，`import '../../services/resumable_download_service.dart';` 之后添加：

```dart
import '../../core/storage/shared_storage_service.dart';
import '../../services/download_service.dart';
```

- [ ] **Step 2: 添加 `_downloadWithBackendService` 方法**

在 `_downloadWithBilibiliDownloader` 方法之后（第 465 行 `}` 之后），添加 MP3 下载路径：

```dart
  /// 使用 DownloadService 下载（后端 SSE，支持格式转换）
  Future<void> _downloadWithBackendService(
    int taskId,
    DownloadTask task,
    CancelToken cancelToken,
    String format,
  ) async {
    final service = DownloadService();

    await service.downloadAudio(
      bvid: task.bvid!,
      savePath: task.savePath,
      format: format,
      onProgress: (progress) {
        if (cancelToken.isCancelled) {
          throw TaskCanceledException();
        }

        _downloadTaskDao.updateProgressPercent(taskId, progress.percent);
        _downloadTaskDao.updateProgressTimestamp(taskId, DateTime.now());

        _progressController.add(DownloadProgressEvent(
          taskId: taskId,
          trackId: task.trackId,
          bvid: task.bvid!,
          progress: progress.percent,
          stage: progress.stage,
          message: progress.message,
        ));
      },
    ).then((result) {
      if (!result.success) {
        throw Exception(result.error ?? '下载失败');
      }
    });
  }
```

- [ ] **Step 3: 修��� `startDownload` 中的路由逻辑**

将第 249-256 行的分支逻辑：

```dart
      if (canResume) {
        AppLogger.info('DownloadRepository', '使用断点续传: 已下载 ${task.downloadedBytes} bytes');
        await _downloadWithResumable(taskId, task, cancelToken);
      } else {
        await _downloadWithBilibiliDownloader(taskId, task, cancelToken);
      }
```

替换为：

```dart
      final downloadFormat = SharedStorageService.instance.getDownloadFormat();

      if (canResume) {
        AppLogger.info('DownloadRepository', '使用断点续传: 已下载 ${task.downloadedBytes} bytes');
        await _downloadWithResumable(taskId, task, cancelToken);
      } else if (downloadFormat == 'mp3') {
        AppLogger.info('DownloadRepository', '使用后端 SSE 下载: format=$downloadFormat');
        await _downloadWithBackendService(taskId, task, cancelToken, downloadFormat);
      } else {
        AppLogger.info('DownloadRepository', '使用 BilibiliDownloader 下载: format=$downloadFormat');
        await _downloadWithBilibiliDownloader(taskId, task, cancelToken);
      }
```

- [ ] **Step 4: 运行静态分析验证**

```bash
cd frontend_flutter && flutter analyze
```

- [ ] **Step 5: 运行现有测试确保不回归**

```bash
cd frontend_flutter && flutter test
```

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/data/repositories/download_repository.dart
git commit -m "feat: 下载仓库根据全局格式设置分流下载路径"
```

---

## 验证清单

- [ ] 设置页切换格式后，SharedPreferences 中 `download_format` 值正确变更
- [ ] 设置 m4a 后触发下载，输出 `.m4a` 文件，走 BilibiliDownloader 路径
- [ ] 设置 mp3 后触发下载，输出 `.mp3` 文件，走 DownloadService + 后端 SSE 路径
- [ ] 切换格式不影响进行中的下载任务（每个任务创建时读取一次格式）
- [ ] 应用重启后格式设置持久化，保持用户上次选择
- [ ] `flutter analyze` 无新增警告
- [ ] `flutter test` 全部通过
