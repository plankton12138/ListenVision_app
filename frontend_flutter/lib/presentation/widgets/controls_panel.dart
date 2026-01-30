import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/audio/now_playing_provider.dart';
import 'package:demo/presentation/widgets/volume_slider.dart';
import 'package:demo/presentation/widgets/speed_button.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 播放控制面板组件
///
/// Phase 5: 更新为使用 audioplayers 状态检测
/// 显示播放进度、时间显示和控制按钮（上一曲、播放/暂停、下一曲）
class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final nowPlayingProvider = context.watch<NowPlayingProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 时间显示（当前位置/总时长）
        _buildTimeDisplay(context, provider, nowPlayingProvider),
        // 进度条
        _buildProgressBar(context, provider, nowPlayingProvider),
        // 控制按钮
        _buildControlButtons(context, provider),
      ],
    );
  }

  /// 构建时间显示
  /// Phase 5: 使用 audioplayers 状态检测
  /// ✅ UX改进：优先显示用户友好的状态消息和错误提示
  /// ✅ 修复：当有有效时长和位置时优先显示时间，而不是状态
  Widget _buildTimeDisplay(
    BuildContext context,
    AudioProvider controller,
    NowPlayingProvider nowPlayingProvider,
  ) {
    final duration = controller.duration;
    final position = controller.position;
    final hasValidDuration = duration > Duration.zero;
    final hasValidPosition = position >= Duration.zero;
    final hasPlaybackProgress = hasValidPosition && (position > Duration.zero || controller.isPlaying);

    // ✅ UX改进：优先显示错误状态（最优先）
    if (controller.hasPlaybackError || nowPlayingProvider.errorMessage != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            controller.playerStatusMessage.isNotEmpty
                ? controller.playerStatusMessage
                : (nowPlayingProvider.errorMessage ?? '播放失败'),
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }

    // ✅ 修复：如果有有效的时间信息，优先显示时间（而不是状态消息）
    // 这样可以避免自动切歌后显示"播放完成"或"加载中"而不显示时间
    if (hasValidDuration && hasPlaybackProgress) {
      return Text(
        '${position.toString().split('.')[0]} / '
        '${duration.toString().split('.')[0]}',
      );
    }

    if (!hasValidDuration && hasPlaybackProgress) {
      return Text(
        '${position.toString().split('.')[0]} / --:--',
      );
    }

    // ✅ UX改进：显示状态消息（正在播放、正在加载等）
    if (controller.playerStatusMessage.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            controller.playerStatusMessage,
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      );
    }

    // ✅ 加载状态（来自 PlaybackController）
    if (controller.isLoading) {
      return const Text(
        '加载中...',
        style: TextStyle(color: Colors.blue),
      );
    }

    // ✅ 缓冲状态（audioplayers 不直接提供，通过加载状态推断）
    if (controller.isBuffering) {
      return const Text(
        '缓冲中...',
        style: TextStyle(color: Colors.orange),
      );
    }

    // 已完成状态 - 只有在没有有效时长时才显示
    if (controller.isCompleted && !hasValidDuration) {
      return const Text(
        '播放完成',
        style: TextStyle(color: Colors.green),
      );
    }

    // 空闲状态
    if (controller.isIdle) {
      return const Text(
        '就绪',
        style: TextStyle(color: Colors.grey),
      );
    }

    // 默认显示时间（即使为0）
    return Text(
      '${position.toString().split('.')[0]} / '
      '${duration.toString().split('.')[0]}',
    );
  }

  /// 构建进度条
  /// Phase 5: 使用 audioplayers 状态检测
  /// ✅ UX改进：在有状态消息或错误时显示友好提示
  /// ✅ 修复：只要有有效时长就显示进度条，而不是加载指示器
  Widget _buildProgressBar(
    BuildContext context,
    AudioProvider controller,
    NowPlayingProvider nowPlayingProvider,
  ) {
    final durationSec = controller.duration.inSeconds;
    final positionSec = controller.position.inSeconds;

    // 确保值在有效范围内
    final safeValue = (durationSec > 0 && positionSec <= durationSec)
        ? positionSec.toDouble()
        : 0.0;

    // ✅ 修复：只要有有效时长，就显示进度条（即使正在加载）
    // 这样可以避免音频已经开始播放但进度条仍显示加载中的问题
    final hasValidDuration = durationSec > 0;

    // ✅ UX改进：有错误时显示重试提示
    if (controller.hasPlaybackError || nowPlayingProvider.errorMessage != null) {
      return SizedBox(
        height: 48,
        child: Center(
          child: TextButton.icon(
            onPressed: () {
              AppLogger.logButtonClick('重试', 'ControlsPanel');
              controller.clearPlaybackError();
              controller.togglePlayPause();
            },
            icon: const Icon(Icons.refresh, color: Colors.blue),
            label: const Text(
              '点击重试',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      );
    }

    // ✅ 修复：如果有有效时长，显示进度条（优先于状态消息和加载状态）
    if (hasValidDuration) {
      return Slider(
        value: safeValue,
        min: 0,
        max: durationSec.toDouble(),
        activeColor: Colors.green,
        inactiveColor: Colors.grey,
        onChanged: (value) {
          AppLogger.logButtonClick('进度条', 'ControlsPanel',
            parameters: {'position': value.toInt()});
          controller.seek(Duration(seconds: value.toInt()));
        },
      );
    }

    // ✅ UX改进：有状态消息时显示提示（没有有效时长时）
    if (controller.playerStatusMessage.isNotEmpty) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // ✅ 加载或缓冲时显示进度指示器（没有有效时长时）
    if (controller.isLoading || controller.isBuffering) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
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
  Widget _buildControlButtons(BuildContext context, AudioProvider provider) {
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
                provider.playPrevious();
              },
            ),
            IconButton(
              icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick(
                  provider.isPlaying ? '暂停' : '播放',
                  'ControlsPanel',
                );
                provider.togglePlayPause();
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 45,
              onPressed: () {
                AppLogger.logButtonClick('下一首', 'ControlsPanel');
                provider.playNext();
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
