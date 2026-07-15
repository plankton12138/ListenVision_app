import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/play_mode.dart';
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
    final hasContent = queueState.queue?.tracks.isNotEmpty ?? false;
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
        errorBuilder: (_, _, _) => _defaultIcon(context),
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
            queueState.queue?.playMode.icon ?? '',
            style: const TextStyle(fontSize: 18),
          ),
          iconSize: 36,
          visualDensity: VisualDensity.compact,
          tooltip: queueState.queue?.playMode.displayName ?? '',
          onPressed: () {
            ref.read(queueViewModelProvider.notifier).togglePlayMode();
            AppLogger.info(
              'FloatingPlayerBar',
              '切换播放模式: ${queueState.queue?.playMode.displayName ?? ''}',
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
