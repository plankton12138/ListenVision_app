# 迁移 audioplayers → media_kit 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将音频播放层从 `audioplayers` 迁移到 `media_kit`，解决 B站CDN 403 和 Windows 线程Bug 问题

**Architecture:** 重写 `AudioPlayerService` 封装层，对外接口（`AudioPlaybackState` 枚举、错误分类、流式API）保持不变，内部实现从 `audioplayers` 的 `AudioPlayer` 替换为 `media_kit` 的 `Player`。B站在播放在线URL时通过 `Media(httpHeaders:)` 传入 Referer 和 User-Agent 请求头。

**Tech Stack:** media_kit ^1.2.6, media_kit_libs_audio ^1.0.7（仅音频，不含视频），media_kit 不需要 video 相关包

---

## 文件结构

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 修改 | `pubspec.yaml` | 移除 audioplayers，添加 media_kit 依赖 |
| 重写 | `lib/services/audio_player_service.dart` | 核心改动：用 media_kit Player 替换 audioplayers AudioPlayer |
| 修改 | `lib/main.dart` | 添加 `MediaKit.ensureInitialized()` |
| 修改 | `lib/presentation/viewmodels/player/playback_viewmodel.dart` | 在线播放时传入 B站请求头 |
| 修改 | `lib/models/online_playable.dart` | 新增 `httpHeaders` 属性 |
| 重新生成 | `lib/presentation/viewmodels/player/playback_viewmodel.g.dart` | Riverpod 代码生成 |
| 修改 | `lib/services/bilibili_downloader.dart` | 注释中更新迁移说明（无功能改动） |

---

## 任务 1: 更新 pubspec.yaml 依赖

**文件:**
- 修改: `pubspec.yaml`

- [ ] **步骤 1: 编辑 pubspec.yaml，移除 audioplayers 依赖，添加 media_kit 依赖**

在 `pubspec.yaml` 中：
- 移除 `audioplayers: ^6.4.0` 和 `audio_session: ^0.2.1`
- 添加 `media_kit: ^1.2.6` 和 `media_kit_libs_audio: ^1.0.7`
- 更新注释说明迁移原因

```yaml
# P0: 音频播放 - 从 audioplayers 迁移到 media_kit（2026-05-20）
# 原因：audioplayers Windows 平台无法设置自定义 HTTP 请求头，B站CDN返回403
# media_kit 支持自定义 httpHeaders，底层使用 libmpv，Windows 线程安全
media_kit: ^1.2.6
media_kit_libs_audio: ^1.0.7
```

- [ ] **步骤 2: 运行 flutter pub get**

```bash
cd frontend_flutter && flutter pub get
```

预期：依赖解析成功

- [ ] **步骤 3: 提交依赖变更**

```bash
git add frontend_flutter/pubspec.yaml frontend_flutter/pubspec.lock
git commit -m "chore(deps): migrate audioplayers to media_kit for HTTP headers support / 迁移到 media_kit 支持 B站请求头"
```

---

## 任务 2: 重写 AudioPlayerService

**文件:**
- 重写: `lib/services/audio_player_service.dart`

这是最核心的改动。需要保持对外接口完全兼容，仅替换内部实现。

- [ ] **步骤 1: 重写 audio_player_service.dart**

关键变更点：
1. 导入从 `audioplayers` 改为 `media_kit`
2. 私有字段从 `AudioPlayer _player` 改为 `Player _player`（media_kit 的 Player）
3. `AudioPlaybackState` 枚举值映射到 media_kit 的 `Player.state` 状态
4. 流式API：`positionStream` → `_player.stream.position`，`durationStream` → `_player.stream.duration`
5. 播放控制：`_player.play()`、`_player.pause()`、`_player.stop()`、`_player.seek()`
6. **关键**：`playUrl` 和 `setUrlSource` 对于在线URL需要支持 `httpHeaders` 参数
7. 音量范围从 0.0-1.0 映射到 media_kit 的 0.0-100.0
8. 倍速和音量设置方法保持兼容
9. 初始化时不再需要创建 `AudioPlayer()`，改为 `Player()`
10. `dispose()` 方法调用 `_player.dispose()`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import '../core/utils/app_logger.dart';

