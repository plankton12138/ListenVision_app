import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 音频信息显示组件
///
/// 显示当前播放音频的封面图、标题和艺术家信息
class AudioInfo extends StatelessWidget {
  const AudioInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 专辑封面
        _buildAlbumArt(context, provider),
        // 音频信息（标题、艺术家）
        _buildAudioInfo(provider),
      ],
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumArt(BuildContext context, AudioProvider controller) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 300,
      decoration: BoxDecoration(
        image: controller.albumArt != null
            ? DecorationImage(
                image: MemoryImage(controller.albumArt!),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              )
            : const DecorationImage(
                image: AssetImage('assets/images/default_album_art.png'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
      ),
    );
  }

  /// 构建音频信息（标题和艺术家）
  Widget _buildAudioInfo(AudioProvider controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),
        Text(
          controller.title,
          style: const TextStyle(
            fontSize: Dimens.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          controller.artist,
          style: const TextStyle(
            fontSize: Dimens.fontSizeSmall,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
