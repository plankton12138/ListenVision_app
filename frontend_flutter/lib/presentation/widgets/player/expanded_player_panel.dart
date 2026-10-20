import 'package:listenvision/core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listenvision/models/play_mode.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/widgets/player_action_bar.dart';
import 'package:listenvision/presentation/widgets/player/queue_bottom_sheet.dart';
import '../common/marquee_text.dart';

/// 全屏播放面板
///
/// 从 FloatingPlayerBar 点击展开，提供完整播放控制。
/// 通过 showModalBottomSheet(isScrollControlled: true) 展开。
class ExpandedPlayerPanel extends ConsumerWidget {
  const ExpandedPlayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackControlsProvider);
    final queueState = ref.watch(queueViewModelProvider);

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
              Consumer(
                builder: (context, ref, _) => _buildProgressSection(
                  context,
                  ref.watch(playbackViewModelProvider),
                  ref,
                ),
              ),
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
      coverWidget = ImageHelper.networkImage(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _defaultCover(context),
      );
    } else {
      coverWidget = _defaultCover(context);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: 270, height: 270, child: coverWidget),
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
        MarqueeText(
          state.errorMessage != null ? '播放失败' : state.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        if (state.albumTitle != null && state.albumTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: MarqueeText(
              state.albumTitle!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                    0.0,
                    1.0,
                  )
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
                hasValidDuration ? duration.toString().split('.')[0] : '--:--',
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
            queueState.queue?.playMode.icon ?? '',
            style: const TextStyle(fontSize: 24),
          ),
          iconSize: 48,
          tooltip: queueState.queue?.playMode.displayName ?? '',
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
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
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
    final queueCount = queueState.queue?.tracks.length ?? 0;

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
