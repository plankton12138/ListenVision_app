# 音频播放优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 解决 B站音频播放延迟（10秒）和状态不同步问题

**Architecture:**
1. 后端：将完整下载代理改为真正的流式代理，边下载边转发，支持 Range 请求
2. 前端：合并 PlayerViewModel 和 QueueViewModel 的播放逻辑为 PlaybackViewModel，建立单向数据流

**Tech Stack:** Python FastAPI (后端), Dart Riverpod 3.0 (前端)

---

## 文件结构

### 后端修改

| 文件 | 操作 | 职责 |
|------|------|------|
| `listen-vision-api-python/app/api/routes/bilibili.py` | 修改 | 流式代理端点 |
| `listen-vision-api-python/app/services/bilibili_service.py` | 修改 | 流式代理方法 |
| `listen-vision-api-python/tests/test_bilibili_proxy.py` | 修改 | 流式代理测试 |

### 前端重构

| 文件 | 操作 | 职责 |
|------|------|------|
| `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart` | 新建 | 核心播放状态管理 |
| `frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart` | 修改 | 简化为纯队列数据管理 |
| `frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart` | 删除 | 功能合并到 PlaybackViewModel |
| `frontend_flutter/lib/presentation/providers.dart` | 修改 | 更新导出 |

**以下文件需要将 playerViewModelProvider 替换为 playbackViewModelProvider：**

| 文件 | 操作 |
|------|------|
| `frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart` | 修改 |
| `frontend_flutter/lib/presentation/widgets/volume_slider.dart` | 修改 |
| `frontend_flutter/lib/presentation/widgets/speed_button.dart` | 修改 |
| `frontend_flutter/lib/presentation/widgets/player_action_bar.dart` | 修改 |
| `frontend_flutter/lib/presentation/widgets/controls_panel.dart` | 修改 |
| `frontend_flutter/lib/presentation/widgets/audio_info.dart` | 修改 |
| `frontend_flutter/lib/presentation/views/player/home_page.dart` | 修改 |
| `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart` | 修改 |
| `frontend_flutter/lib/presentation/views/discovery/explore_page.dart` | 修改 |
| `frontend_flutter/lib/presentation/views/discovery/search_page.dart` | 修改 |
| `frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart` | 修改 |

**测试文件：**

| 文件 | 操作 |
|------|------|
| `frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart` | 新建 |

---

## Part 1: 后端流式代理

### Task 1.1: 实现流式代理方法

**Files:**
- Modify: `listen-vision-api-python/app/services/bilibili_service.py:288-335`

- [ ] **Step 1: 添加流式代理生成器方法**

在 `BilibiliService` 类中添加新的流式代理方法：

```python
@staticmethod
async def stream_audio_proxy(
    bvid: str,
    credential: Optional[Credential] = None,
    range_header: Optional[str] = None
) -> AsyncGenerator[bytes, None]:
    """
    流式代理音频，边从 B站下载边返回

    Args:
        bvid: 视频BV号
        credential: B站认证凭证（可选）
        range_header: Range请求头（可选）

    Yields:
        音频数据块
    """
    streams = await BilibiliService.get_audio_streams(bvid, credential)
    if not streams.streams:
        raise ValueError("无可用音频流")

    stream = streams.streams[0]
    url = stream.url

    headers = BILIBILI_HEADERS.copy()
    if range_header:
        headers["Range"] = range_header

    async with httpx.AsyncClient(timeout=60.0) as client:
        async with client.stream("GET", url, headers=headers, follow_redirects=True) as response:
            response.raise_for_status()
            async for chunk in response.aiter_bytes(chunk_size=65536):  # 64KB chunks
                yield chunk
```

- [ ] **Step 2: 添加获取流信息的方法**

```python
@staticmethod
async def get_audio_stream_info(
    bvid: str,
    credential: Optional[Credential] = None
) -> Tuple[str, int, dict]:
    """
    获取音频流信息（URL、大小、请求头）

    Args:
        bvid: 视频BV号
        credential: B站认证凭证（可选）

    Returns:
        元组 (音频URL, 内容长度, 响应头字典)
    """
    streams = await BilibiliService.get_audio_streams(bvid, credential)
    if not streams.streams:
        raise ValueError("无可用音频流")

    stream = streams.streams[0]
    url = stream.url

    # 发送 HEAD 请求获取元信息
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.head(url, headers=BILIBILI_HEADERS, follow_redirects=True)
        content_length = int(response.headers.get("content-length", 0))
        content_type = response.headers.get("content-type", "audio/mp4")

        return url, content_length, {
            "content-type": content_type,
            "accept-ranges": "bytes",
        }
```

