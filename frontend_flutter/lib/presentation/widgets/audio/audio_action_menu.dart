import 'dart:io';

import 'package:listenvision/core/constants/api_constants.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/download_task.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/playlist.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/library/playlist_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/system/download_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// 音频操作菜单组件
///
/// 提供播放、下载、加入歌单、收藏、跳转原网页等操作
class AudioActionMenu extends ConsumerWidget {
  /// BVID
  final String bvid;

  /// 标题
  final String title;

  /// 艺术家
  final String? artist;

  /// 封面 URL
  final String? coverUrl;

  /// 时长（秒）
  final int? duration;

  /// 是否显示收藏按钮
  final bool showFavorite;

  /// 是否显示下载按钮
  final bool showDownload;

  /// 是否显示添加到歌单按钮
  final bool showAddToPlaylist;

  /// 是否显示跳转原网页按钮
  final bool showOpenInBrowser;

  const AudioActionMenu({
    super.key,
    required this.bvid,
    required this.title,
    this.artist,
    this.coverUrl,
    this.duration,
    this.showFavorite = true,
    this.showDownload = true,
    this.showAddToPlaylist = true,
    this.showOpenInBrowser = true,
  });

  /// 显示底部操作菜单
  static Future<void> show(
    BuildContext context, {
    required String bvid,
    required String title,
    String? artist,
    String? coverUrl,
    int? duration,
    bool showFavorite = true,
    bool showDownload = true,
    bool showAddToPlaylist = true,
    bool showOpenInBrowser = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AudioActionMenu(
        bvid: bvid,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        duration: duration,
        showFavorite: showFavorite,
        showDownload: showDownload,
        showAddToPlaylist: showAddToPlaylist,
        showOpenInBrowser: showOpenInBrowser,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistViewModelProvider);
    final downloadState = ref.watch(downloadViewModelProvider);
    return playlistState.when(
      data: (state) {
        final isFavorited = state.map(
          initial: (_) => false,
          loaded: (value) => value.favoritesItems.any((item) => item.bvid == bvid),
          error: (_) => false,
        );
        // 获取当前 bvid 的下载任务
        final downloadTask = downloadState.whenOrNull(
          data: (state) {
            try {
              return state.downloads.firstWhere((task) => task.bvid == bvid);
            } catch (_) {
              return null;
            }
          },
        );
        return _buildContent(context, ref, isFavorited, downloadTask);
      },
      loading: () => _buildContent(context, ref, false, null),
      error: (_, __) => _buildContent(context, ref, false, null),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    bool isFavorited,
    DownloadTask? downloadTask,
  ) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部指示条
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 音频信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (coverUrl != null && coverUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      coverUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artist != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          artist!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 操作列表
          // 收藏（本地优先，离线可用）
          if (showFavorite)
            ListTile(
              leading: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.red : null,
              ),
              title: Text(isFavorited ? '取消收藏' : '收藏'),
              onTap: () async {
                try {
                  AppLogger.info('AudioActionMenu', '切换收藏: $bvid');

                  final playlistNotifier = ref.read(playlistViewModelProvider.notifier);

                  await playlistNotifier.toggleFavorite(
                    bvid,
                    title: title,
                    artist: artist,
                    duration: duration,
                    coverUrl: coverUrl,
                  );

                } catch (e) {
                  AppLogger.error('AudioActionMenu', '收藏操作失败: $e');
                }
              },
            ),

          // 加入歌单（仅登录用户可见）
          if (showAddToPlaylist)
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('加入歌单'),
              onTap: () {
                // 不关闭当前 bottom sheet，而是直接打开歌单选择器
                _showPlaylistSelector(context, ref);
              },
            ),

          // 下一首播放
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('下一首播放'),
            onTap: () => _handleInsertNext(context, ref),
          ),

          if (showDownload)
            ListTile(
              leading: Icon(_getDownloadIcon(downloadTask), color: _getDownloadColor(downloadTask)),
              title: Text(_getDownloadTitle(downloadTask)),
              trailing: _buildDownloadProgress(ref, downloadTask),
              onTap: () => _handleDownload(context, ref, downloadTask),
            ),

