import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/audio_provider.dart';
import 'package:demo/providers/auth_provider.dart';
import 'package:demo/providers/playlist_provider.dart';
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
        _buildAudioInfo(context, provider),
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
  Widget _buildAudioInfo(BuildContext context, AudioProvider controller) {
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
        const SizedBox(height: 8),
        _buildFavoriteButton(context, controller),
      ],
    );
  }

  /// 构建收藏按钮
  Widget _buildFavoriteButton(BuildContext context, AudioProvider controller) {
    final authProvider = context.watch<AuthProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();

    // 获取当前音频的 url
    final audioUrl = controller.currentAudio?.url;

    // 只有来自 B站的音频才显示收藏按钮（url 包含 bilibili 或 BV）
    if (audioUrl == null || !audioUrl.contains('bilibili')) {
      return const SizedBox.shrink();
    }

    // 从 url 中提取 bvid（格式如: https://www.bilibili.com/video/BV1xx411c7mD）
    String bvid = '';
    final bvidMatch = RegExp(r'BV[\w]{10}').firstMatch(audioUrl);
    if (bvidMatch != null) {
      bvid = bvidMatch.group(0) ?? '';
    }

    if (bvid.isEmpty) {
      return const SizedBox.shrink();
    }

    final isFavorited = playlistProvider.isFavorited(bvid);

    // 获取音频元数据用于收藏
    final title = controller.title;
    final artist = controller.artist;
    final duration = controller.duration.inSeconds;

    return IconButton(
      icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
      color: isFavorited ? Colors.red : Colors.grey,
      iconSize: 28,
      onPressed: () async {
        if (!authProvider.isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先登录')),
          );
          return;
        }

        try {
          final token = authProvider.user!.token;
          final added = await playlistProvider.toggleFavorite(
            token,
            bvid,
            title: title,
            artist: artist,
            duration: duration,
          );

          // 显示反馈（不使用 mounted，因为是在 build 内部调用的 onPressed）
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(added ? '已添加到我喜欢' : '已从我喜欢移除'),
              duration: const Duration(seconds: 1),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }
}