- [ ] **Step 3: 运行现有测试验证不破坏现有功能**

Run: `cd listen-vision-api-python && uv run pytest tests/test_bilibili_proxy.py -v`
Expected: 所有测试通过

- [ ] **Step 4: Commit**

```bash
git add listen-vision-api-python/app/services/bilibili_service.py
git commit -m "feat(bilibili): add streaming audio proxy methods"
```

---

### Task 1.2: 更新代理端点为流式响应 [depends on: Task 1.1]

**Files:**
- Modify: `listen-vision-api-python/app/api/routes/bilibili.py:138-183`

- [ ] **Step 1: 导入 StreamingResponse**

在文件顶部添加导入：

```python
from fastapi.responses import StreamingResponse
```

- [ ] **Step 2: 重写 proxy_audio 端点**

```python
@router.get("/proxy/audio/{bvid}")
async def proxy_audio(
    bvid: str,
    request: Request,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db)
):
    """
    流式代理音频，支持 Range 请求

    用于播放B站音频，边下载边返回，显著降低启动延迟。
    支持游客模式（无需登录）。
    """
    from app.utils.logger import logger

    range_header = request.headers.get("range")
    logger.info(f"流式音频代理: bvid={bvid}, range={range_header}")

    # 获取用户 B站凭证（如果已登录且已绑定）
    credential = None
    if current_user:
        auth_service = BilibiliAuthService(db)
        credential = await auth_service.get_credential(current_user.id)

    try:
        # 获取流信息
        url, content_length, headers = await BilibiliService.get_audio_stream_info(bvid, credential)

        # 构建响应头
        response_headers = {
            "Content-Type": headers["content-type"],
            "Accept-Ranges": "bytes",
            "Cache-Control": "public, max-age=3600",
        }

        # 处理 Range 请求
        if range_header:
            # 解析 Range 头
            start, end = _parse_range_header(range_header, content_length)
            if start >= content_length:
                return Response(status_code=416, headers={"Content-Range": f"bytes */{content_length}"})

            # 构建子范围请求头
            range_request_header = f"bytes={start}-{end}"
            response_headers["Content-Range"] = f"bytes {start}-{end}/{content_length}"
            response_headers["Content-Length"] = str(end - start + 1)

            logger.info(f"流式代理范围: {range_request_header}")

            return StreamingResponse(
                BilibiliService.stream_audio_proxy(bvid, credential, range_request_header),
                status_code=206,
                headers=response_headers,
                media_type=headers["content-type"]
            )
        else:
            response_headers["Content-Length"] = str(content_length)

            return StreamingResponse(
                BilibiliService.stream_audio_proxy(bvid, credential),
                headers=response_headers,
                media_type=headers["content-type"]
            )

    except Exception as e:
        logger.error(f"流式音频代理失败: bvid={bvid}, error={e}")
        raise HTTPException(status_code=500, detail=f"音频代理失败: {str(e)}")


def _parse_range_header(range_header: str, total_size: int) -> Tuple[int, int]:
    """
    解析 Range 请求头

    Args:
        range_header: Range 头值，如 "bytes=0-1023"
        total_size: 文件总大小

    Returns:
        元组 (start, end)
    """
    if not range_header.startswith("bytes="):
        return 0, total_size - 1

    range_spec = range_header[6:]  # 去掉 "bytes="
    if "-" not in range_spec:
        return 0, total_size - 1

    parts = range_spec.split("-")
    start = int(parts[0]) if parts[0] else 0
    end = int(parts[1]) if parts[1] else total_size - 1

    return start, min(end, total_size - 1)
```

- [ ] **Step 3: 添加必要的导入**

```python
from typing import Tuple
from fastapi import HTTPException
```

- [ ] **Step 4: 手动测试流式代理**

启动后端：
```bash
cd listen-vision-api-python && uv run uvicorn app.main:app
```

使用 curl 测试：
```bash
curl -v "http://127.0.0.1:8000/api/v1/bilibili/proxy/audio/BV1vsAwzREPP" --output test.mp4
```

Expected: 立即开始下载数据，而非等待完整下载

- [ ] **Step 5: Commit**

```bash
git add listen-vision-api-python/app/api/routes/bilibili.py
git commit -m "feat(bilibili): implement streaming audio proxy with Range support"
```

---

### Task 1.3: 添加流式代理测试 [depends on: Task 1.2]

**Files:**
- Modify: `listen-vision-api-python/tests/test_bilibili_proxy.py`

- [ ] **Step 1: 添加流式代理测试**

