import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/playlist.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/library/playlist_viewmodel.dart';
import 'package:listenvision/presentation/widgets/audio/audio_action_menu.dart';

/// 播放器底部操作栏
///
/// 包含收藏、添加到歌单、更多等操作按钮
class PlayerActionBar extends ConsumerWidget {
  const PlayerActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playbackViewModelProvider);
    final playlistAsync = ref.watch(playlistViewModelProvider);

    final currentId = playerState.currentPlayable?.id ?? '';

    if (currentId.isEmpty) {
      return const Text(
        '暂无播放内容',
        style: TextStyle(color: Colors.grey),
      );
    }

    final isFavorited = playlistAsync.when(
      data: (playlistState) {
        if (playlistState is PlaylistStateLoaded) {
          return playlistState.favoritesItems.any((item) => item.bvid == currentId);
        }
        return false;
      },
      loading: () => false,
      error: (_, __) => false,
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
          onTap: () => _handleAddToPlaylist(context, ref),
        ),
        _ActionButton(
          icon: Icons.more_horiz,
          label: '更多',
          onTap: () => _handleMore(context, ref),
        ),
      ],
    );
  }

  /// 处理收藏按钮点击
  ///
  /// 切换当前播放歌曲的收藏状态（本地操作，无需登录）。
  Future<void> _handleFavorite(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final playlistNotifier = ref.read(playlistViewModelProvider.notifier);
    final playerState = ref.read(playbackViewModelProvider);

    final currentPlayable = playerState.currentPlayable;
    if (currentPlayable == null) return;

    final bvid = currentPlayable.id;

    AppLogger.logButtonClick(
      '收藏',
      'PlayerActionBar',
      parameters: {'bvid': bvid, 'title': currentPlayable.title},
    );

    try {
      final added = await playlistNotifier.toggleFavorite(
        bvid,
        title: currentPlayable.title,
        artist: currentPlayable.artist,
        duration: currentPlayable.duration,
        coverUrl: currentPlayable.coverUrl,
        localPath: currentPlayable.isOnline ? null : currentPlayable.url,
      );

      if (!context.mounted) return;

      // toggleFavorite已内部调用_loadFavoritesFromLocal()更新本地状态
      // 无需再次调用loadFavorites，避免服务器同步延迟导致的状态闪烁
      _showSnackBar(
        context,
        added ? '已添加到我喜欢' : '已从我喜欢移除',
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
  void _handleAddToPlaylist(BuildContext context, WidgetRef ref) {
    final playerState = ref.read(playbackViewModelProvider);
    final currentPlayable = playerState.currentPlayable;

    if (currentPlayable == null) {
      _showSnackBar(context, '当前没有播放内容', Colors.orange);
      return;
    }

    AppLogger.logButtonClick('添加到歌单', 'PlayerActionBar');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PlaylistSelectorForPlayer(
        bvid: currentPlayable.id,
        title: currentPlayable.title,
        artist: currentPlayable.artist,
        coverUrl: currentPlayable.coverUrl,
        duration: currentPlayable.duration,
      ),
    );
  }

  /// 处理更多选项
  void _handleMore(BuildContext context, WidgetRef ref) {
    final playerState = ref.read(playbackViewModelProvider);
    final currentPlayable = playerState.currentPlayable;

    if (currentPlayable == null) {
      _showSnackBar(context, '当前没有播放内容', Colors.orange);
      return;
    }

    AppLogger.logButtonClick('更多选项', 'PlayerActionBar');

    AudioActionMenu.show(
      context,
      bvid: currentPlayable.id,
      title: currentPlayable.title,
      artist: currentPlayable.artist,
      coverUrl: currentPlayable.coverUrl,
      duration: currentPlayable.duration,
      showDownload: currentPlayable.isOnline,
      showOpenInBrowser: currentPlayable.isOnline,
    );
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
        backgroundColor: backgroundColor.withAlpha(200),
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

/// 歌单选择器（用于播放器添加到歌单）
class _PlaylistSelectorForPlayer extends ConsumerStatefulWidget {
  final String bvid;
  final String title;
  final String? artist;
  final String? coverUrl;
  final int? duration;

  const _PlaylistSelectorForPlayer({
    required this.bvid,
    required this.title,
    this.artist,
    this.coverUrl,
    this.duration,
  });

  @override
  ConsumerState<_PlaylistSelectorForPlayer> createState() => _PlaylistSelectorForPlayerState();
}

class _PlaylistSelectorForPlayerState extends ConsumerState<_PlaylistSelectorForPlayer> {
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                _addToPlaylist(newPlaylist.id);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _addToPlaylist(String playlistId) async {
    try {
      AppLogger.info('PlayerActionBar', '添加到歌单: ${widget.bvid} -> $playlistId');

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
      AppLogger.error('PlayerActionBar', '添加到歌单失败: $e');
      if (mounted) {
        _showSnackBar('操作失败: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor.withAlpha(200),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
