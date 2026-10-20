import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listenvision/presentation/widgets/volume_slider.dart';
import 'package:listenvision/presentation/widgets/speed_button.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/presentation/providers.dart';

/// 播放控制面板组件
///
/// 显示播放进度、时间显示和控制按钮（上一曲、播放/暂停、下一曲）
class ControlsPanel extends ConsumerWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playbackControlsProvider);
    final playerViewModel = ref.read(playbackViewModelProvider.notifier);

    // 无播放内容时显示提示
    if (playerState.currentPlayable == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            '暂无播放内容',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 时间显示（当前位置/总时长）
        Consumer(
          builder: (context, ref, _) =>
              _buildTimeDisplay(context, ref.watch(playbackViewModelProvider)),
        ),
        // 进度条
        Consumer(
          builder: (context, ref, _) => _buildProgressBar(
            context,
            ref.watch(playbackViewModelProvider),
            playerViewModel,
          ),
        ),
        // 控制按钮
        _buildControlButtons(context, ref, playerState, playerViewModel),
      ],
    );
  }

  /// 播放上一首
  void _playPrevious(BuildContext context, WidgetRef ref) {
    final playbackNotifier = ref.read(playbackViewModelProvider.notifier);
    playbackNotifier.previous();
  }

  /// 播放下一首
  void _playNext(BuildContext context, WidgetRef ref) {
    final playbackNotifier = ref.read(playbackViewModelProvider.notifier);
    playbackNotifier.next();
  }

  /// 构建时间显示
  ///
  /// 优先显示用户友好的状态消息和错误提示
  /// 当有有效时长和位置时优先显示时间，而不是状态
  Widget _buildTimeDisplay(BuildContext context, playerState) {
    final duration = playerState.duration ?? Duration.zero;
    final position = playerState.position;
    final hasValidDuration = duration > Duration.zero;
    final hasValidPosition = position >= Duration.zero;
    final hasPlaybackProgress =
        hasValidPosition && (position > Duration.zero || playerState.isPlaying);

    // UX改进：优先显示错误状态（最优先）
    if (playerState.errorMessage != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            playerState.errorMessage!.isNotEmpty
                ? playerState.errorMessage!
                : '播放失败',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }

    // 修复：如果有有效的时间信息，优先显示时间（而不是状态消息）
    // 这样可以避免自动切歌后显示"播放完成"或"加载中"而不显示时间
    if (hasValidDuration && hasPlaybackProgress) {
      return Text(
        '${position.toString().split('.')[0]} / '
        '${duration.toString().split('.')[0]}',
      );
    }

    if (!hasValidDuration && hasPlaybackProgress) {
      return Text('${position.toString().split('.')[0]} / --:--');
    }

    // 加载状态（来自 PlaybackController）
    if (playerState.isLoading) {
      return const Text('加载中...', style: TextStyle(color: Colors.blue));
    }

    // 已完成状态 - 只有在没有有效时长时才显示
    if (playerState.isCompleted && !hasValidDuration) {
      return const Text('播放完成', style: TextStyle(color: Colors.green));
    }

    // 空闲状态
    if (playerState.currentPlayable == null) {
      return const Text('就绪', style: TextStyle(color: Colors.grey));
    }

    // 默认显示时间（即使为0）
    return Text(
      '${position.toString().split('.')[0]} / '
      '${duration.toString().split('.')[0]}',
    );
  }

  /// 构建进度条
  ///
  /// 在有状态消息或错误时显示友好提示
  /// 只要有有效时长就显示进度条，而不是加载指示器
  Widget _buildProgressBar(BuildContext context, playerState, playerViewModel) {
    final duration = playerState.duration ?? Duration.zero;
    final durationSec = duration.inSeconds;
    final positionSec = playerState.position.inSeconds;

    // 确保值在有效范围内
    final safeValue = (durationSec > 0 && positionSec <= durationSec)
        ? positionSec.toDouble()
        : 0.0;

    // 修复：只要有有效时长，就显示进度条（即使正在加载）
    // 这样可以避免音频已经开始播放但进度条仍显示加载中的问题
    final hasValidDuration = durationSec > 0;

    // UX改进：有错误时显示重试提示
    if (playerState.errorMessage != null) {
      return SizedBox(
        height: 48,
        child: Center(
          child: TextButton.icon(
            onPressed: () {
              AppLogger.logButtonClick('重试', 'ControlsPanel');
              // 重试播放当前音频
              if (playerState.currentPlayable != null) {
                playerViewModel.play(playerState.currentPlayable!);
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.blue),
            label: const Text('点击重试', style: TextStyle(color: Colors.blue)),
          ),
        ),
      );
    }

    // 修复：如果有有效时长，显示进度条（优先于状态消息和加载状态）
    if (hasValidDuration) {
      return Slider(
        value: safeValue,
        min: 0,
        max: durationSec.toDouble(),
        activeColor: Colors.green,
        inactiveColor: Colors.grey,
        onChanged: (value) {
          AppLogger.logButtonClick(
            '进度条',
            'ControlsPanel',
            parameters: {'position': value.toInt()},
          );
          playerViewModel.seek(Duration(seconds: value.toInt()));
        },
      );
    }

    // 加载时显示进度指示器（没有有效时长时）
    if (playerState.isLoading) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 默认显示不可用的进度条
    return Slider(
      value: 0,
      min: 0,
      max: 1.0,
      activeColor: Colors.green,
      inactiveColor: Colors.grey,
      onChanged: null,
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(
    BuildContext context,
    WidgetRef ref,
    playerState,
    playerViewModel,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：播放控制按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick('上一首', 'ControlsPanel');
                _playPrevious(context, ref);
              },
            ),
            IconButton(
              icon: Icon(
                playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick(
                  playerState.isPlaying ? '暂停' : '播放',
                  'ControlsPanel',
                );
                playerViewModel.togglePlayPause();
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick('下一首', 'ControlsPanel');
                _playNext(context, ref);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 第二行：Phase 3B 播放控制（音量和倍速）
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            // 音量滑块
            VolumeSlider(),

            SizedBox(width: 24),

            // 倍速按钮
            SpeedButton(),
          ],
        ),
      ],
    );
  }
}
