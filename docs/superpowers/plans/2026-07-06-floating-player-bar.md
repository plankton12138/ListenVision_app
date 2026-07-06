# 浮动播放条 & 全屏播放面板 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在任意非 HomePage 页面底部显示浮动播放条，支持基础播放控制和全屏展开面板，不修改任何现有 ViewModel 或路由。

**Architecture:** 在 `app.dart` 的 `MaterialApp.router.builder` 中用 `Stack` 叠加浮动播放条。浮动条和全屏面板作为 `ConsumerWidget`，直接读取 `playbackViewModelProvider` 和 `queueViewModelProvider`。零侵入：不改路由、不改 HomePage、不提取公共组件。

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Riverpod 3.0 (code-gen), go_router, media_kit

## Global Constraints

- 使用 provider 名称: `playbackViewModelProvider`, `queueViewModelProvider`（来自 `providers.dart` 统一导出）
- `PlayMode` 枚举值: `sequence`, `loopAll`, `shuffle`, `loopOne`，带 `displayName`/`icon`/`next()` 扩展
- 时间格式化: `Duration.toString().split('.')[0]`
- 日志规范: `AppLogger.info/debug('ClassName', 'message')`，使用 `import 'package:listenvision/core/utils/app_logger.dart'`
- 所有 import 使用 `package:listenvision/...` 绝对路径
- 文件使用 Unix (LF) 行尾

---

### Task 1: 修改 app.dart — 添加 Stack 包裹层

**Files:**
- Modify: `frontend_flutter/lib/app.dart:68-70`

**Interfaces:**
- Consumes: GoRouter `routerConfig`（已存在于 `app.dart`）
- Produces: GoRouter 的 `child` 与 `FloatingPlayerBar` 在 Stack 中叠放；`FloatingPlayerBar` 通过 `GoRouterState.of(context)` 获取当前路由

- [ ] **Step 1: 修改 builder 方法，用 Stack 包裹 child**

在 `app.dart` 的 `builder` 中，将当前直接返回 `NetworkStatusListener` 改为 `Stack` 包裹：

```dart
builder: (context, child) {
  return Stack(
    children: [
      // GoRouter 页面内容
      NetworkStatusListener(child: child ?? const SizedBox()),
      // 浮动播放条（覆盖在底部）
      const Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: FloatingPlayerBar(),
      ),
    ],
  );
},
```

需要在文件顶部添加 import：
```dart
import 'presentation/widgets/player/floating_player_bar.dart';
```

- [ ] **Step 2: 运行静态分析确认无编译错误**

```bash
cd frontend_flutter && flutter analyze lib/app.dart
```
Expected: 可能报 `FloatingPlayerBar` 未定义（因为还未创建），确认仅此错误无其他问题后继续。

- [ ] **Step 3: 暂存（等 Task 2 完成后一起提交）**

---

### Task 2: 创建浮动播放条 — FloatingPlayerBar

**Files:**
- Create: `frontend_flutter/lib/presentation/widgets/player/floating_player_bar.dart`

**Interfaces:**
- Consumes: `playbackViewModelProvider` → `PlaybackState`（title, artist, coverData, coverUrl, isPlaying, isLoading, position, duration, errorMessage）; `queueViewModelProvider` → `QueueState`（queue, playMode）
- Produces: `class FloatingPlayerBar extends ConsumerWidget` — 无构造参数
- 触发: `showModalBottomSheet` → `ExpandedPlayerPanel()`（Task 3）

- [ ] **Step 1: 创建文件并编写核心布局**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/presentation/providers.dart';

import 'expanded_player_panel.dart';

/// 浮动底部播放条
///
/// 在所有非 HomePage 页面底部显示当前播放信息和基础控制。
/// 空队列或 HomePage 时自动隐藏。
class FloatingPlayerBar extends ConsumerWidget {
  const FloatingPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);
    final playbackState = ref.watch(playbackViewModelProvider);

    // 显示条件：有播放内容 && 不在 HomePage && 键盘未弹出
    final hasContent = queueState.queue.isNotEmpty;
    final location = GoRouterState.of(context).uri.toString();
    final isHomePage = location == '/';
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isVisible = hasContent && !isHomePage && !keyboardVisible;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度条
            _ProgressIndicator(playbackState: playbackState),
            // 主体
            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 4,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    // 左侧：封面 + 信息
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openExpandedPanel(context),
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! < -100) {
                            _openExpandedPanel(context);
                          }
                        },
                        child: _TrackInfo(playbackState: playbackState),
                      ),
                    ),
                    // 右侧：控制按钮
                    _ControlButtons(
                      playbackState: playbackState,
                      queueState: queueState,
                      ref: ref,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _openExpandedPanel(BuildContext context) {
    AppLogger.debug('FloatingPlayerBar', '打开全屏播放面板');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const ExpandedPlayerPanel(),
    );
  }
}

/// 进度指示条（2px 高线性渐变）
class _ProgressIndicator extends StatelessWidget {
  final PlaybackState playbackState;
  const _ProgressIndicator({required this.playbackState});