          if (showOpenInBrowser)
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('在浏览器中打开'),
              onTap: () {
                Navigator.pop(context);
                _openInBrowser(context);
              },
            ),


          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 显示歌单选择器
  void _showPlaylistSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PlaylistSelectorContent(
        bvid: bvid,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        duration: duration,
      ),
    );
  }

  /// 在浏览器中打开
  void _openInBrowser(BuildContext context) async {
    final url = 'https://www.bilibili.com/video/$bvid';
    AppLogger.info('AudioActionMenu', '在浏览器中打开: $url');

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 添加到下一首播放
  void _handleInsertNext(BuildContext context, WidgetRef ref) {
    AppLogger.info('AudioActionMenu', '添加到下一首播放: $bvid');

    final baseUrl = ApiConstants.baseUrl.replaceAll('localhost', '127.0.0.1');
    final proxyUrl = '$baseUrl/api/v1/bilibili/proxy/audio/$bvid?format=auto';

    final audio = Audio(
      id: bvid,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      duration: duration,
    );

    final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

    ref.read(queueViewModelProvider.notifier).insertNext(playable);

    Navigator.pop(context);
    _showSnackBar(context, '已添加到下一首播放', Colors.green);
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

  /// 获取下载目录
  Future<String> _getDownloadDirectory() async {
    try {
      // 获取系统下载目录
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        throw Exception('系统下载目录不可用');
      }

      // 创建应用子目录
      final appDownloadDir = Directory('${downloadDir.path}${path.separator}ListenVision');
      if (!await appDownloadDir.exists()) {
        await appDownloadDir.create(recursive: true);
      }

      return '${appDownloadDir.path}${path.separator}';
    } catch (e) {
      AppLogger.error('AudioActionMenu', '获取下载目录失败: $e');
      // 降级到应用文档目录
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${docDir.path}${path.separator}Downloads');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return '${fallbackDir.path}${path.separator}';
      } catch (e) {
        AppLogger.error('AudioActionMenu', '获取备用目录失败: $e');
        return '';
      }
    }
  }

  /// 清理标题字符串
  String _sanitizeTitle(String input) {
    const pattern =
        r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""''·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 获取下载图标
  IconData _getDownloadIcon(DownloadTask? task) {
    if (task == null) return Icons.download;
    return switch (task.status) {
      DownloadStatus.pending => Icons.downloading,
      DownloadStatus.downloading => Icons.downloading,
      DownloadStatus.paused => Icons.pause,
      DownloadStatus.completed => Icons.check_circle,
      DownloadStatus.failed => Icons.error,
      DownloadStatus.stalled => Icons.warning,
    };
  }

  /// 获取下载图标颜色
  Color? _getDownloadColor(DownloadTask? task) {
    if (task == null) return null;
    return switch (task.status) {
      DownloadStatus.completed => Colors.green,
      DownloadStatus.failed => Colors.red,
      DownloadStatus.paused => Colors.orange,
      _ => null,
    };
  }

  /// 获取下载标题
  String _getDownloadTitle(DownloadTask? task) {
    if (task == null) return '下载';
    return switch (task.status) {
      DownloadStatus.pending => '下载中',
      DownloadStatus.downloading => '下载中',
      DownloadStatus.paused => '已暂停',
      DownloadStatus.completed => '已下载',
      DownloadStatus.failed => '下载失败',
      DownloadStatus.stalled => '连接中断',
    };
  }

  /// 构建下载进度显示
  Widget? _buildDownloadProgress(WidgetRef ref, DownloadTask? task) {
    if (task?.status == DownloadStatus.downloading) {
      final progress = ref.read(downloadViewModelProvider.notifier).getTaskProgress(task!.id!);
      return Text('$progress%', style: const TextStyle(fontSize: 12, color: Colors.grey));
    }
    return null;
  }

  /// 处理下载操作
  void _handleDownload(BuildContext context, WidgetRef ref, DownloadTask? task) async {
    // 如果已完成，不做任何事（按钮显示"已下载"）
    if (task?.isCompleted == true) {
      return;
    }

    // 如果正在下载/排队，不做任何事（按钮显示"下载中"）
    if (task?.isActive == true) {
      return;
    }

    // 开始下载（bottom sheet 保持打开，用户可以看到状态变化）
    try {
      AppLogger.info('AudioActionMenu', '下载音频: $bvid');

      final downloadNotifier = ref.read(downloadViewModelProvider.notifier);
      final downloadDir = await _getDownloadDirectory();
      final sanitizedTitle = _sanitizeTitle(title);
      final savePath = '$downloadDir$sanitizedTitle.mp3';

      await downloadNotifier.addDownload(
        bvid: bvid,
        savePath: savePath,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
      );
    } catch (e) {
      AppLogger.error('AudioActionMenu', '下载操作失败: $e');
    }
  }
}