```python
@pytest.mark.asyncio
async def test_stream_audio_proxy():
    """测试流式音频代理"""
    bvid = "BV1vsAwzREPP"

    chunks = []
    async for chunk in BilibiliService.stream_audio_proxy(bvid):
        chunks.append(chunk)
        if len(chunks) >= 3:  # 只测试前几个块
            break

    assert len(chunks) > 0
    assert all(isinstance(chunk, bytes) for chunk in chunks)


@pytest.mark.asyncio
async def test_stream_audio_proxy_with_range():
    """测试带 Range 的流式代理"""
    bvid = "BV1vsAwzREPP"

    # 先获取流信息
    url, content_length, headers = await BilibiliService.get_audio_stream_info(bvid)
    assert content_length > 0

    # 请求前 1KB
    chunks = []
    async for chunk in BilibiliService.stream_audio_proxy(bvid, range_header="bytes=0-1023"):
        chunks.append(chunk)

    total_size = sum(len(chunk) for chunk in chunks)
    assert total_size == 1024  # 请求了 0-1023，共 1024 字节
```

- [ ] **Step 2: 运行测试**

Run: `cd listen-vision-api-python && uv run pytest tests/test_bilibili_proxy.py -v`
Expected: 所有测试通过

- [ ] **Step 3: Commit**

```bash
git add listen-vision-api-python/tests/test_bilibili_proxy.py
git commit -m "test(bilibili): add streaming proxy tests"
```

---

## Part 2: 前端架构重构

### Task 2.1: 创建 PlaybackViewModel

**Files:**
- Create: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart`

- [ ] **Step 1: 创建 PlaybackViewModel 核心结构**

```dart
import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/audio.dart';
import '../../../models/local_playable.dart';
import '../../../models/online_playable.dart';
import '../../../models/playable_audio.dart';
import '../../../models/play_mode.dart';
import '../../../services/audio_player_service.dart';
import '../auth/auth_viewmodel.dart' show isLoggedInProvider;
import '../library/history_viewmodel.dart';
import 'queue_viewmodel.dart';
import 'subtitle_viewmodel.dart';

part 'playback_viewmodel.freezed.dart';
part 'playback_viewmodel.g.dart';

/// 播放状态
@freezed
abstract class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    /// 当前可播放音频
    PlayableAudio? currentPlayable,

    /// 标题
    @Default('未知标题') String title,

    /// 艺术家
    @Default('未知艺术家') String artist,

    /// 封面 URL
    String? coverUrl,

    /// 是否正在播放
    @Default(false) bool isPlaying,

    /// 是否已暂停
    @Default(false) bool isPaused,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否已完成
    @Default(false) bool isCompleted,

    /// 当前播放位置
    @Default(Duration.zero) Duration position,

    /// 音频总时长
    Duration? duration,

    /// 音量
    @Default(1.0) double volume,

    /// 播放倍速
    @Default(1.0) double speed,

    /// 错误消息
    String? errorMessage,

    /// 当前播放索引
    @Default(-1) int currentIndex,
  }) = _PlaybackState;
}

/// 播放控制器 ViewModel
///
/// 职责：
/// 1. 统一管理播放状态（播放/暂停/加载/完成）
/// 2. 当前播放音频信息
/// 3. 播放控制（play/pause/stop/seek/next/previous）
/// 4. 音量和倍速设置
///
/// 依赖：
/// - AudioPlayerService: 底层播放器
/// - QueueViewModel: 队列数据（只读取，不修改）
@Riverpod(keepAlive: true)
class PlaybackViewModel extends _$PlaybackViewModel {
  AudioPlayerService? _audioService;
  SharedStorageService? _storage;
  Timer? _positionSaveTimer;
  bool _disposed = false;
  bool _isSwitchingSource = false;

  @override
  PlaybackState build() {
    _audioService = ref.watch(audioPlayerServiceProvider);
    _storage = ref.watch(sharedStorageServiceProvider);

    ref.onDispose(() {
      if (!_disposed) {
        _disposed = true;
        _positionSaveTimer?.cancel();
        _audioService?.dispose();
      }
    });

    Future.microtask(_init);

    return const PlaybackState();
  }

  Future<void> _init() async {
    await _audioService!.setVolume(state.volume);
    await _audioService!.setPlaybackRate(state.speed);
    _initListeners();
    AppLogger.info('PlaybackViewModel', '初始化完成');
  }

  void _initListeners() {
    // 位置变化监听
    _audioService!.positionStream.listen((position) {
      if (_disposed) return;
      state = state.copyWith(position: position);
      ref.read(subtitleViewModelProvider.notifier).updatePosition(position);
    });

    // 时长变化监听
    _audioService!.durationStream.listen((duration) {
      if (_disposed) return;
      state = state.copyWith(duration: duration);
    });

    // 播放状态监听
    _audioService!.playerStateStream.listen((playerState) {
      if (_disposed) return;
      _onPlayerStateChanged(playerState);
    });

    // 播放完成监听
    _audioService!.onPlayerComplete.listen((_) {
      if (_disposed) return;
      _onPlaybackComplete();
    });
  }

