# 收藏歌曲功能实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在UI层添加完整的收藏歌曲交互功能，让用户可以在播放器、探索页面、播放历史等位置收藏/取消收藏歌曲

**Architecture:** 后端API和Provider层已100%完成，仅需实现UI层的收藏按钮、状态显示和交互反馈

**Tech Stack:** Flutter 3.38.5, Dart 3.10.4, Provider状态管理, 后端API已就绪

---

## 现状分析

### 已完成（100%）
- **后端API** (`listen-vision_api/`):
  - `POST /api/playlists/favorites/toggle` - 切换收藏状态
  - `GET /api/playlists/favorites/check/:bvid` - 检查收藏状态
  - `GET /api/playlists/favorites` - 获取收藏列表
- **Provider层** (`playlist_provider.dart:341-381`):
  - `toggleFavorite()` - 切换收藏
  - `isFavorited()` - 检查状态
  - `loadFavorites()` - 加载列表
- **测试覆盖**:
  - 后端: 25个收藏测试用例
  - 前端: 42个收藏测试用例

### 需要实现
1. **播放器页面** (`home_page.dart`) - 收藏按钮
2. **探索页面** (`explore_page.dart`) - 列表项收藏状态
3. **播放历史页面** (`play_history_page.dart`) - 列表项收藏状态
4. **通用收藏按钮组件** (`widgets/cards/favorite_button.dart`) - 新建
5. **UI交互反馈** - SnackBar提示、动画效果

---

## Task 1: 创建通用收藏按钮组件

**Files:**
- Create: `frontend_flutter/lib/presentation/widgets/cards/favorite_button.dart`

**Step 1: 写失败的测试**

创建 `frontend_flutter/test/widgets/cards/favorite_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';

void main() {
  group('FavoriteButton', () {
    testWidgets('显示空心爱心图标当未收藏时', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('显示实心爱心图标当已收藏时', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final favoriteIcon = tester.widget<Icon>(find.byType(Icon));
      expect(favoriteIcon.icon, Icons.favorite);
    });

    testWidgets('点击时调用onPressed回调', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FavoriteButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('显示自定义size尺寸', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () {},
              size: 32,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width?.value, 32);
      expect(sizedBox.height?.value, 32);
    });
  });
}
```

**Step 2: 运行测试验证失败**

```powershell
cd frontend_flutter
flutter test test/widgets/cards/favorite_button_test.dart
```

Expected: FAIL - "file not found"

**Step 3: 实现组件**

创建 `frontend_flutter/lib/presentation/widgets/cards/favorite_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 收藏按钮组件
///
/// 用于在列表和播放器中显示收藏状态，支持点击切换
class FavoriteButton extends StatefulWidget {
  /// 当前收藏状态
  final bool isFavorited;

  /// 点击回调
  final VoidCallback onPressed;

  /// 按钮尺寸
  final double size;

  /// 是否禁用
  final bool disabled;

  /// 颜色
  final Color? activeColor;

  const FavoriteButton({
    super.key,
    required this.isFavorited,
    required this.onPressed,
    this.size = 24,
    this.disabled = false,
    this.activeColor,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorited != oldWidget.isFavorited) {
      if (widget.isFavorited) {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.colorScheme.error;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IconButton(
          icon: Icon(
            widget.isFavorited ? Icons.favorite : Icons.favorite_border,
            color: widget.isFavorited ? activeColor : theme.colorScheme.onSurfaceVariant,
          ),
          iconSize: widget.size,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: widget.size,
            minHeight: widget.size,
          ),
          onPressed: widget.disabled
              ? null
              : () {
                  AppLogger.logButtonClick(
                    widget.isFavorited ? '取消收藏' : '收藏',
                    'FavoriteButton',
                  );
                  widget.onPressed();
                },
        ),
      ),
    );
  }
}
```

