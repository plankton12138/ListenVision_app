import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/local_playable.dart';
import 'package:listenvision/models/queue_source.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/widgets/common/snackbar_helper.dart';
import 'package:listenvision/presentation/widgets/common/marquee_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/local_audio.dart';
import '../../viewmodels/library/local_music_viewmodel.dart';

/// 本地音乐歌单页面
///
/// 展示和管理"本地音乐"歌单中的音频文件。
/// 支持批量选择和删除。
class LocalMusicPlaylistPage extends ConsumerStatefulWidget {
  const LocalMusicPlaylistPage({super.key});

  @override
  ConsumerState<LocalMusicPlaylistPage> createState() =>
      _LocalMusicPlaylistPageState();
}

class _LocalMusicPlaylistPageState
    extends ConsumerState<LocalMusicPlaylistPage> {
  /// 批量模式状态
  bool _isBatchMode = false;

  /// 选中的音频 ID 集合
  final Set<int> _selectedIds = {};

  /// 进入批量模式
  void _enterBatchMode() {
    setState(() {
      _isBatchMode = true;
      _selectedIds.clear();
    });
  }

  /// 退出批量模式
  void _exitBatchMode() {
    setState(() {
      _isBatchMode = false;
      _selectedIds.clear();
    });
  }

  /// 切换选中状态
  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// 全选/取消全选
  void _toggleSelectAll(List<LocalAudio> audios) {
    setState(() {
      if (_selectedIds.length == audios.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(audios.map((a) => a.id!));
      }
    });
  }

  /// 批量删除
  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量移除'),
        content: Text('确定要从本地音乐中移除选中的 ${_selectedIds.length} 首歌曲吗？\n\n（不会删除原始文件）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    AppLogger.info('LocalMusicPlaylistPage', '批量移除: ${_selectedIds.length}项');

    // 逐个删除
    int success = 0;
    for (final id in _selectedIds) {
      try {
        await ref.read(localMusicViewModelProvider.notifier).deleteLocalMusic(id);
        success++;
      } catch (e) {
        AppLogger.error('LocalMusicPlaylistPage', '移除失败 id=$id: $e');
      }
    }

    if (mounted) {
      SnackbarHelper.showSuccess(context, '成功移除 $success 首歌曲');
      _exitBatchMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localMusicViewModelProvider);
    // 检查是否有已加载的音频数据
    final hasItems = state.when(
      data: (localState) => localState.maybeWhen(
        loaded: (audios) => audios.isNotEmpty,
        orElse: () => false,
      ),
      loading: () => false,
      error: (_, _) => false,
    );

    return Scaffold(
      appBar: _isBatchMode
          ? _buildBatchAppBar()
          : _buildNormalAppBar(hasItems),
      body: state.when(
        data: (localState) => localState.map(
          initial: (_) => const Center(child: CircularProgressIndicator()),
          loading: (_) => const Center(child: CircularProgressIndicator()),
          loaded: (data) => _buildPlaylistView(context, data.audios, ref),
          importing: (data) => _buildImportingView(
            context,
            data.current,
            data.total,
            data.currentFile,
          ),
          error: (data) => _buildErrorView(context, data.message, ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
      ),
      bottomNavigationBar:
          _isBatchMode ? _buildBatchActionBar() : null,
    );
  }

  /// 正常模式 AppBar
  AppBar _buildNormalAppBar(bool hasItems) {

    return AppBar(
      title: Text(
        '本地音乐',
        style: TextStyle(fontSize: UIConstants.fontSizeLarge),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home),
          iconSize: UIConstants.iconMedium,
          onPressed: () => context.go('/'),
        ),
        if (hasItems)
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: '批量操作',
            onPressed: _enterBatchMode,
          ),
        IconButton(
          icon: const Icon(Icons.playlist_add),
          tooltip: '批量导入',
          onPressed: () {
            ref.read(localMusicViewModelProvider.notifier).importMultipleFiles();
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '导入音频',
          onPressed: () {
            ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '刷新',
          onPressed: () {
            ref.read(localMusicViewModelProvider.notifier).refresh();
          },
        ),
      ],
    );
  }

  /// 批量模式 AppBar
  AppBar _buildBatchAppBar() {
    return AppBar(
      leading: TextButton(
        onPressed: _exitBatchMode,
        child: const Text('取消', style: TextStyle(color: Colors.white)),
      ),
      title: const Text('批量操作'),
      centerTitle: true,
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '已选 ${_selectedIds.length} 项',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// 批量操作底部栏
  Widget _buildBatchActionBar() {
    final hasSelection = _selectedIds.isNotEmpty;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                // 从 state 获取 audios 列表需要用另一种方式
                // 这里我们从 widget 重建获取
                final state = ref.read(localMusicViewModelProvider);
                state.whenData((localState) {
                  localState.map(
                    loaded: (data) => _toggleSelectAll(data.audios),
                    // 其他状态不处理
                    initial: (_) {},
                    loading: (_) {},
                    importing: (_) {},
                    error: (_) {},
                  );
                });
              },
              icon: Icon(Icons.check_box_outline_blank),
              label: const Text('全选'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: hasSelection ? _batchDelete : null,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text('删除(${_selectedIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 歌单内容视图
  Widget _buildPlaylistView(
      BuildContext context, List<LocalAudio> audios, WidgetRef ref) {
    if (audios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('本地音乐歌单是空的'),
            const SizedBox(height: 8),
            const Text(
              '导入的本地音频将显示在这里',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
              },
              icon: const Icon(Icons.add),
              label: const Text('导入音频'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 歌单信息头（批量模式提示）
        if (_isBatchMode)
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  _selectedIds.length == audios.length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedIds.length == audios.length ? '已全选' : '勾选要移除的歌曲',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length}/${audios.length}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCoverImage(audios),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '本地音乐',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${audios.length}首歌曲',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // 播放全部按钮（仅在非批量模式显示）
        if (!_isBatchMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _playAll(context, ref, audios),
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        // 歌曲列表
        Expanded(
          child: ListView.builder(
            itemCount: audios.length,
            itemBuilder: (context, index) {
              final audio = audios[index];
              return _buildAudioListTile(context, audio, index, ref, audios);
            },
          ),
        ),
      ],
    );
  }

  /// 构建封面图片
  Widget _buildCoverImage(List<LocalAudio> audios) {
    final audioWithCover = audios.firstWhere(
      (a) => a.albumArt != null,
      orElse: () => audios.first,
    );

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: audioWithCover.albumArt != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                audioWithCover.albumArt!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.music_note, size: 40),
              ),
            )
          : const Icon(Icons.music_note, size: 40),
    );
  }

  /// 构建音频列表项
  Widget _buildAudioListTile(
      BuildContext context, LocalAudio audio, int index, WidgetRef ref, List<LocalAudio> audios) {
    if (_isBatchMode) {
      return _buildBatchAudioTile(audio, index);
    }
    return _buildNormalAudioTile(context, audio, index, ref, audios);
  }

  /// 普通模式列表项
  Widget _buildNormalAudioTile(
      BuildContext context, LocalAudio audio, int index, WidgetRef ref, List<LocalAudio> audios) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ),
      title: MarqueeText(audio.title),
      subtitle: MarqueeText(
        '${audio.artist} · ${_formatDuration(audio.duration)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              audio.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: audio.isFavorite ? Colors.red : null,
              size: 20,
            ),
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).toggleFavorite(
                    audio.id!,
                    !audio.isFavorite,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showItemMenu(context, audio, ref),
          ),
        ],
      ),
      onTap: () => _playAudio(context, ref, audio, audios),
      onLongPress: () {
        _enterBatchMode();
        _toggleSelection(audio.id!);
      },
    );
  }

  /// 批量模式列表项
  Widget _buildBatchAudioTile(LocalAudio audio, int index) {
    final isSelected = _selectedIds.contains(audio.id);
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleSelection(audio.id!),
      ),
      title: MarqueeText(audio.title),
      subtitle: MarqueeText(
        '${audio.artist} · ${_formatDuration(audio.duration)}',
      ),
      trailing: Icon(
        Icons.music_note,
        size: 20,
        color: Colors.grey[400],
      ),
      onTap: () => _toggleSelection(audio.id!),
    );
  }

  /// 导入中视图
  Widget _buildImportingView(
      BuildContext context, int current, int total, String currentFile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: current / total,
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '导入中... $current/$total',
            style: const TextStyle(fontSize: 16),
          ),
          if (currentFile.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: MarqueeText(
                currentFile,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(BuildContext context, String message, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 显示歌曲菜单
  void _showItemMenu(BuildContext context, LocalAudio audio, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: MarqueeText(audio.title),
              subtitle: Text(audio.artist),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('播放'),
              onTap: () {
                final audios = ref.read(localMusicViewModelProvider).whenOrNull(
                  data: (state) => state.maybeWhen(
                    loaded: (audios) => audios,
                    orElse: () => <LocalAudio>[],
                  ),
                ) ?? <LocalAudio>[];
                Navigator.pop(context);
                _playAudio(context, ref, audio, audios);
              },
            ),
            ListTile(
              leading: Icon(
                audio.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: audio.isFavorite ? Colors.red : null,
              ),
              title: Text(audio.isFavorite ? '取消收藏' : '收藏'),
              onTap: () {
                Navigator.pop(context);
                ref.read(localMusicViewModelProvider.notifier).toggleFavorite(
                      audio.id!,
                      !audio.isFavorite,
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('从歌单移除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, audio, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 确认删除
  void _confirmDelete(BuildContext context, LocalAudio audio, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text(
            '确定要从"本地音乐"歌单中移除"${audio.title}"吗？\n\n（不会删除原始文件）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(localMusicViewModelProvider.notifier).deleteLocalMusic(audio.id!);
            },
            child: const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 播放全部
  Future<void> _playAll(BuildContext context, WidgetRef ref, List<LocalAudio> audios) async {
    if (audios.isEmpty) return;

    final playables = audios.map((audio) => LocalPlayable.fromAudio(audio)).toList();
    final source = QueueSource.userPlaylist('local_music', '本地音乐');

    await ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
      playables,
      source,
      initialIndex: 0,
    );

    ref.read(playbackViewModelProvider.notifier).play(playables.first, index: 0);

    if (context.mounted) {
      SnackbarHelper.showPlaying(context, audios.first.title, artist: audios.first.artist);
    }
  }

  /// 播放音频
  void _playAudio(BuildContext context, WidgetRef ref, LocalAudio audio, List<LocalAudio> allAudios) async {
    AppLogger.info('LocalMusicPlaylistPage', '点击播放: id=${audio.id}, title=${audio.title}, filePath=${audio.filePath}');

    try {
      final index = allAudios.indexWhere((a) => a.id == audio.id);
      final playables = allAudios.map((a) => LocalPlayable.fromAudio(a)).toList();
      final source = QueueSource.userPlaylist('local_music', '本地音乐');

      await ref.read(queueViewModelProvider.notifier).setQueueFromPlaylist(
        playables,
        source,
        initialIndex: index,
      );

      ref.read(playbackViewModelProvider.notifier).play(
        playables[index],
        index: index,
      );

      if (context.mounted) {
        SnackbarHelper.showPlaying(context, audio.title, artist: audio.artist);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
