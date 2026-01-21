import 'package:flutter/material.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/recommendation.dart';

/// 歌单卡片组件（新架构）
///
/// 统一的歌单展示卡片，支持本地 Playlist 和 B站歌单
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

  /// 从本地 Playlist 实体创建
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
      coverUrl: playlist.coverUrl,
      itemCount: playlist.itemCount,
      playCount: playlist.playCount,
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: trailing,
      iconColor: iconColor,
      icon: icon,
    );
  }

  /// 从 B站歌单创建
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
        leading: _buildLeading(),
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

  Widget? _buildLeading() {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          coverUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 48,
              height: 48,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    if (icon != null) {
      return CircleAvatar(
        backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20),
      );
    }

    return null;
  }

  Widget _buildFallbackIcon() {
    return CircleAvatar(
      backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.1),
      child: Icon(icon ?? Icons.music_note, color: iconColor, size: 20),
    );
  }
}
