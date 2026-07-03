import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/utils/image_helper.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/library/playlist_viewmodel.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 歌单库页面
///
/// 显示用户的歌单列表
/// 使用 Riverpod 3.0 AsyncNotifier 模式
class PlaylistLibraryPage extends ConsumerWidget {
  const PlaylistLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final playlistAsync = ref.watch(playlistViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '歌单',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          // 创建歌单按钮（仅登录用户）
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.add),
              iconSize: UIConstants.iconMedium,
              onPressed: () => _showCreatePlaylistDialog(context, ref),
              tooltip: '创建歌单',
            ),
          // 刷新按钮（仅登录用户）
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              iconSize: UIConstants.iconMedium,
              onPressed: () {
                ref.read(playlistViewModelProvider.notifier).loadPlaylists();
              },
            ),
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (state) => _buildContent(context, ref, state, isLoggedIn),
      ),
    );
  }

  /// 显示创建歌单对话框
  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新歌单'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入歌单名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('歌单名称不能为空')),
                );
                return;
              }
              Navigator.pop(context);
              await ref.read(playlistViewModelProvider.notifier).createPlaylist(
                name: name,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('歌单 "$name" 创建成功')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PlaylistState state, bool isLoggedIn) {
    return Column(
      children: [
        // 本地音乐歌单（系统预设，所有用户可见）
        _buildLocalMusicPlaylistTile(context, ref),

        const Divider(),
        // 系统歌单：我喜欢（离线也可用）
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: const Text('我喜欢'),
          subtitle: Text('${state.favoritesItems.length}首'),
          onTap: () {
            final id = state.favoritesPlaylist?.id ?? '1';
            context.push('/playlists/$id');
          },
        ),

        // 在线歌单列表（仅登录用户可见）
        if (isLoggedIn) ...[
          const Divider(),
          Expanded(
            child: state.userPlaylists.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_add, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无歌单，点击 + 创建新歌单'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.userPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = state.userPlaylists[index];
                      return ListTile(
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: playlist.hasCover
                              ? ImageHelper.cachedNetworkImageWithRadius(
                                  playlist.coverUrl!,
                                  fit: BoxFit.cover,
                                  borderRadius: 4,
                                )
                              : Icon(
                                  Icons.playlist_play,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                        ),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.itemCount}首'),
                        onTap: () {
                          context.push('/playlists/${playlist.id}');
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showPlaylistOptions(context, ref, playlist),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  /// 显示歌单选项
  void _showPlaylistOptions(BuildContext context, WidgetRef ref, dynamic playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _showDeleteConfirmDialog(context, ref, playlist);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除歌单 "${playlist.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(playlistViewModelProvider.notifier)
          .deletePlaylist(playlist.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('歌单已删除')),
        );
      }
    }
  }

  /// 本地音乐歌单项
  Widget _buildLocalMusicPlaylistTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.folder_special,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: const Text('本地音乐'),
      subtitle: Consumer(
        builder: (context, ref, child) {
          final localMusicState = ref.watch(localMusicViewModelProvider);
          return localMusicState.when(
            data: (state) => state.map(
              initial: (_) => const Text('导入的本地音频'),
              loading: (_) => const Text('加载中...'),
              loaded: (data) => Text('${data.audios.length}首歌曲'),
              importing: (data) => const Text('导入中...'),
              error: (_) => const Text('导入的本地音频'),
            ),
            loading: () => const Text('加载中...'),
            error: (_, _) => const Text('导入的本地音频'),
          );
        },
      ),
      onTap: () {
        context.push('/playlists/local');
      },
    );
  }
}
