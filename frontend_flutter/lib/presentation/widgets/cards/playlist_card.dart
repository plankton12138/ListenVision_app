import 'package:demo/models/models_export.dart';
import 'package:flutter/material.dart';

/// 歌单卡片变体类型
enum PlaylistCardVariant {
  standard,
  favorite,
  nowPlaying,
  bilibili,
}

/// 歌单卡片组件
///
/// 统一的歌单展示卡片，支持本地Playlist和B站歌单
class PlaylistCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? coverUrl;
  final int itemCount;
  final int playCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final Color? iconColor;
  final IconData? icon;
  final PlaylistCardVariant variant;

  const PlaylistCard({
    super.key,
    required this.title,
    this.description,
    this.coverUrl,
    this.itemCount = 0,
    this.playCount = 0,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.iconColor,
    this.icon,
    this.variant = PlaylistCardVariant.standard,
  });

  /// 从本地Playlist创建
  factory PlaylistCard.fromPlaylist(
    Playlist playlist, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Widget? trailing,
  }) {
    IconData? icon;
    PlaylistCardVariant variant;

    if (playlist.isFavorites) {
      icon = Icons.favorite;
      variant = PlaylistCardVariant.favorite;
    } else if (playlist.isNowPlaying) {
      icon = Icons.play_circle;
      variant = PlaylistCardVariant.nowPlaying;
    } else {
      icon = Icons.playlist_play;
      variant = PlaylistCardVariant.standard;
    }

    return PlaylistCard(
      title: playlist.name,
      description: playlist.description,
      coverUrl: null, // 本地歌单暂无封面
      itemCount: playlist.itemCount,
      playCount: playlist.playCount,
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: trailing,
      icon: icon,
      variant: variant,
    );
  }

  /// 从B站歌单创建
  factory PlaylistCard.fromBiliPlaylist(
    BiliPlaylist playlist, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Widget? trailing,
  }) {
    return PlaylistCard(
      title: playlist.title,
      description: playlist.intro,
      coverUrl: playlist.coverUrl,
      itemCount: playlist.songCount,
      playCount: 0, // B站歌单没有播放次数
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: trailing,
      icon: Icons.library_music,
      variant: PlaylistCardVariant.bilibili,
    );
  }

  String _buildSubtitle() {
    final parts = <String>[
      if (description != null && description!.isNotEmpty) description!,
      if (itemCount > 0) '$itemCount首',
      if (playCount > 0) '播放$playCount次',
    ];
    return parts.where((s) => s.isNotEmpty).join(' · ');
  }

  Color _getVariantColor(BuildContext context) {
    if (iconColor != null) return iconColor!;
    
    final colorScheme = Theme.of(context).colorScheme;
    switch (variant) {
      case PlaylistCardVariant.favorite:
        return colorScheme.error;
      case PlaylistCardVariant.nowPlaying:
        return colorScheme.primary;
      case PlaylistCardVariant.bilibili:
        return colorScheme.tertiary;
      case PlaylistCardVariant.standard:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = _getVariantColor(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: icon != null
            ? CircleAvatar(
                backgroundColor: effectiveIconColor.withValues(alpha: 0.1),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              )
            : null,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          _buildSubtitle(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

