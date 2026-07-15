import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 播放列表页面
///
/// 显示当前播放队列中的音频列表
/// 使用 Riverpod 的 QueueViewModel
class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);
    final queue = queueState.queue;
    final tracks = queue?.tracks;
    final currentIndex = queue?.currentIndex;
    final isEmpty = tracks?.isEmpty ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放列表',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
          // 清空列表按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            iconSize: UIConstants.iconMedium,
            onPressed: isEmpty
                ? null
                : () => ref.read(queueViewModelProvider.notifier).clear(),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '播放列表为空',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: tracks!.length,
              itemBuilder: (context, index) {
                final playable = tracks[index];
                final isCurrent = currentIndex == index;

                return ListTile(
                  key: ValueKey(playable.id),
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    child: Icon(
                      isCurrent ? Icons.play_arrow : Icons.music_note,
                      color: isCurrent ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    playable.title,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text(playable.artist ?? '未知艺术家'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => ref.read(queueViewModelProvider.notifier).removeAt(index),
                  ),
                  onTap: () {
                    ref.read(queueViewModelProvider.notifier).setCurrentIndex(index);
                    // 后续在此接入明确的播放触发入口
                  },
                );
              },
            ),
    );
  }
}