/// 歌单选择器内容组件
class _PlaylistSelectorContent extends ConsumerStatefulWidget {
  final String bvid;
  final String title;
  final String? artist;
  final String? coverUrl;
  final int? duration;

  const _PlaylistSelectorContent({
    required this.bvid,
    required this.title,
    this.artist,
    this.coverUrl,
    this.duration,
  });

  @override
  ConsumerState<_PlaylistSelectorContent> createState() => _PlaylistSelectorContentState();
}

class _PlaylistSelectorContentState extends ConsumerState<_PlaylistSelectorContent> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistViewModelProvider);

    return playlistState.when(
      data: (state) {
        final userPlaylists = state.map(
          initial: (_) => <Playlist>[],
          loaded: (value) => value.userPlaylists,
          error: (_) => <Playlist>[],
        );
        return _buildContent(context, userPlaylists);
      },
      loading: () => _buildContent(context, <Playlist>[]),
      error: (_, __) => _buildContent(context, <Playlist>[]),
    );
  }

  Widget _buildContent(BuildContext context, List<Playlist> userPlaylists) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 顶部指示条
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '选择歌单',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showCreatePlaylistDialog,
                      tooltip: '创建新歌单',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 歌单列表
              Expanded(
                child: userPlaylists.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.playlist_add, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('暂无歌单，点击 + 创建'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: userPlaylists.length,
                        itemBuilder: (context, index) {
                          final playlist = userPlaylists[index];
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: playlist.hasCover
                                    ? null
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: playlist.hasCover
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        playlist.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.playlist_play),
                                      ),
                                    )
                                  : const Icon(Icons.playlist_play),
                            ),
                            title: Text(playlist.name),
                            subtitle: Text('${playlist.itemCount} 首歌曲'),
                            onTap: () => _addToPlaylist(playlist.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示创建歌单对话框
  void _showCreatePlaylistDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新歌单'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '歌单名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) {
                _showSnackBar('请输入歌单名称', Colors.orange);
                return;
              }

              Navigator.pop(context);

              final playlistNotifier = ref.read(playlistViewModelProvider.notifier);
              final newPlaylist = await playlistNotifier.createPlaylist(
                name: name,
              );

              if (newPlaylist != null && mounted) {
                // 自动添加到新创建的歌单
                _addToPlaylist(newPlaylist.id);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 添加到歌单
  void _addToPlaylist(String playlistId) async {
    try {
      AppLogger.info('AudioActionMenu', '添加到歌单: ${widget.bvid} -> $playlistId');

      Navigator.pop(context);

      final playlistNotifier = ref.read(playlistViewModelProvider.notifier);

      final success = await playlistNotifier.addItem(
        playlistId,
        widget.bvid,
        title: widget.title,
        artist: widget.artist,
        duration: widget.duration,
        coverUrl: widget.coverUrl,
      );

      if (mounted) {
        if (success) {
          _showSnackBar('已添加到歌单', Colors.green);
        } else {
          _showSnackBar('添加失败', Colors.red);
        }
      }
    } catch (e) {
      AppLogger.error('AudioActionMenu', '添加到歌单失败: $e');
      if (mounted) {
        _showSnackBar('操作失败: $e', Colors.red);
      }
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
