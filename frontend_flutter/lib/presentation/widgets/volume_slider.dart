import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';

/// 音量滑块组件
///
/// 允许用户调节播放音量（0.0 - 1.0，即 0% - 100%）
class VolumeSlider extends StatelessWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, child) {
        final volumePercent = (provider.volume * 100).toInt();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 音量减小图标
            const Icon(Icons.volume_down, size: 20),
            const SizedBox(width: 8),

            // 音量滑块
            SizedBox(
              width: 120,
              child: Slider(
                value: provider.volume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '$volumePercent%',
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  provider.setVolume(value);
                },
              ),
            ),

            const SizedBox(width: 8),

            // 音量增大图标
            const Icon(Icons.volume_up, size: 20),
            const SizedBox(width: 4),

            // 音量百分比文本
            Text(
              '$volumePercent%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