  void _onPlayerStateChanged(dynamic playerState) {
    final isPlaying = playerState.name == 'playing';
    final isPaused = playerState.name == 'paused';

    state = state.copyWith(
      isPlaying: isPlaying,
      isPaused: isPaused,
      isLoading: false,
    );
  }

  void _onPlaybackComplete() {
    AppLogger.info('PlaybackViewModel', '播放完成');
    _stopPositionSaveTimer();
    state = state.copyWith(isPlaying: false, isCompleted: true);
    _playNextAutomatically();
  }

  // ==================== 播放控制 ====================

  /// 播放指定音频
  Future<void> play(PlayableAudio playable, {int index = -1}) async {
    if (_disposed) return;

    AppLogger.info('PlaybackViewModel', '播放: ${playable.title}');

    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      artist: playable.artist ?? '未知艺术家',
      coverUrl: playable.coverUrl,
      currentIndex: index,
      isLoading: true,
      errorMessage: null,
    );

    try {
      if (playable.isOnline && playable is OnlinePlayable) {
        await _playOnline(playable);
      } else if (playable is LocalPlayable) {
        await _playLocal(playable);
      }

      state = state.copyWith(isLoading: false, isPlaying: true);
      _startPositionSaveTimer();
      _recordHistory(playable);
    } catch (e) {
      AppLogger.error('PlaybackViewModel', '播放失败: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '播放失败: $e',
      );
    }
  }

  Future<void> _playOnline(OnlinePlayable playable) async {
    final url = playable.url;
    AppLogger.debug('PlaybackViewModel', '播放在线URL: $url');
    await _audioService!.playUrl(url);

    // 加载字幕
    ref.read(subtitleViewModelProvider.notifier).loadSubtitle(
      playable.original.id,
      cid: playable.original.cid,
    );
  }

  Future<void> _playLocal(LocalPlayable playable) async {
    AppLogger.debug('PlaybackViewModel', '播放本地文件: ${playable.url}');
    await _audioService!.playFile(playable.url);
    ref.read(subtitleViewModelProvider.notifier).clear();
  }

  /// 暂停
  Future<void> pause() async {
    if (_disposed) return;
    await _audioService!.pause();
    _stopPositionSaveTimer();
    state = state.copyWith(isPlaying: false, isPaused: true);
    AppLogger.debug('PlaybackViewModel', '暂停');
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_disposed) return;
    await _audioService!.play();
    _startPositionSaveTimer();
    state = state.copyWith(isPlaying: true, isPaused: false);
    AppLogger.debug('PlaybackViewModel', '恢复播放');
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// 停止
  Future<void> stop() async {
    if (_disposed) return;
    await _audioService!.stop();
    _stopPositionSaveTimer();
    state = state.copyWith(
      isPlaying: false,
      isPaused: false,
      currentPlayable: null,
      currentIndex: -1,
    );
    AppLogger.debug('PlaybackViewModel', '停止');
  }

  /// 跳转
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _audioService!.seek(position);
    AppLogger.debug('PlaybackViewModel', '跳转到: ${position.inSeconds}秒');
  }

  /// 播放下一首
  Future<void> next() async {
    final queueState = ref.read(queueViewModelProvider);
    if (!queueState.hasNext) return;

    final nextIndex = queueState.currentIndex + 1;
    final nextPlayable = queueState.queue[nextIndex];

    // 更新队列索引
    ref.read(queueViewModelProvider.notifier).setCurrentIndex(nextIndex);

    await play(nextPlayable, index: nextIndex);
    AppLogger.info('PlaybackViewModel', '播放下一首: ${nextPlayable.title}');
  }

  /// 播放上一首
  Future<void> previous() async {
    final queueState = ref.read(queueViewModelProvider);
    if (!queueState.hasPrevious) return;

    final prevIndex = queueState.currentIndex - 1;
    final prevPlayable = queueState.queue[prevIndex];

    ref.read(queueViewModelProvider.notifier).setCurrentIndex(prevIndex);

    await play(prevPlayable, index: prevIndex);
    AppLogger.info('PlaybackViewModel', '播放上一首: ${prevPlayable.title}');
  }

  void _playNextAutomatically() async {
    final queueState = ref.read(queueViewModelProvider);
    if (queueState.playMode == PlayMode.sequence && !queueState.hasNext) {
      AppLogger.debug('PlaybackViewModel', '已是最后一首，停止');
      return;
    }

    if (queueState.playMode == PlayMode.loopOne) {
      // 单曲循环
      final current = state.currentPlayable;
      if (current != null) {
        await play(current, index: queueState.currentIndex);
      }
      return;
    }

    await next();
  }

  // ==================== 音量/倍速 ====================

  Future<void> setVolume(double value) async {
    if (_disposed) return;
    final clamped = value.clamp(0.0, 1.0);
    await _audioService!.setVolume(clamped);
    state = state.copyWith(volume: clamped);
    await _storage!.setDouble(StorageKeys.playbackVolume, clamped);
  }

  Future<void> setSpeed(double value) async {
    if (_disposed) return;
    final clamped = value.clamp(0.5, 2.0);
    await _audioService!.setPlaybackRate(clamped);
    state = state.copyWith(speed: clamped);
    await _storage!.setDouble(StorageKeys.playbackSpeed, clamped);
  }

  // ==================== 辅助方法 ====================

  /// 注册初始化完成回调
  ///
  /// 如果已经初始化完成，回调会立即执行
  /// 用于 QueueViewModel 恢复播放时等待初始化
  void onInitialized(void Function() callback) {
    // 当前实现中初始化是同步的，直接执行回调
    callback();
  }

  /// 准备音频源（不自动播放）
  ///
  /// 用于恢复播放时准备音频源并设置起始位置
  Future<void> prepareSource(PlayableAudio playable, {int startPosition = 0}) async {
    if (_disposed) return;

    AppLogger.info('PlaybackViewModel', '准备音频源: ${playable.title}');

    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      artist: playable.artist ?? '未知艺术家',
      coverUrl: playable.coverUrl,
      isLoading: true,
    );

    try {
      if (playable.isOnline && playable is OnlinePlayable) {
        await _audioService!.setUrlSource(playable.url);
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
    } catch (e) {
      AppLogger.error('PlaybackViewModel', '准备音频源失败: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载失败',
      );
      rethrow;
    }
  }

  void _startPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
  }

  void _stopPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
  }

  Future<void> _savePosition() async {
    if (_disposed || state.currentPlayable == null) return;
    await _storage!.setInt(StorageKeys.playbackPosition, state.position.inSeconds);
  }

  void _recordHistory(PlayableAudio playable) {
    if (playable is! OnlinePlayable) return;

    try {
      ref.read(historyViewModelProvider.notifier).recordPlay(
        bvid: playable.original.id,
        title: playable.title,
        artist: playable.artist,
        duration: playable.original.duration,
        coverUrl: playable.coverUrl,
        progress: 0,
      );
    } catch (e) {
      AppLogger.debug('PlaybackViewModel', '记录历史失败: $e');
    }
  }

  /// 构建代理 URL
  String _buildProxyUrl(String bvid) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    return '$baseUrl/api/v1/bilibili/proxy/audio/$bvid?format=auto';
  }
}