/// 播放状态枚举（抽象层，不依赖具体库实现）
enum AudioPlaybackState {
  playing,
  paused,
  stopped,
  completed,
  idle,
}

/// 音频播放错误类型
enum AudioPlayerErrorType {
  sourceLoadFailed,
  networkError,
  fileNotFound,
  formatNotSupported,
  platformError,
  unknown,
}

AudioPlayerErrorType classifyError(dynamic error) {
  final errorString = error.toString().toLowerCase();
  if (errorString.contains('platformerror') ||
      errorString.contains('platform') ||
      errorString.contains('media_kit') ||
      errorString.contains('mpv')) {
    return AudioPlayerErrorType.platformError;
  }
  if (errorString.contains('network') ||
      errorString.contains('socket') ||
      errorString.contains('timeout') ||
      errorString.contains('connection') ||
      errorString.contains('403') ||
      errorString.contains('404')) {
    return AudioPlayerErrorType.networkError;
  }
  if (errorString.contains('file not found') ||
      errorString.contains('enoent') ||
      errorString.contains('could not find') ||
      errorString.contains('no such file')) {
    return AudioPlayerErrorType.fileNotFound;
  }
  if (errorString.contains('format') ||
      errorString.contains('unsupported') ||
      errorString.contains('invalid audio') ||
      errorString.contains('no audio')) {
    return AudioPlayerErrorType.formatNotSupported;
  }
  if (errorString.contains('source') ||
      errorString.contains('load failed') ||
      errorString.contains('failed to load') ||
      errorString.contains('failed to open')) {
    return AudioPlayerErrorType.sourceLoadFailed;
  }
  return AudioPlayerErrorType.unknown;
}

String getUserFriendlyMessage(AudioPlayerErrorType type) {
  return switch (type) {
    AudioPlayerErrorType.sourceLoadFailed => '音频源加载失败，请重试',
    AudioPlayerErrorType.networkError => '网络连接失败，请检查网络',
    AudioPlayerErrorType.fileNotFound => '音频文件不存在或已被删除',
    AudioPlayerErrorType.formatNotSupported => '音频格式不支持',
    AudioPlayerErrorType.platformError => '播放器初始化失败，请重启应用',
    AudioPlayerErrorType.unknown => '播放失败，请重试',
  };
}

/// 音频播放服务
///
/// 封装 media_kit 的 Player 功能，提供统一的播放控制接口。
/// 对外接口与 audioplayers 版本完全兼容。
///
/// 职责：
/// - 播放控制（play/pause/stop/seek）
/// - 音频源管理（本地文件/在线URL + 自定义HTTP请求头）
/// - 播放状态流（position/duration/playerState）
/// - 播放设置（volume/playbackRate）
class AudioPlayerService {
  final Player _player;
  bool _disposed = false;
  String? _currentSourceUrl;
  final List<StreamSubscription> _subscriptions = [];
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;
  bool _isCompleted = false;

  AudioPlayerService({Player? player}) : _player = player ?? Player() {
    _initStreams();
    AppLogger.debug('AudioPlayerService', '服务已创建');
  }

