import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 音频信息显示组件
///
/// 显示当前播放音频的封面图、标题和艺术家信息
class AudioInfo extends StatelessWidget {
  const AudioInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioMetadataProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 专辑封面
        _buildAlbumArt(context, provider),
        // 音频信息（标题、艺术家）
        _buildAudioInfo(context, provider),
      ],
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumArt(BuildContext context, AudioMetadataProvider controller) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 300,
      child: _buildAlbumArtContent(context, controller),
    );
  }

  /// 构建封面内容（支持本地和网络）
  Widget _buildAlbumArtContent(BuildContext context, AudioMetadataProvider controller) {
    // 优先级1: 本地音频封面 (Uint8List)
    if (controller.albumArt != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(controller.albumArt!),
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      );
    }

    // 优先级2: 在线音频封面 (使用代理解决防盗链)
    final coverUrl = controller.currentPlayable?.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final bilibiliProvider = context.read<BilibiliProvider>();
      final proxyUrl = bilibiliProvider.getProxyImageUrl(coverUrl);

      return Image.network(
        proxyUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 网络加载失败时使用默认图片
          AppLogger.error('AudioInfo', '封面加载失败: $error');
          return Image.asset(
            'assets/images/default_album_art.png',
            fit: BoxFit.contain,
          );
        },
      );
    }

    // 优先级3: 默认图片
    return Image.asset(
      'assets/images/default_album_art.png',
      fit: BoxFit.contain,
    );
  }

  /// 构建音频信息（标题和艺术家）
  Widget _buildAudioInfo(BuildContext context, AudioMetadataProvider controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),
        Text(
          controller.title,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          controller.artist,
          style: const TextStyle(
            fontSize: UIConstants.fontSizeSmall,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
