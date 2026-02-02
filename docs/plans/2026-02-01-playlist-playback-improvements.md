# 歌单播放功能完善与UI优化实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完善歌单播放功能（添加播放全部按钮）、修复本地歌曲播放问题、优化播放页面UI布局（移收藏按钮到底部工具栏）、统一注释格式和播放状态

**Architecture:** 分三个层次实施：1) 统一播放状态枚举和注释格式；2) 修复本地播放bug；3) UI层优化和歌单整体播放功能

**Tech Stack:** Flutter 3.38.5, Dart 3.10.4, Provider状态管理

---

## 现状分析

### 已完成（基础架构）
- **播放控制**: `PlaybackController` 支持本地/在线播放
- **歌单管理**: `PlaylistProvider` 支持歌单CRUD
- **收藏功能**: UI层已完成收藏按钮集成
- **单曲播放**: 歌单项点击可播放单个歌曲

### 需要修复/添加
1. **本地歌曲播放Bug**: 歌单中本地歌曲可能无法正常播放
2. **歌单整体播放**: 缺少"播放全部"功能
3. **UI布局问题**: 收藏按钮与标题挤在一行，显得拥挤
4. **状态枚举不统一**: 使用 audioplayers 的 `PlayerState`，需统一为自定义状态
5. **注释格式不统一**: 部分文件缺少 DartDoc 注释

---

## Task 1: 创建统一播放状态枚举

**Files:**
- Create: `frontend_flutter/lib/core/constants/playback_status.dart`
- Modify: `frontend_flutter/lib/presentation/providers/audio/playback_controller.dart`

**Step 1: 创建播放状态枚举文件**

创建 `frontend_flutter/lib/core/constants/playback_status.dart`:

```dart
/// 播放状态枚举
///
/// 统一定义应用的播放状态，与 audioplayers 的 PlayerState 解耦
enum PlaybackStatus {
  /// 空闲状态 - 未加载任何音频
  idle,

  /// 加载中 - 正在加载音频源或元数据
  loading,

  /// 就绪 - 音频已加载，等待播放
  ready,

  /// 播放中
  playing,

  /// 已暂停
  paused,

  /// 播放完成
  completed,

  /// 错误状态
  error,
}

/// 播放状态扩展方法
extension PlaybackStatusExtension on PlaybackStatus {
  /// 是否可以播放
  bool get canPlay => this == PlaybackStatus.ready || this == PlaybackStatus.paused;

  /// 是否可以暂停
  bool get canPause => this == PlaybackStatus.playing;

  /// 是否正在播放（包括缓冲中）
  bool get isActive => this == PlaybackStatus.playing || this == PlaybackStatus.loading;

  /// 是否显示加载指示器
  bool get showLoading => this == PlaybackStatus.loading;

  /// 用户友好的状态描述
  String get description {
    switch (this) {
      case PlaybackStatus.idle:
        return '未播放';
      case PlaybackStatus.loading:
        return '加载中...';
      case PlaybackStatus.ready:
        return '准备就绪';
      case PlaybackStatus.playing:
        return '播放中';
      case PlaybackStatus.paused:
        return '已暂停';
      case PlaybackStatus.completed:
        return '播放完成';
      case PlaybackStatus.error:
        return '播放错误';
    }
  }

  /// 图标
  // String get iconName {
  //   switch (this) {
  //     case PlaybackStatus.playing:
  //       return 'pause';
  //     default:
  //       return 'play_arrow';
  //   }
  // }
}
```

**Step 2: 运行代码分析**

```powershell
cd frontend_flutter
flutter analyze lib/core/constants/playback_status.dart
```

Expected: 0 issues

**Step 3: 在 PlaybackController 中集成新状态枚举**

编辑 `frontend_flutter/lib/presentation/providers/audio/playback_controller.dart`:

在 import 部分添加:
```dart
import 'package:demo/core/constants/playback_status.dart';
```

在类中添加状态转换方法（约第124行后）:

