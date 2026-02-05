import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 歌单库页面
///
/// 显示用户的歌单列表
/// 使用 Riverpod 的 PlaylistViewModel
class PlaylistLibraryPage extends ConsumerWidget {
  const PlaylistLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final playlistViewModel = ref.watch(playlistViewModelProvider);

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
              // TODO: 刷新歌单列表
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
          : Column(
              children: [
                // 本地音乐歌单（系统预设）
                _buildLocalMusicPlaylistTile(context, ref),
                const Divider(),
                // 在线歌单列表（待实现）
                const Expanded(
                  child: Center(
                    child: Text('在线歌单列表待实现'),
                  ),
                ),
              ],
            ),
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
            loaded: (audios) => Text('${audios.length}首歌曲'),
            loading: () => const Text('加载中...'),
            error: (_) => const Text('导入的本地音频'),
            importing: (_, __, ___) => const Text('导入中...'),
            initial: () => const Text('导入的本地音频'),
          );
        },
      ),
      onTap: () {
        context.push('/playlist/local');
      },
    );
  }
}
