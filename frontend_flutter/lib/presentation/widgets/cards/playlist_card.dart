// 使用 Clean Architecture entities
import 'package:demo/domain/entities/models_export.dart';
import 'package:flutter/material.dart';

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
  });

  /// 从本地Playlist创建
  factory PlaylistCard.fromPlaylist(
    Playlist playlist, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Widget? trailing,
  }) {
    IconData? icon;
    Color? iconColor;

    if (playlist.isFavorites) {
      icon = Icons.favorite;
      iconColor = Colors.red;
    } else if (playlist.isNowPlaying) {
      icon = Icons.play_circle;
      iconColor = Colors.blue;
    } else {
      icon = Icons.playlist_play;
      iconColor = Colors.grey;
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
      iconColor: iconColor,
      icon: icon,
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
      iconColor: Colors.purple,
      icon: Icons.library_music,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: icon != null
            ? CircleAvatar(
                backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 20),
              )
            : null,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _buildSubtitle(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