  void _initStreams() {
    _subscriptions.add(
      _player.stream.position.listen((position) {
        _currentPosition = position;
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((duration) {
        _currentDuration = duration;
      }),
    );
    _subscriptions.add(
      _player.stream.completed.listen((completed) {
        _isCompleted = completed;
      }),
    );
  }

  Player get player => _player;
  bool get disposed => _disposed;
  Duration get position => _currentPosition;
  Duration? get duration => _currentDuration;

  bool get isPlaying => _player.state.playing;
  bool get isPaused => !_player.state.playing && _currentSourceUrl != null && !_isCompleted;
  bool get isStopped => _currentSourceUrl == null;
  bool get isCompleted => _isCompleted;
  bool get isIdle => _currentSourceUrl == null;
  bool get isLoading =>
      _currentSourceUrl != null &&
      (_currentDuration == null || _currentDuration == Duration.zero) &&
      !isPlaying &&
      _currentPosition == Duration.zero;
  bool get isReady => _currentSourceUrl != null && (_currentDuration ?? Duration.zero) > Duration.zero;

  // ==================== 播放控制 ====================

  Future<void> play() async {
    if (_disposed) return;
    if (_currentSourceUrl == null) {
      AppLogger.warn('AudioPlayerService', 'play() 调用失败：未加载音频源');
      throw Exception('未加载音频源，请先调用 setSource 或 playFile/playUrl');
    }
    AppLogger.debug('AudioPlayerService', 'play()');
    await _player.play();
  }

  Future<void> pause() async {
    if (_disposed) return;
    AppLogger.debug('AudioPlayerService', 'pause()');
    await _player.pause();
  }

  Future<void> stop() async {
    if (_disposed) return;
    AppLogger.debug('AudioPlayerService', 'stop()');
    await _player.stop();
    _currentSourceUrl = null;
    _isCompleted = false;
  }

  Future<void> togglePlayPause() async {
    if (_disposed) return;
    await _player.playOrPause();
  }

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    AppLogger.debug('AudioPlayerService', 'seek(${position.inSeconds}秒)');
    await _player.seek(position);
  }

  // ==================== 音频源管理 ====================

  Source _buildLocalSource(String pathOrUrl) {
    if (kIsWeb ||
        pathOrUrl.startsWith('blob:') ||
        pathOrUrl.startsWith('http://') ||
        pathOrUrl.startsWith('https://')) {
      return UrlSource(pathOrUrl);
    }
    return DeviceFileSource(pathOrUrl);
  }

  Future<void> setSource(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置本地音频源: $filePath');
    final source = _buildLocalSource(filePath);
    if (source is UrlSource) {
      await _player.open(Media(source.url));
    } else {
      await _player.open(Media(source.path));
    }
    _currentSourceUrl = filePath;
    _isCompleted = false;
  }

  Future<void> setUrlSource(String url, {Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    if (url.isEmpty) {
      AppLogger.warn('AudioPlayerService', 'setUrlSource() 失败：URL 为空');
      throw Exception('在线音频 URL 为空，请刷新后重试');
    }
    AppLogger.info('AudioPlayerService', '设置在线音频源: $url');
    final media = httpHeaders != null && httpHeaders.isNotEmpty
        ? Media(url, httpHeaders: httpHeaders)
        : Media(url);
    await _player.open(media);
    _currentSourceUrl = url;
    _isCompleted = false;
  }

  Future<void> playFile(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放本地文件: $filePath');
    final source = _buildLocalSource(filePath);
    if (source is UrlSource) {
      await _player.open(Media(source.url));
    } else {
      await _player.open(Media(source.path));
    }
    _currentSourceUrl = filePath;
    _isCompleted = false;
  }

  Future<void> playUrl(String url, {int maxRetries = 2, Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    if (url.isEmpty) {
      AppLogger.warn('AudioPlayerService', 'playUrl() 失败：URL 为空');
      throw Exception('在线音频 URL 为空，请刷新后重试');
    }

    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        AppLogger.info('AudioPlayerService', '播放在线URL (尝试 ${attempt + 1}): $url');
        final media = httpHeaders != null && httpHeaders.isNotEmpty
            ? Media(url, httpHeaders: httpHeaders)
            : Media(url);
        await _player.open(media);
        _currentSourceUrl = url;
        _isCompleted = false;
        return;
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) {
          AppLogger.error('AudioPlayerService', '播放失败，已重试 $maxRetries 次: $e');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        AppLogger.warn('AudioPlayerService', '播放失败，准备重试 ($attempt/$maxRetries): $e');
      }
    }
  }

  Future<void> playAsset(String path) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '播放Asset: $path');
    // media_kit 不直接支持 asset，使用 asset 绝对路径
    // 实际项目中此方法很少使用，如果不支持可以抛异常
    throw UnimplementedError('media_kit 不支持 Asset 播放，请使用本地文件或在线URL');
  }

  Future<void> setSourceAndPlayFile(String filePath) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置并播放本地文件: $filePath');
    final source = _buildLocalSource(filePath);
    if (source is UrlSource) {
      await _player.open(Media(source.url));
    } else {
      await _player.open(Media(source.path));
    }
    _currentSourceUrl = filePath;
    _isCompleted = false;
  }

  Future<void> setSourceAndPlayUrl(String url, {Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '设置并播放在线URL: $url');
    final media = httpHeaders != null && httpHeaders.isNotEmpty
        ? Media(url, httpHeaders: httpHeaders)
        : Media(url);
    await _player.open(media);
    _currentSourceUrl = url;
    _isCompleted = false;
  }

  Future<void> prepareSource(String url, {bool isOnline = false, Map<String, String>? httpHeaders}) async {
    if (_disposed) return;
    AppLogger.info('AudioPlayerService', '准备音频源: $url (在线:$isOnline)');
    if (isOnline) {
      final media = httpHeaders != null && httpHeaders.isNotEmpty
          ? Media(url, httpHeaders: httpHeaders)
          : Media(url);
      await _player.open(media, play: false);
    } else {
      final source = _buildLocalSource(url);
      if (source is UrlSource) {
        await _player.open(Media(source.url), play: false);
      } else {
        await _player.open(Media(source.path), play: false);
      }
    }
    _currentSourceUrl = url;
    _isCompleted = false;
  }

  // ==================== 播放设置 ====================

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    // media_kit 音量范围 0.0 - 100.0
    await _player.setVolume(clampedVolume * 100.0);
    AppLogger.debug('AudioPlayerService', '音量设置为: ${(clampedVolume * 100).toInt()}%');
  }

  Future<double> getVolume() async {
    if (_disposed) return 1.0;
    return _player.state.volume / 100.0;
  }

  Future<void> setPlaybackRate(double rate) async {
    if (_disposed) return;
    final clampedRate = rate.clamp(0.5, 2.0);
    await _player.setRate(clampedRate);
    AppLogger.debug('AudioPlayerService', '倍速设置为: $clampedRate');
  }

  Future<double> getPlaybackRate() async {
    if (_disposed) return 1.0;
    return _player.state.rate;
  }

  Future<void> release() async {
    if (_disposed) return;
    await _player.stop();
    _currentSourceUrl = null;
    _isCompleted = false;
    AppLogger.debug('AudioPlayerService', '资源已释放');
  }

  // ==================== 状态流 ====================

  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration?> get durationStream => _player.stream.duration;
  Stream<AudioPlaybackState> get playbackStateStream =>
      _player.stream.playing.map((playing) {
        if (playing) return AudioPlaybackState.playing;
        if (_isCompleted) return AudioPlaybackState.completed;
        if (_currentSourceUrl == null) return AudioPlaybackState.idle;
        return AudioPlaybackState.paused;
      });
  Stream<void> get onPlayerComplete => _player.stream.completed.where((c) => c);

  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
    AppLogger.debug('AudioPlayerService', '服务已释放');
  }
}

