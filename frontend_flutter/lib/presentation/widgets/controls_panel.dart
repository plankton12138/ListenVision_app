import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 播放控制面板组件
///
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
  Widget _buildTimeDisplay(BuildContext context, AudioProvider controller) {
    return Text(
      '${controller.position.toString().split('.')[0]} / '
      '${controller.duration.toString().split('.')[0]}',
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(BuildContext context, AudioProvider controller) {
    final durationSec = controller.duration.inSeconds;
    final positionSec = controller.position.inSeconds;

    // 确保值在有效范围内
    final safeValue = (durationSec > 0 && positionSec <= durationSec)
        ? positionSec.toDouble()
        : 0.0;

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
    return Row(
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
    );
  }
}
