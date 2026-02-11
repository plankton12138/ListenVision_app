# 本地音乐扫描跨平台实现方案

## 部署目标

| 平台 | 需求 | 实现方式 |
|------|------|----------|
| **Android** | 完整支持 | `on_audio_query` 访问 MediaStore |
| **Windows** | 完整支持 | `dart:io` 文件系统扫描 + `metadata_god` 读取元数据 |
| **Web** | 测试功能 | 禁用本地扫描（浏览器限制） |

## 当前问题

`on_audio_query` 插件仅支持移动端（Android/iOS），在 Windows 上初始化时崩溃：
```
MissingPluginException(No implementation found for method setLogConfig)
```

## 解决方案：平台抽象层

创建平台接口抽象，不同平台使用不同实现：

```
MediaScannerService (统一接口)
    ├── _AndroidMediaScanner (on_audio_query)
    ├── _WindowsMediaScanner (dart:io + metadata_god)
    └── _WebMediaScanner (空实现/报错提示)
```

## 实施步骤

### 1. 创建平台接口

**文件**: `frontend_flutter/lib/services/media_scanner_service.dart`

```dart
abstract class MediaScannerPlatform {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
    void Function(int current, int total, String fileName)? onProgress,
  });
  void dispose();
}
```

### 2. 实现 Android 扫描器

**文件**: `frontend_flutter/lib/services/platform/android_media_scanner.dart`

- 复用现有 `OnAudioQuery` 逻辑
- 已有代码迁移到此类

### 3. 实现 Windows 扫描器

**文件**: `frontend_flutter/lib/services/platform/windows_media_scanner.dart`

- 使用 `dart:io` 的 `Directory` 递归扫描音频文件
- 使用已有的 `metadata_god` 包读取音频元数据（已在 pubspec.yaml）
- 支持用户选择扫描目录（可选）
- 常见音频格式: `.mp3`, `.flac`, `.wav`, `.m4a`, `.ogg`, `.wma`

### 4. 实现 Web 扫描器（空实现）

**文件**: `frontend_flutter/lib/services/platform/web_media_scanner.dart`

- 返回空结果或显示"此功能不支持网页版"提示

### 5. 修改 MediaScannerService

**文件**: `frontend_flutter/lib/services/media_scanner_service.dart`

```dart
class MediaScannerService {
  late final MediaScannerPlatform _scanner;

  MediaScannerService({LocalMusicRepository? repository}) {
    if (Platform.isAndroid) {
      _scanner = AndroidMediaScanner(repository);
    } else if (Platform.isWindows) {
      _scanner = WindowsMediaScanner(repository);
    } else {
      _scanner = WebMediaScanner(); // kIsWeb 或其他平台
    }
  }

  // 委托调用
  Future<bool> hasPermission() => _scanner.hasPermission();
  // ... 其他方法同理
}
```

## 修改文件清单

| 文件 | 操作 |
|------|------|
| `lib/services/media_scanner_service.dart` | 重构为接口+工厂模式 |
| `lib/services/platform/android_media_scanner.dart` | 新建（迁移现有逻辑） |
| `lib/services/platform/windows_media_scanner.dart` | 新建（文件系统扫描） |
| `lib/services/platform/web_media_scanner.dart` | 新建（空实现） |

## Windows 实现细节

### 已确认：metadata_god 支持 Windows

根据 pub.dev 文档：
> "Linux, Windows and MacOS doesn't need any extra configuration and good to go after installation"

### 扫描目录

参考现有下载功能实现（`audio_action_menu.dart:_getDownloadDirectory`）：

**主要目录**：
- `C:\Users\<用户>\Downloads\ListenVision\` - 应用下载目录（首选）
- `C:\Users\<用户>\Music\` - 系统音乐文件夹

**备用目录**（可选）：
- `D:\Music\`（如果存在）
- 用户自定义目录

**实现方式**：复用 `path_provider` 包的 `getDownloadsDirectory()`

### 音频格式支持

metadata_god 支持的格式：
| 格式 | 元数据格式 |
|------|-----------|
| mp3 | id3v2.4 |
| m4a, mp4 | MPEG-4 audio metadata |
| flac | Vorbis comment |

```dart
const supportedExtensions = ['.mp3', '.flac', '.m4a', '.mp4', '.wav', '.ogg'];
```

### 元数据读取

使用已有的 `metadata_god` 包（已在 pubspec.yaml ^0.5.0+1）：
```dart
// 需要先初始化
await MetadataGod.initialize();

// 读取元数据
Metadata metadata = await MetadataGod.readMetadata(filePath);
```

**注意**: metadata_god 需要 Rust 工具链，确保开发环境已安装 rustup。

## UI 考虑

Windows 平台可能需要：
1. 目录选择器（让用户选择扫描路径）
2. 扫描配置（是否包含子目录、文件类型过滤等）

## 补充说明

### 1. 性能优化

**并发控制**：
```dart
final _scanPool = Pool(4); // 同时处理4个文件
```

**扫描取消机制**：
```dart
class ScanCancelToken {
  bool _isCancelled = false;
  void cancel() => _isCancelled = true;
}
```

**增量扫描**：记录上次扫描时间，只处理新增/修改的文件（基于文件修改时间）

### 2. Web 平台判断修复

```dart
MediaScannerService() {
  if (kIsWeb) {
    _scanner = WebMediaScanner();
  } else if (Platform.isAndroid) {
    _scanner = AndroidMediaScanner(repository);
  } else if (Platform.isWindows) {
    _scanner = WindowsMediaScanner(repository);
  }
}
```

### 3. 权限模型统一

| 平台 | `hasPermission()` | `requestPermission()` |
|------|-------------------|----------------------|
| Android | 检查运行时权限 | 请求权限弹窗 |
| Windows | 始终返回 `true` | 空操作，返回 `true` |
| Web | 始终返回 `false` | 空操作，返回 `false` |

### 4. 元数据模型统一

**统一模型**: `lib/models/audio_metadata.dart`

```dart
@freezed
class AudioMetadata with _$AudioMetadata {
  const factory AudioMetadata({
    required String filePath,
    required String title,
    String? artist,
    String? album,
    String? albumArt,
    Duration? duration,
    int? trackNumber,
    int? year,
  }) = _AudioMetadata;
}
```

各平台实现负责将原生格式转换为统一模型：
- `AndroidMediaScanner`: `OnAudioQuery` → `AudioMetadata`
- `WindowsMediaScanner`: `MetadataGod.readMetadata()` → `AudioMetadata`

### 5. 错误处理策略

- **单个文件元数据读取失败**：记录日志，跳过该文件，继续扫描
- **目录访问失败**：记录日志，跳过该目录
- **用户取消扫描**：保存已扫描结果，不回滚

```dart
try {
  final metadata = await MetadataGod.readMetadata(filePath);
} catch (e) {
  AppLogger.warn('Failed to read metadata: $filePath', error: e);
  continue; // 跳过继续下一个
}
```

### 6. metadata_god 初始化

在 `WindowsMediaScanner` 构造时初始化：

```dart
class WindowsMediaScanner implements MediaScannerPlatform {
  static bool _initialized = false;

  WindowsMediaScanner() {
    _init();
  }

  Future<void> _init() async {
    if (!_initialized) {
      await MetadataGod.initialize();
      _initialized = true;
    }
  }
}
```

### 7. 扫描进度持久化

支持中断恢复，保存扫描状态到本地：

```dart
class ScanProgress {
  final List<String> scannedPaths;
  final String? lastPath;
  final DateTime timestamp;
}
```

下次扫描时可选"继续上次扫描"
