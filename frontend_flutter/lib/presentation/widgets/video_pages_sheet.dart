import 'package:flutter/material.dart';
import '../../models/audio.dart';

/// 分P选择底部面板
///
/// 当用户点击搜索结果中的多P视频时弹出。
/// 显示所有分P列表和"播放全部"/"下载全部"按钮。
class VideoPagesSheet extends StatelessWidget {
  final String title;
  final List<AudioPage> pages;
  final int? totalDuration;
  final void Function(AudioPage page) onPlayPage;
  final VoidCallback onPlayAll;
  final void Function(AudioPage page)? onDownloadPage;
  final VoidCallback? onDownloadAll;

  const VideoPagesSheet({
    super.key,
    required this.title,
    required this.pages,
    this.totalDuration,
    required this.onPlayPage,
    required this.onPlayAll,
    this.onDownloadPage,
    this.onDownloadAll,
  });

  /// 弹出分P选择面板
  static void show({
    required BuildContext context,
    required String title,
    required List<AudioPage> pages,
    int? totalDuration,
    required void Function(AudioPage page) onPlayPage,
    required VoidCallback onPlayAll,
    void Function(AudioPage page)? onDownloadPage,
    VoidCallback? onDownloadAll,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => VideoPagesSheet(
        title: title,
        pages: pages,
        totalDuration: totalDuration,
        onPlayPage: onPlayPage,
        onPlayAll: onPlayAll,
        onDownloadPage: onDownloadPage,
        onDownloadAll: onDownloadAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示条
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          // 分P列表
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pages.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final page = pages[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    page.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        page.formattedDuration,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      if (onDownloadPage != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onDownloadPage!(page),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.download,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onPlayPage(page);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 底部操作按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 播放全部
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.playlist_play, size: 18),
                    label: Text(
                      totalDuration != null
                          ? '播放全部 (${AudioPage.formatDuration(totalDuration)})'
                          : '播放全部',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onPlayAll();
                    },
                  ),
                ),
                if (onDownloadAll != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('下载全部', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDownloadAll!();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
