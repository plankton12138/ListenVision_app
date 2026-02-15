import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/presentation/providers.dart';

/// 音量滑块组件
///
/// 允许用户调节播放音量（0.0 - 1.0，即 0% - 100%）
class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerViewModelProvider);
    final volume = playerState.volume;
    final volumePercent = (volume * 100).toInt();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 音量减小图标
        const Icon(Icons.remove, size: 20),
        const SizedBox(width: 8),

        // 音量滑块
        SizedBox(
          width: 120,
          child: Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '$volumePercent%',
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              ref.read(playerViewModelProvider.notifier).setVolume(value);
            },
          ),
        ),

        const SizedBox(width: 8),

        // 音量增大图标
        const Icon(Icons.add, size: 20),
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
  }
}