/// 音频源类型标记类（保持接口兼容）
class Source {
  final String path;
  Source(this.path);
}

class UrlSource extends Source {
  String get url => path;
  UrlSource(String url) : super(url);
}

class DeviceFileSource extends Source {
  String get path => super.path;
  DeviceFileSource(String path) : super(path);
}
```

**关键设计决策：**
- `AudioPlaybackState` 枚举和错误分类函数保持完全不变，确保 ViewModel 层零改动
- `playUrl` 和 `setUrlSource` 新增可选 `httpHeaders` 参数，用于传入 B站请求头
- `Source`/`UrlSource`/`DeviceFileSource` 类保留为简化标记类，仅用于 `_buildLocalSource` 判断
- 音量从 0.0-1.0 映射到 media_kit 的 0.0-100.0
- `playAsset` 不再支持（media_kit 不支持 asset 播放），抛出 `UnimplementedError`
- `playbackStateStream` 从 `_player.stream.playing` 和 `_isCompleted` 状态派生
- `onPlayerComplete` 使用 `_player.stream.completed.where((c) => c)` 过滤

- [ ] **步骤 2: 保存文件**

---

## 任务 3: 初始化 MediaKit

**文件:**
- 修改: `lib/main.dart`

- [ ] **步骤 1: 在 main() 中添加 MediaKit.ensureInitialized()**

在 `main()` 函数中，`WidgetsFlutterBinding.ensureInitialized()` 之后添加：

```dart
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();  // 新增：media_kit 初始化
  // ... 其余代码不变
}
```

- [ ] **步骤 2: 提交**

```bash
git add lib/main.dart
git commit -m "feat(audio): add MediaKit initialization in main.dart / 在 main 中初始化 media_kit"
```

---

## 任务 4: 在线播放传入 B站请求头

**文件:**
- 修改: `lib/presentation/viewmodels/player/playback_viewmodel.dart`
- 修改: `lib/models/online_playable.dart`

- [ ] **步骤 1: 修改 OnlinePlayable，添加 httpHeaders 属性**

在 `OnlinePlayable` 中：

```dart
class OnlinePlayable extends PlayableAudio {
  final Audio _audio;
  final String? _proxyUrl;
  final Map<String, String>? httpHeaders; // 新增：自定义HTTP请求头