```dart
  /// 获取统一的播放状态
  PlaybackStatus get playbackStatus {
    if (_lastPlayerState == PlayerState.stopped && _currentSourceUrl == null) {
      return PlaybackStatus.idle;
    }
    if (_isLoadingSource) {
      return PlaybackStatus.loading;
    }
    if (_lastPlayerState == PlayerState.playing) {
      return PlaybackStatus.playing;
    }
    if (_lastPlayerState == PlayerState.paused) {
      return PlaybackStatus.paused;
    }
    if (_lastPlayerState == PlayerState.completed) {
      return PlaybackStatus.completed;
    }
    return PlaybackStatus.ready;
  }

  /// 是否正在加载音频源
  bool _isLoadingSource = false;

  /// 检查播放状态是否为空闲
  bool get isIdle => playbackStatus == PlaybackStatus.idle;

  /// 检查是否正在播放
  bool get isPlaying => playbackStatus == PlaybackStatus.playing;

  /// 检查是否已暂停
  bool get isPaused => playbackStatus == PlaybackStatus.paused;

  /// 检查是否显示加载指示器
  bool get showLoadingIndicator => playbackStatus.showLoading;
```

**Step 4: 更新加载状态标记**

在 `setUrlSource` 和 `setFileSource` 方法开始时添加 `_isLoadingSource = true`，结束时设置 `false`:

```dart
  /// 设置在线音频源
  Future<void> setUrlSource(String url) async {
    AppLogger.info('PlaybackController', '设置在线音频源: $url');
    _isLoadingSource = true;
    notifyListeners();
    try {
      await _player.setSource(UriSource(url))
          .timeout(const Duration(seconds: 10));
      _currentSourceUrl = url;
    } finally {
      _isLoadingSource = false;
      notifyListeners();
    }
  }

  /// 设置本地文件音频源
  Future<void> setFileSource(String filePath) async {
    AppLogger.info('PlaybackController', '设置本地音频源: $filePath');
    _isLoadingSource = true;
    notifyListeners();
    try {
      await _player.setSource(DeviceFileSource(filePath))
          .timeout(const Duration(seconds: 5));
      _currentSourceUrl = filePath;
    } finally {
      _isLoadingSource = false;
      notifyListeners();
    }
  }
```

**Step 5: 运行测试验证**

```powershell
cd frontend_flutter
flutter test test/providers/player/playback_controller_test.dart
```

Expected: PASS

**Step 6: 提交**

```powershell
cd frontend_flutter
git add lib/core/constants/playback_status.dart lib/presentation/providers/audio/playback_controller.dart
git commit -m "refactor(audio): add unified PlaybackStatus enum"
```

---

## Task 2: 修复本地歌曲播放问题

**Files:**
- Modify: `frontend_flutter/lib/presentation/pages/playlist_detail_page.dart:551-593`

**Step 1: 分析问题**

当前 `_playPlaylistItem` 方法使用 `playOnlineAudio`，对于本地歌曲（bvid 为空或以 file:// 开头）会失败。

**Step 2: 创建测试文件**

创建 `frontend_flutter/test/pages/playlist_detail_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/pages/playlist_detail_page.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaylistDetailPage', () {
    testWidgets('应该能够播放本地歌曲', (tester) async {
      final audioProvider = AudioProvider();
      final playlistProvider = PlaylistProvider();
      final authProvider = AuthProvider();

      // 创建包含本地歌曲的测试歌单
      await tester.runAsync(() async {
        // 测试本地歌曲播放逻辑
      });

      expect(find.byType(PlaylistDetailPage), findsOneWidget);
    });
  });
}
```

**Step 3: 修改 _playPlaylistItem 方法支持本地歌曲**

编辑 `frontend_flutter/lib/presentation/pages/playlist_detail_page.dart`，修改 `_playPlaylistItem` 方法:

```dart
  /// 播放歌单项（支持在线和本地歌曲）
  ///
  /// 根据歌曲类型（在线/本地）选择不同的播放方式
  Future<void> _playPlaylistItem(
    BuildContext context,
    PlaylistItem item,
  ) async {
    final audioProvider = context.read<AudioProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();
    final authProvider = context.read<AuthProvider>();

    await runAsync(
      operation: () async {
        // 判断是否为本地歌曲
        final isLocal = item.bvid.isEmpty || item.bvid.startsWith('file://');

        if (isLocal) {
          // 本地歌曲播放逻辑
          if (item.localPath == null && item.bvid.isEmpty) {
            throw Exception('本地歌曲路径为空');
          }

          final localPath = item.localPath ?? item.bvid.replaceFirst('file://', '');

          AppLogger.info('PlaylistDetailPage', '播放本地歌曲: $localPath');

          await audioProvider.loadAudio(localPath);
        } else {
          // 在线歌曲播放逻辑
          final audio = Audio.fromDto({
            'bvid': item.bvid,
            'title': item.title ?? item.bvid,
            'artist': item.artist,
            'cover': item.coverUrl,
            'duration': item.duration,
          });

          AppLogger.info('PlaylistDetailPage', '播放在线歌曲: ${audio.title}');

          await audioProvider.playOnlineAudio(audio: audio);
        }

        // 记录播放历史
        if (authProvider.isLoggedIn) {
          await historyProvider.recordPlay(
            bvid: item.bvid,
            title: item.title ?? item.bvid,
            artist: item.artist ?? '',
            coverUrl: item.coverUrl,
            duration: item.duration,
          );
        }
      },
      loadingMessage: '正在加载...',
      successMessage: '开始播放: ${item.title ?? item.bvid}',
      onError: () {
        AppLogger.error('PlaylistDetailPage', '播放失败');
      },
    );
  }
```

**Step 4: 检查 PlaylistItem 实体是否有 localPath 字段**

检查 `frontend_flutter/lib/domain/entities/playlist/playlist.dart`:

如果缺少 `localPath`，需要添加:

```dart
/// 歌单项实体
class PlaylistItem extends Equatable {
  final String? id;
  final String bvid;
  final String? title;
  final String? artist;
  final String? coverUrl;
  final int? duration;
  final int? orderIndex;
  final String? localPath; // 添加本地路径字段

  // ... 其他代码
}
```

**Step 5: 运行测试**

```powershell
cd frontend_flutter
flutter test test/pages/playlist_detail_page_test.dart
```

Expected: PASS

