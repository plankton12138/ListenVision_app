import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:demo/presentation/providers.dart';

/// 播放器底部操作栏
///
/// 包含收藏、添加到歌单、更多等操作按钮
class PlayerActionBar extends ConsumerWidget {
  const PlayerActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerViewModel = ref.watch(playerViewModelProvider);
    final playlistViewModel = ref.watch(playlistViewModelProvider);

    final playerState = playerViewModel.playerState;
    final currentId = playerState.currentPlayable?.id ?? '';

    if (currentId.isEmpty) {
      return const Text(
        '暂无播放内容',
        style: TextStyle(color: Colors.grey),
      );
    }

    final playlistState = playlistViewModel.playlistState;
    final isFavorited = playlistState.maybeWhen(
      loaded: (_, __, ___, ____, _____, favoritesItems, ______) {
        return favoritesItems.any((item) => item.bvid == currentId);
      },
      orElse: () => false,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: isFavorited ? Icons.favorite : Icons.favorite_border,
          label: '收藏',
          iconColor: isFavorited ? Theme.of(context).colorScheme.error : null,
          onTap: () => _handleFavorite(context, ref),
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
  ///
  /// 切换当前播放歌曲的收藏状态。
  Future<void> _handleFavorite(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final authViewModel = ref.read(authViewModelProvider);
    final playlistViewModel = ref.read(playlistViewModelProvider);
    final playerViewModel = ref.read(playerViewModelProvider);

    if (!authViewModel.isLoggedIn) {
      if (context.mounted) {
        _showSnackBar(context, '请先登录后收藏', Colors.orange);
      }
      return;
    }

    final currentPlayable = playerViewModel.playerState.currentPlayable;
    if (currentPlayable == null) return;

    final token = authViewModel.currentToken;
    if (token == null) {
      if (context.mounted) {
        _showSnackBar(context, '请先登录后收藏', Colors.orange);
      }
      return;
    }

    final bvid = currentPlayable.id;

    AppLogger.logButtonClick(
      '收藏',
      'PlayerActionBar',
      parameters: {'bvid': bvid, 'title': currentPlayable.title},
    );

    try {
      await playlistViewModel.toggleFavorite(
        token,
        bvid,
        title: currentPlayable.title,
        artist: currentPlayable.artist,
        duration: currentPlayable.duration,
        coverUrl: currentPlayable.coverUrl,
      );

      if (!context.mounted) return;

      // 刷新收藏列表
      await playlistViewModel.loadFavorites(token);
      _showSnackBar(
        context,
        '已添加到我喜欢',
        Colors.green,
      );
    } catch (e) {
      AppLogger.error('PlayerActionBar', '收藏操作失败: $e');
      if (context.mounted) {
        _showSnackBar(context, '操作失败: $e', Colors.red);
      }
    }
  }

  /// 处理添加到歌单
  ///
  /// 显示开发中的功能提示。
  void _handleAddToPlaylist(BuildContext context) {
    AppLogger.logButtonClick('添加到歌单', 'PlayerActionBar');
    _showSnackBar(context, '添加到歌单功能开发中', Colors.orange);
  }

  /// 处理更多选项
  ///
  /// 显示开发中的功能提示。
  void _handleMore(BuildContext context) {
    AppLogger.logButtonClick('更多选项', 'PlayerActionBar');
    _showSnackBar(context, '更多选项功能开发中', Colors.orange);
  }

  /// 显示提示消息
  ///
  /// 参数:
  /// - [context] BuildContext
  /// - [message] 要显示的消息内容
  /// - [backgroundColor] 消息背景颜色
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
///
/// 用于显示播放器操作栏中的单个按钮（图标+文字）。
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