// ==================== Providers ====================

@riverpod
AudioPlayerService audioPlayerService(Ref ref) {
  return AudioPlayerService();
}

@riverpod
SharedStorageService sharedStorageService(Ref ref) {
  return SharedStorageService.instance;
}
```

- [ ] **Step 2: 运行 build_runner 生成代码**

Run: `cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `playback_viewmodel.freezed.dart` 和 `playback_viewmodel.g.dart`

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.freezed.dart
git add frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.g.dart
git commit -m "feat(player): create PlaybackViewModel with unified state management"
```

---

### Task 2.2: 简化 QueueViewModel [depends on: Task 2.1]

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart`

- [ ] **Step 1: 移除播放相关方法**

删除以下方法（移动到 PlaybackViewModel）：
- `playAt()` - 播放逻辑
- `playNext()` - 下一首逻辑
- `playPrevious()` - 上一首逻辑
- `_prepareFirstAudio()` - 准备播放
- 对 `playerViewModelProvider` 的所有引用

保留以下方法：
- `setQueue()` - 设置队列
- `add()` - 添加到队列
- `removeAt()` - 移除
- `clear()` - 清空
- `setCurrentIndex()` - 设置索引
- `reorder()` - 排序
- `insertNext()` - 插队
- 持久化相关方法

- [ ] **Step 2: 简化后的 QueueViewModel 核心方法**

