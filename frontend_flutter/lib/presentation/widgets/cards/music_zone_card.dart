import 'package:flutter/material.dart';

/// 音乐区视频卡片组件
///
/// 用于显示音乐区的推荐视频
class MusicZoneCard extends StatelessWidget {
  final String bvid;
  final String title;
  final String cover;
  final String author;
  final int playCount;
  final String? arcurl;
  final VoidCallback? onTap;

  const MusicZoneCard({
    super.key,
    required this.bvid,
    required this.title,
    required this.cover,
    required this.author,
    this.playCount = 0,
    this.arcurl,
    this.onTap,
  });

  /// 从Map创建（用于API返回数据）
  factory MusicZoneCard.fromJson(
    Map<String, dynamic> json, {
    VoidCallback? onTap,
  }) {
    return MusicZoneCard(
      bvid: json['bvid'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      author: json['author'] ?? 'Unknown',
      playCount: json['playCount'] ?? 0,
      arcurl: json['arcurl'],
      onTap: onTap,
    );
  }

  String _formatCoverUrl() {
    String url = cover;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }
    return url;
  }

  String _formatPlayCount() {
    if (playCount >= 10000) {
      return '${(playCount / 10000).toStringAsFixed(1)}万';
    }
    return playCount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _formatCoverUrl();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Match Card default radius usually
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  coverUrl.isNotEmpty ? coverUrl : '',
                  width: 100,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 70,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image, size: 32, color: colorScheme.onSurfaceVariant),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 70,
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // 右侧信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 作者和播放量
                    Text(
                      'UP: $author  ·  播放: ${_formatPlayCount()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 播放按钮
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: onTap,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