**Step 4: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/widgets/cards/favorite_button_test.dart
```

Expected: PASS (4/4 tests passing)

**Step 5: 提交**

```powershell
cd frontend_flutter
git add test/widgets/cards/favorite_button_test.dart lib/presentation/widgets/cards/favorite_button.dart
git commit -m "feat(ui): add favorite button widget with animation"
```

---

## Task 2: 在播放器页面添加收藏按钮

**Files:**
- Modify: `frontend_flutter/lib/presentation/widgets/audio_info.dart:82-106`

**Step 1: 写失败的测试**

创建 `frontend_flutter/test/widgets/audio_info_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioInfo with Favorite', () {
    late Audio testAudio;
    late AudioMetadataProvider metadataProvider;
    late PlaylistProvider playlistProvider;

    setUp(() {
      testAudio = Audio(
        id: 'BV123456',
        title: 'Test Song',
        artist: 'Test Artist',
        coverUrl: 'https://example.com/cover.jpg',
        duration: 180,
      );

      metadataProvider = AudioMetadataProvider();
      playlistProvider = PlaylistProvider();

      // 设置当前播放
      metadataProvider.setCurrentPlayable(testAudio);
    });

    testWidgets('显示收藏按钮', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: metadataProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('收藏按钮点击调用toggleFavorite', (tester) async {
      var toggleCalled = false;
      String? capturedBvid;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: metadataProvider),
            ChangeNotifierProvider(
              create: (_) => playlistProvider..toggleFavorite = (_, bvid, {__) async {
                toggleCalled = true;
                capturedBvid = bvid;
                return true;
              } as Future<bool> Function(String, String, {String? title, String? artist, int? duration, String? coverUrl})>,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(toggleCalled, true);
      expect(capturedBvid, 'BV123456');
    });
  });
}
```

**Step 2: 运行测试验证失败**

```powershell
cd frontend_flutter
flutter test test/widgets/audio_info_test.dart
```

Expected: FAIL - 收藏按钮未找到

**Step 3: 修改AudioInfo组件**

编辑 `frontend_flutter/lib/presentation/widgets/audio_info.dart`:

在 `import` 部分添加:
```dart
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
```

修改 `_buildAudioInfo` 方法（第82-106行）为:

```dart
  /// 构建音频信息（标题和艺术家）
  Widget _buildAudioInfo(BuildContext context, AudioMetadataProvider controller) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final currentId = controller.currentPlayable?.id ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),

        // 标题行 - 添加收藏按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                controller.title,
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (currentId.isNotEmpty) ...[
              const SizedBox(width: 8),
              FavoriteButton(
                isFavorited: playlistProvider.isFavorited(currentId),
                size: 28,
                onPressed: () => _handleFavoriteToggle(context, playlistProvider, controller),
              ),
            ],
          ],
        ),

        const SizedBox(height: 15),
        Text(
          controller.artist,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeSmall,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 处理收藏按钮点击
  Future<void> _handleFavoriteToggle(
    BuildContext context,
    PlaylistProvider playlistProvider,
    AudioMetadataProvider controller,
  ) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先登录后收藏'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final currentPlayable = controller.currentPlayable;
    if (currentPlayable == null) return;

    final bvid = currentPlayable.id;
    final wasFavorited = playlistProvider.isFavorited(bvid);

    try {
      await playlistProvider.toggleFavorite(
        authProvider.user!.token,
        bvid,
        title: currentPlayable.title,
        artist: currentPlayable.artist,
        duration: currentPlayable.duration,
        coverUrl: currentPlayable.coverUrl,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasFavorited ? '已取消收藏' : '已添加到我喜欢'),
            backgroundColor: wasFavorited ? Colors.grey : Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('AudioInfo', '收藏操作失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
```

同时在文件顶部添加 `AuthProvider` 导入:
```dart
import 'package:demo/presentation/providers/auth/auth_provider.dart';
```

**Step 4: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/widgets/audio_info_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/widgets/audio_info.dart test/widgets/audio_info_test.dart
git commit -m "feat(ui): add favorite button to audio info widget"
```

---

## Task 3: 探索页面添加收藏状态

**Files:**
- Modify: `frontend_flutter/lib/presentation/pages/explore_page.dart:352-443`

**Step 1: 写失败的测试**

创建 `frontend_flutter/test/pages/explore_page_favorite_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/pages/explore_page.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExplorePage Favorite Integration', () {
    testWidgets('音乐区卡片显示收藏状态', (tester) async {
      final playlistProvider = PlaylistProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BilibiliProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: playlistProvider),
          ],
          child: const MaterialApp(
            home: ExplorePage(),
          ),
        ),
      );

      // 设置测试数据
      await tester.runAsync(() async {
        await tester.pump();
      });

      // 验证收藏按钮存在
      expect(find.byIcon(Icons.favorite_border), findsWidgets);
    });
  });
}
```

**Step 2: 运行测试验证失败**

```powershell
cd frontend_flutter
flutter test test/pages/explore_page_favorite_test.dart
```

Expected: FAIL - 收藏按钮未在音乐区卡片中实现

**Step 3: 修改ExplorePage音乐区卡片**

编辑 `frontend_flutter/lib/presentation/pages/explore_page.dart`:

在 `import` 部分添加:
```dart
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
```

修改 `_buildMusicZoneCard` 方法（第352-443行），在卡片中添加收藏按钮。

找到 `trailing` 部分（第427-437行），修改为:

```dart
              // 收藏状态按钮
              Consumer<PlaylistProvider>(
                builder: (context, playlistProvider, _) {
                  return FavoriteButton(
                    isFavorited: playlistProvider.isFavorited(bvid),
                    size: 24,
                    onPressed: () => _handleFavoriteToggle(
                      context,
                      playlistProvider,
                      bvid,
                      item,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              // 播放按钮
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                color: Colors.blue,
                iconSize: 32,
                onPressed: () {
                  if (bvid.isNotEmpty) {
                    _playOnlineAudio(context, bvid, item);
                  }
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
```

添加处理方法:

```dart
  /// 处理收藏按钮点击
  Future<void> _handleFavoriteToggle(
    BuildContext context,
    PlaylistProvider playlistProvider,
    String bvid,
    Map<String, dynamic> item,
  ) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      if (mounted) {
        DialogHelper.showSnackBar(
          context,
          '请先登录后收藏',
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    final wasFavorited = playlistProvider.isFavorited(bvid);

    try {
      await playlistProvider.toggleFavorite(
        authProvider.user!.token,
        bvid,
        title: item['title'],
        artist: item['author'],
        coverUrl: item['cover'],
      );

      if (mounted) {
        DialogHelper.showSnackBar(
          context,
          wasFavorited ? '已取消收藏' : '已添加到我喜欢',
          backgroundColor: wasFavorited ? Colors.grey : Colors.green,
        );
      }
    } catch (e) {
      AppLogger.error('ExplorePage', '收藏操作失败: $e');
      if (mounted) {
        DialogHelper.showSnackBar(
          context,
          '操作失败: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }
```

**Step 4: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/pages/explore_page_favorite_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/pages/explore_page.dart test/pages/explore_page_favorite_test.dart
git commit -m "feat(ui): add favorite button to explore page music zone cards"
```

---

## Task 4: 播放历史页面添加收藏状态

**Files:**
- Modify: `frontend_flutter/lib/presentation/pages/play_history_page.dart:509-576`

**Step 1: 写失败的测试**

创建 `frontend_flutter/test/pages/play_history_favorite_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/pages/play_history_page.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayHistoryPage Favorite Integration', () {
    testWidgets('历史卡片显示收藏状态', (tester) async {
      final playlistProvider = PlaylistProvider();
      final historyProvider = PlayHistoryProvider();
      final authProvider = AuthProvider();

      // 创建测试用户
      await tester.runAsync(() async {
        await authProvider.login('test@example.com', 'password');
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: historyProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
          ],
          child: const MaterialApp(
            home: PlayHistoryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证页面加载
      expect(find.byType(PlayHistoryPage), findsOneWidget);
    });
  });
}
```

**Step 2: 运行测试验证失败**

```powershell
cd frontend_flutter
flutter test test/pages/play_history_favorite_test.dart
```

Expected: FAIL - 收藏按钮未在历史卡片中实现

**Step 3: 修改PlayHistoryPage历史卡片**

编辑 `frontend_flutter/lib/presentation/pages/play_history_page.dart`:

在 `import` 部分添加:
```dart
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
```

修改 `_buildHistoryCard` 方法，在 `trailing` 位置添加收藏按钮（第568-572行），修改为:

```dart
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 收藏按钮
              Consumer<PlaylistProvider>(
                builder: (context, playlistProvider, _) {
                  return FavoriteButton(
                    isFavorited: playlistProvider.isFavorited(item.audio.id),
                    size: 24,
                    onPressed: () => _handleFavoriteToggle(
                      context,
                      playlistProvider,
                      item,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              // 播放按钮
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () => _playHistoryItem(item),
              ),
            ],
          ),
```

添加处理方法:

```dart
  /// 处理收藏按钮点击
  Future<void> _handleFavoriteToggle(
    BuildContext context,
    PlaylistProvider playlistProvider,
    PlayHistoryItem item,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final audio = item.audio;

    final wasFavorited = playlistProvider.isFavorited(audio.id);

    try {
      await playlistProvider.toggleFavorite(
        authProvider.user!.token,
        audio.id,
        title: audio.title,
        artist: audio.artist,
        duration: audio.duration,
        coverUrl: audio.coverUrl,
      );

      if (mounted) {
        DialogHelper.showSnackBar(
          context,
          wasFavorited ? '已取消收藏' : '已添加到我喜欢',
          backgroundColor: wasFavorited ? Colors.grey : Colors.green,
        );
      }
    } catch (e) {
      AppLogger.error('PlayHistoryPage', '收藏操作失败: $e');
      if (mounted) {
        DialogHelper.showSnackBar(
          context,
          '操作失败: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }
```

**Step 4: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/pages/play_history_favorite_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/pages/play_history_page.dart test/pages/play_history_favorite_test.dart
git commit -m "feat(ui): add favorite button to play history page cards"
```

---

## Task 5: 优化收藏状态同步

**Files:**
- Modify: `frontend_flutter/lib/presentation/providers/playlist/playlist_provider.dart`

**Step 1: 写失败的测试**

```dart
// 添加到现有测试文件
test('收藏状态变更后正确更新缓存', () async {
  final provider = PlaylistProvider(dioProvider: mockDioProvider);

  // 初始状态：未收藏
  expect(provider.isFavorited('BV123'), false);

  // 模拟API返回添加成功
  when(mockDioProvider.post(
    '/playlists/favorites/toggle',
    data: anyNamed('data'),
  )).thenAnswer((_) async => {
    'success': true,
    'data': {'added': true},
  });

  await provider.toggleFavorite('token', 'BV123', title: 'Test');

  // 验证状态已更新
  expect(provider.isFavorited('BV123'), true);
});
```

**Step 2: 运行测试验证失败**

```powershell
cd frontend_flutter
flutter test test/providers/favorites/playlist_provider_test.dart
```

Expected: FAIL - 缓存更新可能有问题

**Step 3: 确保缓存更新正确**

验证 `toggleFavorite` 方法（第341-381行）中缓存更新逻辑:

```dart
  /// 切换收藏状态
  Future<bool> toggleFavorite(
    String token,
    String bvid, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    try {
      final response = await _dioProvider.post(
        '/playlists/favorites/toggle',
        data: {
          'bvid': bvid,
          if (title != null) 'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final added = data['added'] as bool? ?? data['favorited'] as bool? ?? false;

        if (added) {
          _favoritedBvids.add(bvid);
          await loadFavorites(token); // 重新加载完整列表确保同步
        } else {
          _favoritedBvids.remove(bvid);
          _favoritesItems.removeWhere((item) => item.bvid == bvid);
        }

        _saveFavoritesToLocal();
        notifyListeners(); // 确保UI更新
        return added;
      }
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('PlaylistProvider', '切换收藏失败: $e');
    }
    return false;
  }
```

**Step 4: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/providers/favorites/playlist_provider_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add lib/presentation/providers/playlist/playlist_provider.dart
git commit -m "fix(playlist): ensure favorite cache updates correctly"
```

---

## Task 6: 端到端测试

**Files:**
- Create: `frontend_flutter/test/integration/favorite_flow_test.dart`

**Step 1: 写失败的测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/app.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Favorite Flow Integration Test', () {
    testWidgets('完整收藏流程: 登录 -> 播放 -> 收藏 -> 验证状态', (tester) async {
      // 启动应用
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 1. 登录
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 2. 导航到探索页
      await tester.tap(find.text('发现'));
      await tester.pumpAndSettle();

      // 3. 点击第一个音乐项的收藏按钮
      final favoriteButton = find.byType(FavoriteButton).first;
      expect(favoriteButton, findsOneWidget);

      await tester.tap(favoriteButton);
      await tester.pumpAndSettle();

      // 4. 验证SnackBar提示
      expect(find.text('已添加到我喜欢'), findsOneWidget);

      // 5. 验证按钮状态变为已收藏
      await tester.pumpAndSettle();
      final favoritedIcon = tester.widget<Icon>(
        find.descendant(
          favoriteButton,
          find.byType(Icon),
        ),
      );
      expect(favoritedIcon.icon, Icons.favorite);
    });
  });
}
```

**Step 2: 运行测试验证失败**

```powershell
cd frontend_flutter
flutter test test/integration/favorite_flow_test.dart
```

Expected: FAIL - 需要添加key和完善流程

**Step 3: 添加必要的Widget Key**

为相关组件添加测试Key:

```dart
// 在登录相关组件添加
Key('email_field')
Key('password_field')
Key('login_button')
```

**Step 4: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/integration/favorite_flow_test.dart
```

Expected: PASS

**Step 5: 提交**

```powershell
cd frontend_flutter
git add test/integration/favorite_flow_test.dart
git commit -m "test(integration): add favorite flow e2e test"
```

---

## Task 7: 运行完整测试套件

**Step 1: 运行所有测试**

```powershell
cd frontend_flutter
flutter test
```

Expected: PASS (所有测试通过，包括新增的收藏功能测试)

**Step 2: 运行代码分析**

```powershell
cd frontend_flutter
flutter analyze
```

Expected: 0 issues

**Step 3: 提交最终版本**

```powershell
cd frontend_flutter
git add .
git commit -m "feat(favorites): complete UI layer for favorite song feature

- Add FavoriteButton widget with animation
- Add favorite button to audio info (player)
- Add favorite button to explore page cards
- Add favorite button to play history cards
- Add integration tests for favorite flow
- Ensure cache synchronization

Backend API and Provider layer already 100% complete."
```

---

## 验收标准

### 功能验证
- [ ] 播放器页面显示收藏按钮，点击可收藏当前歌曲
- [ ] 探索页面音乐卡片显示收藏状态
- [ ] 播放历史页面卡片显示收藏状态
- [ ] 收藏后显示"已添加到我喜欢"提示
- [ ] 取消收藏后显示"已取消收藏"提示
- [ ] 未登录时点击收藏提示"请先登录"
- [ ] 收藏按钮有动画效果

### 测试覆盖
- [ ] FavoriteButton单元测试: 100%
- [ ] AudioInfo集成测试: 通过
- [ ] ExplorePage集成测试: 通过
- [ ] PlayHistoryPage集成测试: 通过
- [ ] 端到端流程测试: 通过
- [ ] 全部测试套件: 通过

### 代码质量
- [ ] flutter analyze: 0 issues
- [ ] 遵循日志规范 (LOGGING_STANDARDS.md)
- [ ] 遵循注释规范 (CODE_COMMENT_STANDARDS.md)
- [ ] 所有用户操作记录日志

---

## 相关文档
- [LOGGING_STANDARDS.md](../../LOGGING_STANDARDS.md) - 日志记录规范
- [CODE_COMMENT_STANDARDS.md](../../CODE_COMMENT_STANDARDS.md) - 代码注释规范
- [CLAUDE.md](../../CLAUDE.md) - 项目开发指南

---

## 估计工作量
- Task 1: 创建通用组件 - 15分钟
- Task 2: 播放器集成 - 15分钟
- Task 3: 探索页集成 - 15分钟
- Task 4: 历史页集成 - 15分钟
- Task 5: 缓存同步优化 - 10分钟
- Task 6: E2E测试 - 20分钟
- Task 7: 验收和提交 - 10分钟

**总计**: 约100分钟 (1.5-2小时)
