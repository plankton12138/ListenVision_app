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
  Widget _buildTimeDisplay(BuildContext context, AudioProvider controller) {
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
  Widget _buildProgressBar(BuildContext context, AudioProvider controller) {
    final durationSec = controller.duration.inSeconds;
    final positionSec = controller.position.inSeconds;

    // 确保值在有效范围内
    final safeValue = (durationSec > 0 && positionSec <= durationSec)
        ? positionSec.toDouble()
        : 0.0;

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
