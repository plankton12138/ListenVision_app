import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/widgets/volume_slider.dart';
import 'package:demo/presentation/widgets/speed_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 播放控制面板组件
///
/// Phase 5: 更新为使用 just_audio 精确状态检测
/// 显示播放进度、时间显示和控制按钮（上一曲、播放/暂停、下一曲）
class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 时间显示（当前位置/总时长）
        _buildTimeDisplay(context, provider),
        // 进度条
        _buildProgressBar(context, provider),
        // 控制按钮
        _buildControlButtons(context, provider),
      ],
    );
  }

  /// 构建时间显示
  /// Phase 5: 使用 just_audio 精确状态检测
  /// ✅ UX改进：优先显示用户友好的状态消息和错误提示
  Widget _buildTimeDisplay(BuildContext context, AudioProvider controller) {
    // ✅ UX改进：优先显示错误状态（最优先）
    if (controller.hasPlaybackError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            controller.playerStatusMessage.isNotEmpty
                ? controller.playerStatusMessage
                : '播放失败',
            style: const TextStyle(color: Colors.red),
          ),
        ],
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

    // ✅ 精确的加载状态（来自 just_audio ProcessingState）
    if (controller.isLoading) {
      return const Text(
        '加载中...',
        style: TextStyle(color: Colors.blue),
      );
    }

    // ✅ 精确的缓冲状态（来自 just_audio ProcessingState.buffering）
    if (controller.isBuffering) {
      return const Text(
        '缓冲中...',
        style: TextStyle(color: Colors.orange),
      );
    }

    // 已完成状态
    if (controller.isCompleted) {
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

    return Text(
      '${controller.position.toString().split('.')[0]} / '
      '${controller.duration.toString().split('.')[0]}',
    );
  }

  /// 构建进度条
  /// Phase 5: 使用 just_audio 精确状态检测
  /// ✅ UX改进：在有状态消息或错误时显示友好提示
  Widget _buildProgressBar(BuildContext context, AudioProvider controller) {
    final durationSec = controller.duration.inSeconds;
    final positionSec = controller.position.inSeconds;

    // 确保值在有效范围内
    final safeValue = (durationSec > 0 && positionSec <= durationSec)
        ? positionSec.toDouble()
        : 0.0;

    // ✅ UX改进：有错误时显示重试提示
    if (controller.hasPlaybackError) {
      return SizedBox(
        height: 48,
        child: Center(
          child: TextButton.icon(
            onPressed: () {
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

    // ✅ UX改进：有状态消息时显示提示
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

    // ✅ 加载或缓冲时显示进度指示器
    // just_audio 的状态是精确的，不会误判
    if (controller.isLoading || controller.isBuffering) {
      return SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // 缓冲时显示不确定进度
              value: controller.isBuffering ? null : (durationSec > 0 ? safeValue / durationSec.toDouble() : null),
            ),
          ),
        ),
      );
    }

    return Slider(
      value: safeValue,
      min: 0,
      max: durationSec > 0 ? durationSec.toDouble() : 1.0,
      activeColor: Colors.green,
      inactiveColor: Colors.grey,
      onChanged: (value) => controller.seek(Duration(seconds: value.toInt())),
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
              onPressed: () => provider.playPrevious(),
            ),
            IconButton(
              icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 45,
              onPressed: () => provider.togglePlayPause(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 45,
              onPressed: () => provider.playNext(),
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