```dart
/// 播放队列 ViewModel（纯数据管理）
///
/// 职责：
/// 1. 队列数据管理（添加、删除、清空、排序）
/// 2. 当前索引管理
/// 3. 持久化
///
/// 不再负责：
/// - 播放控制（移至 PlaybackViewModel）
/// - 音频加载（移至 PlaybackViewModel）
@Riverpod(keepAlive: true)
class QueueViewModel extends _$QueueViewModel {
  // ... 保留数据相关字段和方法

  /// 设置当前索引（由 PlaybackViewModel 调用）
  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.queue.length) {
      AppLogger.warn('QueueViewModel', '无效索引: $index');
      return;
    }
    state = state.copyWith(currentIndex: index);
    AppLogger.debug('QueueViewModel', '设置索引: $index');
  }

  // 删除: playAt, playNext, playPrevious, _prepareFirstAudio
  // 删除: 对 playerViewModelProvider 的所有引用
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart
git commit -m "refactor(queue): simplify QueueViewModel to pure data management"
```

---

### Task 2.3: 更新 providers.dart 导出 [depends on: Task 2.1, Task 2.2]

**Files:**
- Modify: `frontend_flutter/lib/presentation/providers.dart`

- [ ] **Step 1: 更新导出**

```dart
// ==================== 播放器相关 ====================
export 'viewmodels/player/playback_viewmodel.dart' show playbackViewModelProvider;
export 'viewmodels/player/playback_viewmodel.dart' show PlaybackState;
export 'viewmodels/player/playback_viewmodel.dart' show audioPlayerServiceProvider;
// 移除: playerViewModelProvider 导出
// 保留: queueViewModelProvider, subtitleViewModelProvider, metadataViewModelProvider
export 'viewmodels/player/queue_viewmodel.dart' show queueViewModelProvider;
export 'viewmodels/player/queue_viewmodel.dart' show QueueState;
export 'viewmodels/player/subtitle_viewmodel.dart';
export 'viewmodels/player/metadata_viewmodel.dart' show metadataViewModelProvider;
export 'viewmodels/player/metadata_viewmodel.dart' show metadataServiceProvider;
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/presentation/providers.dart
git commit -m "refactor(providers): update exports for PlaybackViewModel"
```

---

### Task 2.4: 更新 SearchPage 使用新 ViewModel [depends on: Task 2.3]

**Files:**
- Modify: `frontend_flutter/lib/presentation/views/discovery/search_page.dart`

- [ ] **Step 1: 将业务逻辑移到 ViewModel 方法中**

在 SearchViewModel 中添加播放方法（或在 SearchPage 中直接调用 PlaybackViewModel）：

```dart
void _onResultTap(SearchResultItem item) async {
  try {
    // 使用 PlaybackViewModel 播放
    final playbackNotifier = ref.read(playbackViewModelProvider.notifier);
    final queueNotifier = ref.read(queueViewModelProvider.notifier);

    // 创建 Audio 和 OnlinePlayable
    final audio = Audio(
      id: item.bvid,
      title: item.title,
      artist: item.author,
      coverUrl: item.coverUrl,
      duration: item.duration,
    );
    final playable = OnlinePlayable.withProxyUrl(audio);

    // 添加到队列并播放
    await queueNotifier.add(playable, playImmediately: false);
    final index = ref.read(queueViewModelProvider).queue.length - 1;
    await playbackNotifier.play(playable, index: index);

    if (mounted) {
      SnackbarHelper.showPlaying(context, item.title, artist: item.author);
    }
  } catch (e) {
    if (mounted) {
      SnackbarHelper.showError(context, '播放失败: $e');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/presentation/views/discovery/search_page.dart
git commit -m "refactor(search): use PlaybackViewModel for playback"
```

---

### Task 2.5: 更新所有使用 PlayerViewModel 的文件 [depends on: Task 2.3]

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/volume_slider.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/speed_button.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/player_action_bar.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/controls_panel.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/audio_info.dart`
- Modify: `frontend_flutter/lib/presentation/views/player/home_page.dart`
- Modify: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`
- Modify: `frontend_flutter/lib/presentation/views/discovery/explore_page.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart`

- [ ] **Step 1: 更新 queue_viewmodel.dart（关键文件）**

文件位置：`frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart`

此文件有 4 处使用 `playerViewModelProvider`：
- 第 19 行：导入
- 第 314 行：`playAt()` 方法
- 第 656 行：`_loadFromStorage()` 方法
- 第 707 行：`_prepareFirstAudio()` 方法

**需要移除导入并删除所有调用**，因为播放逻辑已移至 `PlaybackViewModel`：
```dart
// 删除第 19 行的导入
- show sharedStorageServiceProvider, playerViewModelProvider;

// 删除 playAt() 中的播放调用（第 314 行附近）
// 删除 _prepareFirstAudio() 中的播放调用（第 707 行附近）
```

- [ ] **Step 2: 更新 volume_slider.dart**

文件位置：`frontend_flutter/lib/presentation/widgets/volume_slider.dart`

