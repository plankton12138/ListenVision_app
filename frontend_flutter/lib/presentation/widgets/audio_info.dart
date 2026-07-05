import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/widgets/player/queue_bottom_sheet.dart';

/// 音频信息显示组件
///
/// 显示当前播放音频的封面图、标题和艺术家信息
class AudioInfo extends ConsumerWidget {
  const AudioInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playbackViewModelProvider);

    return GestureDetector(
      onTap: () {
        AppLogger.logButtonClick('歌曲信息区', 'AudioInfo');
        QueueBottomSheet.show(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 专辑封面 - 自适应高度
          Flexible(
            child: _buildAlbumArt(context, playerState),
          ),
          // 音频信息（标题、艺术家）
          _buildAudioInfo(context, playerState),
        ],
      ),
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumArt(BuildContext context, playerState) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: _buildAlbumArtContent(context, playerState),
    );
  }

  /// 构建封面内容（支持本地和网络）
  ///
  /// 优先级：
  /// 1. 本地音频封面 (Uint8List)
  /// 2. 在线音频封面（通过代理URL）
  /// 3. 默认封面图片
  Widget _buildAlbumArtContent(BuildContext context, playerState) {
    // 优先级1: 本地音频封面 (Uint8List)
    if (playerState.coverData != null) {
      return Image.memory(
        playerState.coverData!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.error('AudioInfo', '本地封面解析失败: $error');
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/default_album_art.png'),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      );
    }

    // 优先级2: 在线音频封面 (使用代理解决防盗链)
    final coverUrl = playerState.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final proxyUrl = _buildProxyImageUrl(coverUrl);

      return Image.network(
        proxyUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 网络加载失败时使用默认图片
          AppLogger.error('AudioInfo', '封面加载失败: $error');
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/default_album_art.png'),
                fit: BoxFit.contain,
              ),
            ),
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

  /// 返回图片URL（纯前端架构：直接使用原始URL）
  String _buildProxyImageUrl(String originalUrl) {
    return originalUrl;
  }


  /// 构建音频信息（三行：标题 / 副标题 / 艺术家）
  Widget _buildAudioInfo(BuildContext context, playerState) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第1行：主标题（分集名/视频标题）— 最大最粗
          Text(
            playerState.title,
            style: const TextStyle(
              fontSize: UIConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          // 第2行：副标题（仅分P音频）— 小字灰色
          if (playerState.albumTitle != null && playerState.albumTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                playerState.albumTitle!,
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeSmall,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

          const SizedBox(height: 4),

          // 第3行：作者（artist/UP主）— 主题色 + 斜体
          Text(
            playerState.artist.isNotEmpty ? playerState.artist : '未知艺术家',
            style: TextStyle(
              fontSize: UIConstants.fontSizeSmall,
              color: primaryColor,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
