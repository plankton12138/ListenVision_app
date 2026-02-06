import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:demo/presentation/viewmodels/library/playlist_viewmodel.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
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
    // Riverpod 3.0: watch AsyncValue<PlaylistState>
    final playlistAsync = ref.watch(playlistViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '歌单',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: UIConstants.iconMedium,
            onPressed: () {
              // Riverpod 3.0: 使用 .notifier 调用方法
              final storage = ref.read(sharedStorageServiceProvider);
              final token = storage.getString('auth_token');
              if (token != null) {
                ref.read(playlistViewModelProvider.notifier).loadPlaylists(token);
              }
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
      body: !isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('请先登录'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('去登录'),
                  ),
                ],
              ),
            )
          : playlistAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('加载失败: $err')),
              data: (state) => _buildContent(context, ref, state),
            ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PlaylistState state) {
    return Column(
      children: [
        // 本地音乐歌单（系统预设）
        _buildLocalMusicPlaylistTile(context, ref),
        const Divider(),
        // 在线歌单列表
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
                        child: Icon(
                          Icons.playlist_play,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.itemCount}首'),
                      onTap: () {
                        context.push('/playlist/${playlist.id}');
                      },
                    );
                  },
                ),
        ),
      ],
    );
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
            error: (_, __) => const Text('导入的本地音频'),
          );
        },
      ),
      onTap: () {
        context.push('/playlist/local');
      },
    );
  }
}