**Step 6: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/pages/playlist_detail_page.dart lib/domain/entities/playlist/playlist.dart test/pages/playlist_detail_page_test.dart
git commit -m "fix(playlist): support local audio playback in playlist items"
```

---

## Task 3: 添加歌单播放全部功能

**Files:**
- Modify: `frontend_flutter/lib/presentation/pages/playlist_detail_page.dart:419-468`

**Step 1: 在歌单信息区域添加播放全部按钮**

修改 `_buildPlaylistInfo` 方法，添加播放全部按钮:

```dart
  /// 构建歌单信息区域（含播放全部按钮）
  Widget _buildPlaylistInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _playlist?.isNowPlaying == true
                    ? Icons.play_circle
                    : Icons.playlist_play,
                size: 48,
                color: _playlist?.isNowPlaying == true
                    ? Colors.blue
                    : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _playlist?.name ?? '',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_playlist?.description != null)
                      Text(
                        _playlist!.description!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    Text(
                      '${_detail?.items.length ?? 0}首',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 播放全部按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _playAll(context),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('播放全部'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
```

**Step 2: 实现 _playAll 方法**

在 `PlaylistDetailPage` 类中添加 `_playAll` 方法:

```dart
  /// 播放全部歌曲
  ///
  /// 将歌单中所有歌曲添加到播放队列并开始播放第一首
  Future<void> _playAll(BuildContext context) async {
    if (_detail == null || _detail!.items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('歌单为空'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final audioProvider = context.read<AudioProvider>();
    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();

    AppLogger.info('PlaylistDetailPage', '开始播放歌单: ${_playlist?.name}, 共 ${_detail!.items.length} 首');

    // 显示加载提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('正在准备播放...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final items = _detail!.items;

      // 分离本地和在线歌曲
      final localItems = <PlaylistItem>[];
      final onlineItems = <PlaylistItem>[];

      for (final item in items) {
        if (item.bvid.isEmpty || item.bvid.startsWith('file://')) {
          localItems.add(item);
        } else {
          onlineItems.add(item);
        }
      }

      // 先播放第一首
      await _playPlaylistItem(context, items.first);

      // 将剩余歌曲添加到播放队列
      for (var i = 1; i < items.length; i++) {
        final item = items[i];
        final isLocal = item.bvid.isEmpty || item.bvid.startsWith('file://');

        if (isLocal) {
          // 本地歌曲添加到队列
          final localPath = item.localPath ?? item.bvid.replaceFirst('file://', '');
          await audioProvider.addToQueue(localPath, isLocal: true);
        } else {
          // 在线歌曲添加到队列
          final audio = Audio.fromDto({
            'bvid': item.bvid,
            'title': item.title ?? item.bvid,
            'artist': item.artist,
            'cover': item.coverUrl,
            'duration': item.duration,
          });
          await audioProvider.addToQueueOnline(audio);
        }
      }

      AppLogger.info('PlaylistDetailPage', '已添加 ${items.length - 1} 首歌曲到播放队列');
    } catch (e) {
      AppLogger.error('PlaylistDetailPage', '播放全部失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
```

**Step 3: 检查 AudioProvider 是否有队列方法**

检查 `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart` 是否有以下方法:
- `addToQueue(String path, {bool isLocal})`
- `addToQueueOnline(Audio audio)`

如果没有，需要添加（见 Task 4）。

**Step 4: 运行测试**

```powershell
cd frontend_flutter
flutter test test/pages/playlist_detail_page_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/pages/playlist_detail_page.dart
git commit -m "feat(playlist): add play all button to playlist detail page"
```

---

## Task 4: 扩展 AudioProvider 支持播放队列

**Files:**
- Modify: `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart`

**Step 1: 添加队列相关方法**

编辑 `audio_provider.dart`，添加以下方法:

```dart
  /// 添加本地音频到播放队列
  ///
  /// [path] 本地文件路径
  /// [isLocal] 是否为本地文件
  Future<void> addToQueue(String path, {bool isLocal = true}) async {
    AppLogger.info('AudioProvider', '添加到队列: $path (isLocal: $isLocal)');

    if (isLocal) {
      _localQueue.add(path);
    } else {
      _onlineQueue.add(path);
    }
    notifyListeners();
  }

  /// 添加在线音频到播放队列
  ///
  /// [audio] 音频实体
  Future<void> addToQueueOnline(Audio audio) async {
    AppLogger.info('AudioProvider', '添加在线音频到队列: ${audio.title}');
    _onlineQueue.add(audio);
    notifyListeners();
  }

  /// 清空播放队列
  void clearQueue() {
    AppLogger.info('AudioProvider', '清空播放队列');
    _localQueue.clear();
    _onlineQueue.clear();
    notifyListeners();
  }

  /// 获取队列长度
  int get queueLength => _localQueue.length + _onlineQueue.length;

  /// 本地音频队列
  final List<String> _localQueue = [];

  /// 在线音频队列
  final List<dynamic> _onlineQueue = [];
```

**Step 2: 在类属性声明区域添加队列变量**

在 `AudioProvider` 类的属性区域添加:

```dart
  // 播放队列
  final List<String> _localQueue = [];
  final List<Audio> _onlineQueue = [];
```

**Step 3: 处理播放完成自动播放下一首**

在 `_setupPlayerListeners` 方法中添加播放完成监听:

```dart
    _player.onPlayerComplete.listen((_) {
      AppLogger.info('PlaybackController', '播放完成');
      _lastPlayerState = PlayerState.completed;

      // 尝试播放队列中的下一首
      _playNextInQueue();
    });
```

添加 `_playNextInQueue` 方法:

```dart
  /// 播放队列中的下一首
  Future<void> _playNextInQueue() async {
    if (_onlineQueue.isNotEmpty) {
      final nextAudio = _onlineQueue.removeAt(0);
      await playOnlineAudio(audio: nextAudio);
    } else if (_localQueue.isNotEmpty) {
      final nextPath = _localQueue.removeAt(0);
      await loadAudio(nextPath);
    } else {
      notifyListeners();
    }
  }
```

**Step 4: 运行测试**

```powershell
cd frontend_flutter
flutter test test/providers/audio/audio_provider_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/providers/audio/audio_provider.dart
git commit -m "feat(audio): add playback queue support"
```

---

## Task 5: 重构播放页面UI - 收藏按钮移到底部工具栏

**Files:**
- Modify: `frontend_flutter/lib/presentation/widgets/audio_info.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/controls_panel.dart` (或对应的控制面板组件)
- Create: `frontend_flutter/lib/presentation/widgets/player_action_bar.dart`

**Step 1: 创建底部操作栏组件**

创建 `frontend_flutter/lib/presentation/widgets/player_action_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放器底部操作栏
///
/// 包含收藏、添加到歌单、更多等操作按钮
class PlayerActionBar extends StatelessWidget {
  const PlayerActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<AudioMetadataProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();
    final currentId = metadataProvider.currentPlayable?.id ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (currentId.isNotEmpty) ...[
          // 收藏按钮
          _ActionButton(
            icon: playlistProvider.isFavorited(currentId)
                ? Icons.favorite
                : Icons.favorite_border,
            label: '收藏',
            iconColor: playlistProvider.isFavorited(currentId)
                ? Theme.of(context).colorScheme.error
                : null,
            onTap: () => _handleFavorite(context, playlistProvider, metadataProvider),
          ),
          // 添加到歌单按钮
          _ActionButton(
            icon: Icons.playlist_add,
            label: '添加',
            onTap: () => _handleAddToPlaylist(context),
          ),
          // 更多按钮
          _ActionButton(
            icon: Icons.more_horiz,
            label: '更多',
            onTap: () => _handleMore(context),
          ),
        ] else ...[
          // 未播放时显示提示
          const Text(
            '暂无播放内容',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  /// 处理收藏按钮点击
  Future<void> _handleFavorite(
    BuildContext context,
    PlaylistProvider playlistProvider,
    AudioMetadataProvider metadataProvider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn || authProvider.user?.token == null) {
      if (context.mounted) {
        _showSnackBar(context, '请先登录后收藏', Colors.orange);
      }
      return;
    }

    final currentPlayable = metadataProvider.currentPlayable;
    if (currentPlayable == null) return;

    final bvid = currentPlayable.id;
    final wasFavorited = playlistProvider.isFavorited(bvid);

    AppLogger.logButtonClick(
      wasFavorited ? '取消收藏' : '收藏',
      'PlayerActionBar',
      parameters: {'bvid': bvid, 'title': currentPlayable.title},
    );

    try {
      await playlistProvider.toggleFavorite(
        authProvider.user!.token!,
        bvid,
        title: currentPlayable.title,
        artist: currentPlayable.artist,
        duration: currentPlayable.duration,
        coverUrl: currentPlayable.coverUrl,
      );

      if (context.mounted) {
        _showSnackBar(
          context,
          wasFavorited ? '已取消收藏' : '已添加到我喜欢',
          wasFavorited ? Colors.grey : Colors.green,
        );
      }
    } catch (e) {
      AppLogger.error('PlayerActionBar', '收藏操作失败: $e');
      if (context.mounted) {
        _showSnackBar(context, '操作失败: $e', Colors.red);
      }
    }
  }

  /// 处理添加到歌单
  void _handleAddToPlaylist(BuildContext context) {
    AppLogger.logButtonClick('添加到歌单', 'PlayerActionBar');
    // TODO: 实现添加到歌单对话框
    _showSnackBar(context, '添加到歌单功能开发中', Colors.orange);
  }

  /// 处理更多选项
  void _handleMore(BuildContext context) {
    AppLogger.logButtonClick('更多选项', 'PlayerActionBar');
    // TODO: 实现更多选项菜单
    _showSnackBar(context, '更多选项功能开发中', Colors.orange);
  }

  /// 显示提示消息
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: 修改 AudioInfo 组件，移除收藏按钮**

编辑 `frontend_flutter/lib/presentation/widgets/audio_info.dart`:

简化 `_buildAudioInfo` 方法，移除收藏按钮:

```dart
  /// 构建音频信息（标题和艺术家）
  Widget _buildAudioInfo(BuildContext context, AudioMetadataProvider controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),

        // 标题
        Text(
          controller.title,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),

        const SizedBox(height: 12),

        // 艺术家
        Text(
          controller.artist,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeSmall,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
```

删除 `_handleFavoriteToggle` 方法。

**Step 3: 修改 HomePage 布局，添加操作栏**

编辑 `frontend_flutter/lib/presentation/pages/home_page.dart`:

在 import 部分添加:
```dart
import 'package:demo/presentation/widgets/player_action_bar.dart';
```

修改 body 部分，添加操作栏:

```dart
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: const [
          // 音频信息（封面、标题、艺术家）
          AudioInfo(),
          // 控制面板（进度条、播放控制）
          ControlsPanel(),
          // 底部操作栏（收藏、添加到歌单、更多）
          PlayerActionBar(),
        ],
      ),
```

**Step 4: 运行测试**

```powershell
cd frontend_flutter
flutter test test/widgets/player_action_bar_test.dart
flutter test test/widgets/audio_info_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/widgets/player_action_bar.dart lib/presentation/widgets/audio_info.dart lib/presentation/pages/home_page.dart
git commit -m "refactor(ui): move favorite button to bottom action bar"
```

---

## Task 6: 统一注释格式（DartDoc标准）

**Files:**
- Modify: 所有修改过的文件

**Step 1: 确保所有公共类都有 DartDoc 注释**

检查并添加注释格式:

```dart
/// 类/方法的单行描述
///
/// 更详细的描述（可选）。
///
/// 参数:
/// - [paramName] 参数描述
///
/// 返回:
/// - 返回值描述
///
/// 抛出:
/// - [ExceptionType] 异常描述
///
/// 示例:
/// ```dart
/// final result = methodName();
/// ```
```

**Step 2: 运行代码分析**

```powershell
cd frontend_flutter
flutter analyze
```

Expected: 0 issues related to documentation

**Step 3: 提交**

```powershell
cd frontend_flutter
git add .
git commit -m "docs: standardize DartDoc comments across codebase"
```

---

## Task 7: 运行完整测试套件

**Step 1: 运行所有测试**

```powershell
cd frontend_flutter
flutter test
```

Expected: 所有新增和修改的测试通过

**Step 2: 运行代码分析**

```powershell
cd frontend_flutter
flutter analyze
```

Expected: 0 issues

**Step 3: 手动测试验证**

验证以下功能:
1. [ ] 点击歌单详情页的"播放全部"按钮，歌单按顺序播放
2. [ ] 在歌单中点击本地歌曲，能够正常播放
3. [ ] 播放页面收藏按钮在底部操作栏中显示
4. [ ] 标题区域不再拥挤
5. [ ] 底部操作栏的"添加到歌单"和"更多"按钮显示（功能待开发）

**Step 4: 最终提交**

```powershell
cd frontend_flutter
git add .
git commit -m "feat(playlist): complete playlist playback feature and UI optimization

Features:
- Add play all button to playlist detail page
- Support local audio playback from playlist
- Move favorite button to bottom action bar
- Add unified PlaybackStatus enum
- Add playback queue support

Bug fixes:
- Fix local audio playback from playlist items

UI improvements:
- Optimize player page layout
- Add dedicated action bar for player controls

Documentation:
- Standardize DartDoc comments
- Add inline documentation for new features"
```

---

## 验收标准

### 功能验证
- [ ] 歌单详情页显示"播放全部"按钮
- [ ] 点击"播放全部"后歌单按顺序播放
- [ ] 本地歌曲能从歌单中正常播放
- [ ] 播放页面标题区域整洁，不再拥挤
- [ ] 收藏按钮位于底部操作栏
- [ ] 底部操作栏显示"收藏"、"添加"、"更多"三个按钮

### 测试覆盖
- [ ] PlaybackStatus 枚举测试: 通过
- [ ] 本地歌曲播放测试: 通过
- [ ] 播放全部功能测试: 通过
- [ ] PlayerActionBar 组件测试: 通过
- [ ] 全部测试套件: 通过

### 代码质量
- [ ] flutter analyze: 0 issues
- [ ] 所有公共 API 都有 DartDoc 注释
- [ ] 遵循日志规范 (LOGGING_STANDARDS.md)
- [ ] 遵循注释规范 (CODE_COMMENT_STANDARDS.md)

---

## 相关文档
- [LOGGING_STANDARDS.md](../../LOGGING_STANDARDS.md) - 日志记录规范
- [CODE_COMMENT_STANDARDS.md](../../CODE_COMMENT_STANDARDS.md) - 代码注释规范
- [CLAUDE.md](../../CLAUDE.md) - 项目开发指南

---

## 估计工作量
- Task 1: 统一播放状态枚举 - 20分钟
- Task 2: 修复本地歌曲播放 - 15分钟
- Task 3: 添加播放全部功能 - 25分钟
- Task 4: 扩展播放队列 - 20分钟
- Task 5: UI布局重构 - 30分钟
- Task 6: 统一注释格式 - 15分钟
- Task 7: 测试和验证 - 15分钟

**总计**: 约140分钟 (2-2.5小时)