  OnlinePlayable(this._audio, [this._proxyUrl, this.httpHeaders]);

  // ... 其他不变，以下构造函数需要更新：
  
  factory OnlinePlayable.withProxyUrl(Audio audio) {
    return OnlinePlayable(audio);
  }

  factory OnlinePlayable.fromAudio(Audio audio, String? proxyUrl) {
    return OnlinePlayable(audio, proxyUrl);
  }

  factory OnlinePlayable.fromMap(Map<String, dynamic> map) {
    final audio = Audio.fromDto(map);
    return OnlinePlayable(audio);
  }
  
  // ... 以下不变
}
```

- [ ] **步骤 2: 修改 PlaybackViewModel._playOnline，传入 B站请求头**

在 `_playOnline` 方法中：

```dart
import '../../../services/bilibili_headers.dart'; // 添加导入

Future<void> _playOnline(OnlinePlayable playable) async {
  final url = await _resolveOnlineStreamUrl(playable);
  AppLogger.debug('PlaybackViewModel', '播放在线URL: $url');
  // 使用 B站请求头，解决 CDN 403 问题
  final headers = playable.httpHeaders ?? bilibiliHeaders;
  await _audioService!.playUrl(url, httpHeaders: headers);

  // 加载字幕
  ref.read(subtitleViewModelProvider.notifier).loadSubtitle(
        playable.original.id,
        cid: playable.original.cid,
      );
}
```

同样修改 `prepareSource` 方法：

```dart
Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
  if (_disposed) return;

  AppLogger.info('PlaybackViewModel', '准备音频源: ${playable.title}');
  _updatePlayableState(playable);
  state = state.copyWith(isLoading: true);

  try {
    if (playable.isOnline && playable is OnlinePlayable) {
      final resolvedUrl = await _resolveOnlineStreamUrl(playable);
      final headers = playable.httpHeaders ?? bilibiliHeaders;
      await _audioService!.setUrlSource(resolvedUrl, httpHeaders: headers);
      // 加载字幕
      ref.read(subtitleViewModelProvider.notifier).loadSubtitle(
            playable.original.id,
            cid: playable.original.cid,
            initialPosition: Duration(seconds: startPosition),
          );
    } else if (playable is LocalPlayable) {
      await _audioService!.setSource(playable.url);
      ref.read(subtitleViewModelProvider.notifier).clear();
    }

    if (startPosition > 0) {
      await _audioService!.seek(Duration(seconds: startPosition));
    }

    state = state.copyWith(isLoading: false);
    AppLogger.info('PlaybackViewModel', '音频源准备完成');
    _validateState();
  } catch (e) {
    AppLogger.error('PlaybackViewModel', '准备音频源失败: $e');
    state = state.copyWith(
      isLoading: false,
      errorMessage: '加载失败',
    );
    rethrow;
  }
}
```

- [ ] **步骤 3: 提交**

```bash
git add lib/services/audio_player_service.dart lib/main.dart lib/presentation/viewmodels/player/playback_viewmodel.dart lib/models/online_playable.dart
git commit -m "feat(audio): rewrite AudioPlayerService with media_kit and add Bilibili HTTP headers / 重写 AudioPlayerService 使用 media_kit，添加 B站请求头支持"
```

---

## 任务 5: 重新生成 Riverpod 代码

- [ ] **步骤 1: 运行 build_runner**

```bash
cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **步骤 2: 验证生成文件无编译错误**

