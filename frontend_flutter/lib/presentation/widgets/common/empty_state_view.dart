import 'package:flutter/material.dart';

/// 空状态视图组件
///
/// 统一的空状态显示
class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 歌单空状态
class EmptyPlaylistView extends StatelessWidget {
  final VoidCallback? onCreate;

  const EmptyPlaylistView({
    super.key,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      message: '还没有歌单',
      icon: Icons.playlist_play,
      action: onCreate != null
          ? ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('创建歌单'),
            )
          : null,
    );
  }
}

/// 搜索结果空状态
class EmptySearchView extends StatelessWidget {
  final String keyword;

  const EmptySearchView({
    super.key,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      message: '没有找到 "$keyword" 的相关内容',
      icon: Icons.search_off,
    );
  }
}

/// 收藏空状态
class EmptyFavoritesView extends StatelessWidget {
  const EmptyFavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      message: '还没有收藏任何内容',
      icon: Icons.favorite_border,
    );
  }
}