  @override
  Widget build(BuildContext context) {
    final duration = playbackState.duration;
    if (duration == null || duration <= Duration.zero) {
      return const SizedBox.shrink();
    }

    final progress = (playbackState.position.inMilliseconds /
            duration.inMilliseconds)
        .clamp(0.0, 1.0);

    return SizedBox(
      height: 2,
      width: double.infinity,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 曲目信息（封面缩略图 + 标题 + 作者）
class _TrackInfo extends StatelessWidget {
  final PlaybackState playbackState;
  const _TrackInfo({required this.playbackState});

  @override
  Widget build(BuildContext context) {
    final title = playbackState.title;
    final artist = playbackState.artist;
    final hasError = playbackState.errorMessage != null;
    final isLoading = playbackState.isLoading;

    return Row(
      children: [
        // 封面缩略图
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 40,
            child: _buildCover(context),
          ),
        ),
        const SizedBox(width: 10),
        // 标题 + 作者
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasError ? '播放失败' : (isLoading ? '加载中...' : title),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasError ? Colors.red : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (artist != '未知艺术家' && !hasError && !isLoading)
                Text(
                  artist,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCover(BuildContext context) {
    final coverData = playbackState.coverData;
    final coverUrl = playbackState.coverUrl;

    if (coverData != null) {
      return Image.memory(coverData, fit: BoxFit.cover);
    }
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return Image.network(coverUrl, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultIcon(context),
      );
    }
    return _defaultIcon(context);
  }

  Widget _defaultIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        size: 24,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 控制按钮组
class _ControlButtons extends StatelessWidget {
  final PlaybackState playbackState;
  final QueueState queueState;
  final WidgetRef ref;
  const _ControlButtons({
    required this.playbackState,
    required this.queueState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playbackState.isPlaying;
    final isLoading = playbackState.isLoading;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 播放模式切换
        IconButton(
          icon: Text(
            queueState.playMode.icon,
            style: const TextStyle(fontSize: 18),
          ),
          iconSize: 36,
          visualDensity: VisualDensity.compact,
          tooltip: queueState.playMode.displayName,
          onPressed: () {
            ref.read(queueViewModelProvider.notifier).togglePlayMode();
            AppLogger.info(
              'FloatingPlayerBar',
              '切换播放模式: ${queueState.playMode.displayName}',
            );
          },
        ),
        // 上一首
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 36,
          visualDensity: VisualDensity.compact,
          tooltip: '上一首',
          onPressed: () {
            ref.read(playbackViewModelProvider.notifier).previous();
          },
        ),
        // 播放/暂停
        IconButton(
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          iconSize: 36,
          visualDensity: VisualDensity.compact,
          tooltip: isPlaying ? '暂停' : '播放',
          onPressed: () {
            ref.read(playbackViewModelProvider.notifier).togglePlayPause();
          },
        ),
        // 下一首
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 36,
          visualDensity: VisualDensity.compact,
          tooltip: '下一首',
          onPressed: () {
            ref.read(playbackViewModelProvider.notifier).next();
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 运行静态分析**

```bash
cd frontend_flutter && flutter analyze lib/presentation/widgets/player/floating_player_bar.dart
```
Expected: 可能报 `ExpandedPlayerPanel` 未定义（Task 3 创建），确认仅此错误无其他问题。

---

### Task 3: 创建全屏播放面板 — ExpandedPlayerPanel

**Files:**
- Create: `frontend_flutter/lib/presentation/widgets/player/expanded_player_panel.dart`

**Interfaces:**
- Consumes: `playbackViewModelProvider` → `PlaybackState`; `queueViewModelProvider` → `QueueState`; `PlayerActionBar`（直接复用 import）; `QueueBottomSheet`（import + `showModalBottomSheet`）
- Produces: `class ExpandedPlayerPanel extends ConsumerWidget` — 无构造参数，用于 `showModalBottomSheet` 的 builder
- 导出: `import 'package:listenvision/presentation/widgets/player/expanded_player_panel.dart'`

- [ ] **Step 1: 创建文件并编写核心布局**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/widgets/player_action_bar.dart';
import 'package:listenvision/presentation/widgets/player/queue_bottom_sheet.dart';

/// 全屏播放面板
///
/// 从 FloatingPlayerBar 点击展开，提供完整播放控制。
/// 通过 showModalBottomSheet(isScrollControlled: true) 展开。
class ExpandedPlayerPanel extends ConsumerWidget {
  const ExpandedPlayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackViewModelProvider);
    final queueState = ref.watch(queueViewModelProvider);

    final hasValidDuration =
        playbackState.duration != null &&
        playbackState.duration! > Duration.zero;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // 1. AppBar: 返回箭头
              _buildAppBar(context),
              const SizedBox(height: 24),
              // 2. 封面大图
              _buildCover(context, playbackState),
              const SizedBox(height: 24),
              // 3. 曲目信息
              _buildTrackTitle(context, playbackState),
              const SizedBox(height: 16),
              // 4. 进度条
              _buildProgressSection(context, playbackState, ref),
              const SizedBox(height: 8),
              // 5. 控制按钮
              _buildControls(context, playbackState, queueState, ref),
              const SizedBox(height: 16),
              // 6. 操作栏（复用 PlayerActionBar）
              const PlayerActionBar(),
              const SizedBox(height: 16),
              // 7. 底部入口
              _buildBottomEntries(context, queueState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar: 仅返回箭头
  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '收起',
        ),
      ],
    );
  }

  /// 封面大图 (270×270, 圆角 16)
  Widget _buildCover(BuildContext context, PlaybackState state) {
    final coverData = state.coverData;
    final coverUrl = state.coverUrl;

    Widget coverWidget;
    if (coverData != null) {
      coverWidget = Image.memory(coverData, fit: BoxFit.cover);
    } else if (coverUrl != null && coverUrl.isNotEmpty) {
      coverWidget = Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultCover(context),
      );
    } else {
      coverWidget = _defaultCover(context);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 270,
          height: 270,
          child: coverWidget,
        ),
      ),
    );
  }

  Widget _defaultCover(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        size: 80,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 曲目信息: 标题 + albumTitle
  Widget _buildTrackTitle(BuildContext context, PlaybackState state) {
    return Column(
      children: [
        Text(
          state.errorMessage != null ? '播放失败' : state.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (state.albumTitle != null && state.albumTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.albumTitle!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// 进度条 + 时间显示
  Widget _buildProgressSection(
    BuildContext context,
    PlaybackState state,
    WidgetRef ref,
  ) {
    final duration = state.duration ?? Duration.zero;
    final position = state.position;
    final hasValidDuration = duration > Duration.zero;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: hasValidDuration
                ? (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0,
            onChanged: hasValidDuration
                ? (value) {
                    final seekPos = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    ref.read(playbackViewModelProvider.notifier).seek(seekPos);
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position.toString().split('.')[0],
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              Text(
                hasValidDuration
                    ? duration.toString().split('.')[0]
                    : '--:--',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 控制按钮行: 播放模式 / 上一首 / 播放暂停 / 下一首
  Widget _buildControls(
    BuildContext context,
    PlaybackState state,
    QueueState queueState,
    WidgetRef ref,
  ) {
    final isPlaying = state.isPlaying;
    final isLoading = state.isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 播放模式
        IconButton(
          icon: Text(
            queueState.playMode.icon,
            style: const TextStyle(fontSize: 24),
          ),
          iconSize: 48,
          tooltip: queueState.playMode.displayName,
          onPressed: () {
            ref.read(queueViewModelProvider.notifier).togglePlayMode();
          },
        ),
        // 上一首
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 48,
          tooltip: '上一首',
          onPressed: () {
            ref.read(playbackViewModelProvider.notifier).previous();
          },
        ),
        // 播放/暂停
        IconButton(
          icon: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          iconSize: 48,
          tooltip: isPlaying ? '暂停' : '播放',
          onPressed: () {
            ref.read(playbackViewModelProvider.notifier).togglePlayPause();
          },
        ),
        // 下一首
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 48,
          tooltip: '下一首',
          onPressed: () {
            ref.read(playbackViewModelProvider.notifier).next();
          },
        ),
      ],
    );
  }

  /// 底部入口: 播放列表 / 播放历史
  Widget _buildBottomEntries(BuildContext context, QueueState queueState) {
    final queueCount = queueState.queue.length;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.queue_music_rounded),
          title: Text('播放列表 ($queueCount)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).pop();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QueueBottomSheet(),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: const Text('播放历史'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).pop();
            context.go('/history');
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 运行静态分析**

```bash
cd frontend_flutter && flutter analyze
```
Expected: 无错误（Task 1~3 全部完成后的零错误）

**Expected result from step 2:**
```
Analyzing frontend_flutter...
No issues found! (ran in X,XXXms)
```

- [ ] **Step 3: 编译测试**

```bash
cd frontend_flutter && flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 4: 提交**

```bash
git add frontend_flutter/lib/app.dart
git add frontend_flutter/lib/presentation/widgets/player/floating_player_bar.dart
git add frontend_flutter/lib/presentation/widgets/player/expanded_player_panel.dart
git commit -m "feat: 添加浮动播放条和全屏播放面板

- 在非HomePage页面底部显示浮动播放条，支持播放/暂停/上下首/模式切换
- 点击浮动条展开全屏播放面板（ModalBottomSheet），包含完整控制
- 空队列或键盘弹出时自动隐藏浮动条"
```

---

### Dependency Order

```
Task 1 (app.dart Stack) ──┐
                          ├── 互不依赖，可并行
Task 2 (FloatingPlayerBar)┤
                          │   但 Task 1 import Task 2，建议先完成 2 再 1
Task 3 (ExpandedPlayerPanel) ── 依赖 Task 2（import 关系）
```

**推荐执行顺序：Task 2 → Task 1 → Task 3**

Task 2 先创建 FloatingPlayerBar 文件 → Task 1 的 import 才合法 → Task 3 创建 ExpandedPlayerPanel → 全部完成零错误。