检查 `playback_viewmodel.g.dart` 是否仍可用，确认 `audioPlayerServiceProvider` 正常生成。

- [ ] **步骤 3: 提交**

```bash
git add lib/presentation/viewmodels/player/playback_viewmodel.g.dart
git commit -m "chore: regenerate Riverpod providers / 重新生成 Riverpod 代码"
```

---

## 任务 6: 清理 audioplayers 残留引用和测试

**文件:**
- 搜索所有引用 audioplayers 的文件并清理

- [ ] **步骤 1: 搜索所有 audioplayers 引用**

```bash
cd frontend_flutter && rg "audioplayers" --type dart -l
```

确保：
- `pubspec.yaml` 中已移除 audioplayers
- 所有 `.dart` 文件中不再有 `import 'package:audioplayers` 导入
- `audio_player_service.dart` 使用 `import 'package:media_kit/media_kit.dart'`

- [ ] **步骤 2: 搜索所有 AudioPlayer 引用（非 AudioPlayerService）**

```bash
cd frontend_flutter && rg "AudioPlayer\b" --type dart -l
```

确保没有直接使用 audioplayers 的 `AudioPlayer` 类的地方。

- [ ] **步骤 3: 运行 flutter analyze**

```bash
cd frontend_flutter && flutter analyze
```

预期：无编译错误。

- [ ] **步骤 4: 运行现有测试**

```bash
cd frontend_flutter && flutter test
```

- [ ] **步骤 5: 提交所有清理变更**

```bash
git add -A
git commit -m "chore: clean up audioplayers references / 清理 audioplayers 残留引用"
```

---

## 任务 7: Windows 桌面构建验证

- [ ] **步骤 1: 运行 flutter run -d windows**

```bash
cd frontend_flutter && flutter run -d windows
```

预期：
- 应用正常启动
- 无 `non-platform thread` 错误
- 播放在线B站音频时，不再出现 `WindowsAudioError: Failed to set source` 错误
- 日志中应显示 B站请求头被传入

- [ ] **步骤 2: 如果构建失败，排查并修复**

常见问题：
1. CMake 缓存需要清理：`flutter clean` 后重新 `flutter pub get` 再构建
2. media_kit_libs_audio 需要下载 mpv native library，可能需要代理

- [ ] **步骤 3: 确认最终提交**

```bash
git log --oneline -5
```

---

## 关键注意事项

1. **media_kit 音量范围是 0.0-100.0**，不是 0.0-1.0，需要映射
2. **media_kit 的 Player() 在 dispose 后不可重用**，确保 `_disposed` 检查正确
3. **media_kit 支持的 Media 构造**：`Media(uri)` 和 `Media(uri, httpHeaders: {'Referer': '...', 'User-Agent': '...'})`
4. **B站 CDN 要求请求头**：`Referer: https://www.bilibili.com/` 和 `User-Agent` 在 `bilibili_headers.dart` 中定义
5. **playAsset 不再支持**：media_kit 不支持 Flutter asset 播放。如果应用中没有使用 asset 音频则无影响
6. **media_kit_libs_audio 包含 mpv native library**，会增加约 5-10MB 的包体积
7. **不要混用 media_kit_libs_video 和 media_kit_libs_audio**，它们是互斥的