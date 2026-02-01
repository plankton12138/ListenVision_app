import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放器底部操作栏
///
/// 包含收藏、添加到歌单、更多等操作按钮
class PlayerActionBar extends StatelessWidget {
  const PlayerActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<AudioMetadataProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();
    final currentId = metadataProvider.currentPlayable?.id ?? '';

    if (currentId.isEmpty) {
      return const Text(
        '暂无播放内容',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: playlistProvider.isFavorited(currentId)
              ? Icons.favorite
              : Icons.favorite_border,
          label: '收藏',
          iconColor: playlistProvider.isFavorited(currentId)
              ? Theme.of(context).colorScheme.error
              : null,
          onTap: () => _handleFavorite(context, playlistProvider, metadataProvider),
        ),
        _ActionButton(
          icon: Icons.playlist_add,
          label: '添加',
          onTap: () => _handleAddToPlaylist(context),
        ),
        _ActionButton(
          icon: Icons.more_horiz,
          label: '更多',
          onTap: () => _handleMore(context),
        ),
      ],
    );
  }

  /// 处理收藏按钮点击
  Future<void> _handleFavorite(
    BuildContext context,
    PlaylistProvider playlistProvider,
    AudioMetadataProvider metadataProvider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn || authProvider.user?.token == null) {
      if (context.mounted) {
        _showSnackBar(context, '请先登录后收藏', Colors.orange);
      }
      return;
    }

    final currentPlayable = metadataProvider.currentPlayable;
    if (currentPlayable == null) return;

    final bvid = currentPlayable.id;
    final wasFavorited = playlistProvider.isFavorited(bvid);

    AppLogger.logButtonClick(
      wasFavorited ? '取消收藏' : '收藏',
      'PlayerActionBar',
      parameters: {'bvid': bvid, 'title': currentPlayable.title},
    );

    try {
      await playlistProvider.toggleFavorite(
        authProvider.user!.token!,
        bvid,
        title: currentPlayable.title,
        artist: currentPlayable.artist,
        duration: currentPlayable.duration,
        coverUrl: currentPlayable.coverUrl,
      );

      if (context.mounted) {
        _showSnackBar(
          context,
          wasFavorited ? '已取消收藏' : '已添加到我喜欢',
          wasFavorited ? Colors.grey : Colors.green,
        );
      }
    } catch (e) {
      AppLogger.error('PlayerActionBar', '收藏操作失败: $e');
      if (context.mounted) {
        _showSnackBar(context, '操作失败: $e', Colors.red);
      }
    }
  }

  /// 处理添加到歌单
  void _handleAddToPlaylist(BuildContext context) {
    AppLogger.logButtonClick('添加到歌单', 'PlayerActionBar');
    _showSnackBar(context, '添加到歌单功能开发中', Colors.orange);
  }

  /// 处理更多选项
  void _handleMore(BuildContext context) {
    AppLogger.logButtonClick('更多选项', 'PlayerActionBar');
    _showSnackBar(context, '更多选项功能开发中', Colors.orange);
  }

  /// 显示提示消息
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