将 `ref.read(playerViewModelProvider.notifier).setVolume(value)` 改为：
```dart
ref.read(playbackViewModelProvider.notifier).setVolume(value);
```

- [ ] **Step 2: 更新 speed_button.dart**

文件位置：`frontend_flutter/lib/presentation/widgets/speed_button.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 3: 更新 player_action_bar.dart**

文件位置：`frontend_flutter/lib/presentation/widgets/player_action_bar.dart`

将所有 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 4: 更新 controls_panel.dart**

文件位置：`frontend_flutter/lib/presentation/widgets/controls_panel.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`，调用 `playbackNotifier.togglePlayPause()`。

- [ ] **Step 5: 更新 audio_info.dart**

文件位置：`frontend_flutter/lib/presentation/widgets/audio_info.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 6: 更新 audio_action_menu.dart**

文件位置：`frontend_flutter/lib/presentation/widgets/audio/audio_action_menu.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`，调用 `playbackNotifier.play()` 方法。

- [ ] **Step 7: 更新 home_page.dart**

文件位置：`frontend_flutter/lib/presentation/views/player/home_page.dart`

将所有 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 8: 更新 playlist_detail_page.dart**

文件位置：`frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 9: 更新 explore_page.dart**

文件位置：`frontend_flutter/lib/presentation/views/discovery/explore_page.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 10: 更新 playlist_detail_viewmodel.dart**

文件位置：`frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 11: 更新 local_music_viewmodel.dart**

文件位置：`frontend_flutter/lib/presentation/viewmodels/library/local_music_viewmodel.dart`

将 `playerViewModelProvider` 替换为 `playbackViewModelProvider`。

- [ ] **Step 12: 验证没有遗漏**

Run: `cd frontend_flutter && grep -r "playerViewModelProvider" lib/ --include="*.dart"`
Expected: 无匹配结果（除了 playback_viewmodel.dart 中可能的历史注释）

- [ ] **Step 13: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart
git add frontend_flutter/lib/presentation/widgets/volume_slider.dart
git add frontend_flutter/lib/presentation/widgets/speed_button.dart
git add frontend_flutter/lib/presentation/widgets/player_action_bar.dart
git add frontend_flutter/lib/presentation/widgets/controls_panel.dart
git add frontend_flutter/lib/presentation/widgets/audio_info.dart
git add frontend_flutter/lib/presentation/views/player/home_page.dart
git add frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart
git add frontend_flutter/lib/presentation/views/discovery/explore_page.dart
git add frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart
git commit -m "refactor: migrate all files from PlayerViewModel to PlaybackViewModel"
```

---

### Task 2.6: 删除旧的 PlayerViewModel [depends on: Task 2.5]

**Files:**
- Delete: `frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.freezed.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.g.dart`

- [ ] **Step 1: 确认没有文件引用 playerViewModelProvider**

Run: `cd frontend_flutter && grep -r "playerViewModelProvider" lib/ --include="*.dart"`
Expected: 无匹配结果

- [ ] **Step 2: 删除旧文件**

```bash
rm frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart
rm frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.freezed.dart
rm frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.g.dart
```

- [ ] **Step 3: 运行 flutter analyze**

Run: `cd frontend_flutter && flutter analyze`
Expected: 无错误

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(player): remove old PlayerViewModel"
```

---

### Task 2.7: 添加 PlaybackViewModel 单元测试 [depends on: Task 2.6]

**Files:**
- Create: `frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart`

- [ ] **Step 1: 创建测试文件**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/presentation/viewmodels/player/playback_viewmodel.dart';

void main() {
  group('PlaybackState', () {
    test('初始状态正确', () {
      final state = PlaybackState();
      expect(state.isPlaying, false);
      expect(state.isPaused, false);
      expect(state.isLoading, false);
      expect(state.currentIndex, -1);
      expect(state.title, '未知标题');
      expect(state.artist, '未知艺术家');
      expect(state.volume, 1.0);
      expect(state.speed, 1.0);
    });

    test('copyWith 正确工作', () {
      final state = PlaybackState();
      final newState = state.copyWith(
        isPlaying: true,
        title: '测试歌曲',
        volume: 0.5,
      );

      expect(newState.isPlaying, true);
      expect(newState.title, '测试歌曲');
      expect(newState.volume, 0.5);
      expect(newState.isPaused, false); // 未修改的保持默认值
    });

    test('错误状态正确设置', () {
      final state = PlaybackState();
      final errorState = state.copyWith(
        errorMessage: '播放失败',
        isLoading: false,
      );

      expect(errorState.errorMessage, '播放失败');
      expect(errorState.isLoading, false);
    });
  });

  group('PlaybackViewModel 方法签名验证', () {
    test('PlaybackState 包含必要字段', () {
      // 验证状态包含所有必要的字段
      final state = PlaybackState(
        currentPlayable: null,
        title: '测试',
        artist: '艺术家',
        coverUrl: 'https://example.com/cover.jpg',
        isPlaying: true,
        isPaused: false,
        isLoading: false,
        isCompleted: false,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 3),
        volume: 0.8,
        speed: 1.5,
        currentIndex: 0,
      );

      expect(state.title, '测试');
      expect(state.artist, '艺术家');
      expect(state.coverUrl, 'https://example.com/cover.jpg');
      expect(state.isPlaying, true);
      expect(state.position.inSeconds, 30);
      expect(state.duration!.inMinutes, 3);
      expect(state.volume, 0.8);
      expect(state.speed, 1.5);
      expect(state.currentIndex, 0);
    });
  });
}
```

- [ ] **Step 2: 运行测试**

Run: `cd frontend_flutter && flutter test test/viewmodels/player/playback_viewmodel_test.dart`
Expected: 测试通过

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart
git commit -m "test(player): add PlaybackViewModel unit tests"
```

---

## Part 3: 集成测试与验证

### Task 3.1: 端到端测试

- [ ] **Step 1: 启动后端**

Run: `cd listen-vision-api-python && uv run uvicorn app.main:app`

- [ ] **Step 2: 启动前端**

Run: `cd frontend_flutter && flutter run`

- [ ] **Step 3: 测试播放流程**

1. 搜索 "playlist"
2. 点击搜索结果播放
3. 验证播放立即开始（不再等待 10 秒）
4. 切换页面，验证播放继续
5. 测试暂停/恢复
6. 测试下一首/上一首

- [ ] **Step 4: 检查日志确认流式代理工作**

后端日志应显示：
```
流式音频代理: bvid=xxx, range=bytes=0-
流式代理范围: bytes=0-xxx
```

---

## 完成标准

- [ ] 后端流式代理实现，播放延迟 < 1 秒
- [ ] 前端 PlaybackViewModel 替代 PlayerViewModel
- [ ] QueueViewModel 简化为纯数据管理
- [ ] 单向数据流：UI → PlaybackViewModel → AudioPlayerService
- [ ] 所有测试通过
- [ ] Flutter analyze 无错误

---

## 回滚计划

### 后端回滚

如果流式代理出现问题：

1. **停止后端服务**
   ```bash
   # 找到并终止后端进程
   Get-Process -Name python -ErrorAction SilentlyContinue | Stop-Process -Force
   ```

2. **回滚代码**
   ```bash
   git checkout HEAD~2 -- listen-vision-api-python/app/api/routes/bilibili.py
   git checkout HEAD~2 -- listen-vision-api-python/app/services/bilibili_service.py
   ```

3. **运行测试验证**
   ```bash
   cd listen-vision-api-python && uv run pytest tests/test_bilibili_proxy.py -v
   ```

4. **重启服务**
   ```bash
   cd listen-vision-api-python && uv run uvicorn app.main:app
   ```

### 前端回滚

如果 PlaybackViewModel 重构出现问题：

1. **停止前端应用** (Ctrl+C 或关闭终端)

2. **回滚所有修改的文件**
   ```bash
   # 回滚到重构前的提交
   git log --oneline -10  # 找到重构前的 commit hash

   # 假设重构前的 commit 是 abc1234
   git checkout abc1234 -- frontend_flutter/lib/presentation/

   # 或者逐个文件回滚
   git checkout HEAD~5 -- frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart
   git checkout HEAD~5 -- frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart
   git checkout HEAD~5 -- frontend_flutter/lib/presentation/providers.dart
   ```

3. **删除新建的文件**
   ```bash
   rm -f frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart
   rm -f frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.freezed.dart
   rm -f frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.g.dart
   ```

4. **重新生成代码**
   ```bash
   cd frontend_flutter && dart run build_runner build --delete-conflicting-outputs
   ```

5. **运行 flutter analyze 验证**
   ```bash
   cd frontend_flutter && flutter analyze
   ```

6. **重新启动应用**
   ```bash
   flutter run
   ```

### 部分回滚

如果只有部分功能有问题，可以单独回滚：

| 问题 | 回滚方案 |
|------|----------|
| 流式代理 Range 请求有问题 | 只回滚 `bilibili.py` 端点，保留 `stream_audio_proxy` 方法 |
| PlaybackViewModel 播放有问题 | 恢复 `player_viewmodel.dart`，保留 `PlaybackViewModel` 作为备用 |
| 某个页面有问题 | 只回滚该页面的文件 |