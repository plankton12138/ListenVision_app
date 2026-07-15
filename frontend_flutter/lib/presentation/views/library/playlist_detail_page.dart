import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/storage/shared_storage_service.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/local_playable.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/widgets/audio/audio_action_menu.dart';
import 'package:listenvision/presentation/widgets/common/snackbar_helper.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:listenvision/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/library/playlist_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../core/state/state_utils.dart';

/// 歌单详情页面
///
/// 显示指定歌单的详细信息和音频列表
class PlaylistDetailPage extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  @override
  void initState() {
    super.initState();
    // 初始加载由 Provider 自动触发
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(
      playlistDetailViewModelProvider(widget.playlistId),
    );
    final viewModel = ref.read(
      playlistDetailViewModelProvider(widget.playlistId).notifier,
    );

    // 使用 ValueListenableBuilder 监听批量操作状态
    return ValueListenableBuilder<BatchOperationState>(
      valueListenable: viewModel.batchStateNotifier,
      builder: (context, batchState, child) {
        final isBatchMode = batchState.isInBatchMode;

        return Scaffold(
          appBar: isBatchMode
              ? _buildBatchAppBar(batchState, viewModel)
              : _buildNormalAppBar(detailState, ref),
          drawer: isBatchMode ? null : const MyDrawer(),
          body: detailState.when(
            data: (state) {
              return state.when(
                initial: () => const Center(child: CircularProgressIndicator()),
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (playlist, items, isOwner) =>
                    _buildContent(playlist, items, ref, batchState, viewModel),
                error: (message) => _buildErrorState(message),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('加载失败')),
          ),
          bottomNavigationBar: isBatchMode
              ? _buildBatchActionBar(batchState, viewModel)
              : null,
        );
      },
    );
  }

  /// 构建正常模式 AppBar
  AppBar _buildNormalAppBar(AsyncValue<PlaylistDetailState> detailState, WidgetRef ref) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: detailState.valueOrNull?.maybeWhen(
        loaded: (playlist, _, _) => Text(
          playlist.name,
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        orElse: () => Text(
          '歌单详情',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
      ),
      actions: <Widget>[
        // 批量操作入口按钮
        detailState.valueOrNull?.maybeWhen(
          loaded: (_, items, _) => items.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '批量操作',
                  onPressed: () {
                    final viewModel = ref.read(
                      playlistDetailViewModelProvider(widget.playlistId).notifier,
                    );
                    viewModel.enterBatchMode();
                  },
                )
              : null,
          orElse: () => null,
        ) ?? const SizedBox.shrink(),
        ...?detailState.valueOrNull?.maybeWhen(
          loaded: (_, _, isOwner) => isOwner
              ? [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) => _onMenuAction(action, ref),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑歌单')),
                      PopupMenuItem(value: 'delete', child: Text('删除歌单')),
                    ],
                  ),
                ]
              : [],
          orElse: () => [],
        ),
        IconButton(
          icon: const Icon(Icons.home),
          iconSize: UIConstants.iconMedium,
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }

  /// 构建批量模式 AppBar
  AppBar _buildBatchAppBar(BatchOperationState batchState, PlaylistDetailViewModel viewModel) {
    return AppBar(
      leading: TextButton(
        onPressed: () => viewModel.exitBatchMode(),
        child: const Text('取消', style: TextStyle(color: Colors.white)),
      ),
      title: const Text('批量操作'),
      centerTitle: true,
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '已选 ${batchState.selectedCount} 项',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    dynamic playlist,
    List<dynamic> items,
    WidgetRef ref,
    BatchOperationState batchState,
    PlaylistDetailViewModel viewModel,
  ) {
    return Column(
      children: [
        _buildPlaylistHeader(playlist, items.length, batchState),
        const Divider(height: 1),
        if (!batchState.isInBatchMode) _buildActionButtons(ref, items),
        Expanded(
          child: items.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => viewModel.refresh(),
                  child: ListView(
                    children: [
                      SizedBox(height: 320, child: _buildEmptyState()),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => viewModel.refresh(),
                  child: _buildItemsList(items, ref, batchState, viewModel),
                ),
        ),
      ],
    );
  }

  Widget _buildPlaylistHeader(
    dynamic playlist,
    int itemCount,
    BatchOperationState batchState,
  ) {
    // 批量模式下显示选择提示信息
    if (batchState.isInBatchMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              batchState.isAllSelected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              batchState.isAllSelected ? '已全选' : '点击选择项目',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${batchState.selectedCount}/${batchState.totalItems}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final coverUrl = playlist.coverUrl as String?;
    final name = playlist.name as String;
    final description = playlist.description as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 封面
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: coverUrl != null && coverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.playlist_play, size: 40);
                      },
                    ),
                  )
                : const Icon(Icons.playlist_play, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$itemCount 首歌曲',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, List items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: Text(items.isEmpty ? '暂无可播放歌曲' : '播放全部'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: items.isEmpty ? null : () => _playAll(ref, items),
      ),
    );
  }

  Widget _buildItemsList(
    List items,
    WidgetRef ref,
    BatchOperationState batchState,
    PlaylistDetailViewModel viewModel,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemTile(
          item,
          index,
          ref,
          batchState,
          viewModel,
        );
      },
    );
  }

  Widget _buildItemTile(
    dynamic item,
    int index,
    WidgetRef ref,
    BatchOperationState batchState,
    PlaylistDetailViewModel viewModel,
  ) {
    final localPath = item.localPath as String?;
    final title = item.title as String?;
    final artist = item.artist as String?;
    final duration = item.duration as int?;
    final bvid = item.bvid as String?;

    final isLocalMusic = localPath != null && localPath.isNotEmpty;
    final isBatchMode = batchState.isInBatchMode;
    final isSelected = bvid != null && batchState.selectedBvids.contains(bvid);

    return ListTile(
      leading: isBatchMode
          ? _buildBatchLeading(isSelected, bvid, viewModel)
          : _buildNormalLeading(index, isLocalMusic),
      title: Text(
        title ?? '未知标题',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${artist ?? '未知艺术家'}${duration != null ? ' • ${_formatDuration(duration)}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isBatchMode ? null : _buildItemTrailing(item, ref),
      onTap: isBatchMode && bvid != null
          ? () => viewModel.toggleSelection(bvid)
          : () => _playItem(item, ref),
      onLongPress: !isBatchMode && bvid != null
          ? () {
              // 长按进入批量模式并选中当前项
              viewModel.enterBatchMode();
              viewModel.toggleSelection(bvid);
            }
          : null,
    );
  }

  /// 构建正常模式的 leading（序号+本地图标）
  Widget _buildNormalLeading(int index, bool isLocalMusic) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isLocalMusic)
          const Icon(Icons.folder_open, size: 14, color: Colors.green),
      ],
    );
  }

  /// 构建批量模式的 leading（复选框）
  Widget _buildBatchLeading(
    bool isSelected,
    String? bvid,
    PlaylistDetailViewModel viewModel,
  ) {
    return Checkbox(
      value: isSelected,
      onChanged: bvid != null ? (_) => viewModel.toggleSelection(bvid) : null,
    );
  }

  Widget _buildItemTrailing(dynamic item, WidgetRef ref) {
    final localPath = item.localPath as String?;
    final isLocalMusic = localPath != null && localPath.isNotEmpty;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      iconSize: 20,
      onSelected: (action) => _onItemMenuAction(action, item, ref),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'play',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 8),
              Text('播放'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_to_playlist',
          child: Row(
            children: [
              Icon(Icons.playlist_add, size: 18),
              SizedBox(width: 8),
              Text('添加到歌单'),
            ],
          ),
        ),
        if (!isLocalMusic) ...[
          const PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 8),
                Text('下载'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'favorite',
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 18),
                SizedBox(width: 8),
                Text('收藏'),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('从歌单移除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _onItemMenuAction(String action, dynamic item, WidgetRef ref) {
    final bvid = item.bvid as String?;
    final title = item.title as String?;
    final artist = item.artist as String?;
    final coverUrl = item.coverUrl as String?;
    final duration = item.duration as int?;

    switch (action) {
      case 'play':
        _playItem(item, ref);
        break;
      case 'add_to_playlist':
        if (bvid != null) {
          AudioActionMenu.show(
            context,
            bvid: bvid,
            title: title ?? '未知标题',
            artist: artist,
            coverUrl: coverUrl,
            duration: duration,
            showFavorite: false,
            showDownload: true,
          );
        }
        break;
      case 'download':
        _handleDownload(item, ref);
        break;
      case 'favorite':
        _handleFavorite(item, ref);
        break;
      case 'remove':
        _showRemoveConfirmDialog(item, ref);
        break;
    }
  }

  void _handleDownload(dynamic item, WidgetRef ref) async {
    final bvid = item.bvid as String?;
    if (bvid == null) return;

    try {
      final downloadDir = await _getDownloadDirectory();
      final sanitizedTitle = _sanitizeTitle(item.title as String? ?? '未知');
      final ext = SharedStorageService.instance.getDownloadFormat();
      final savePath = '$downloadDir$sanitizedTitle.$ext';

      await ref
          .read(downloadViewModelProvider.notifier)
          .addDownload(
            bvid: bvid,
            savePath: savePath,
            title: item.title,
            artist: item.artist,
            coverUrl: item.coverUrl,
          );
      if (mounted) {
        SnackbarHelper.showSuccess(context, '已添加到下载队列');
      }
    } catch (e) {
      AppLogger.error('PlaylistDetailPage', '下载失败: $e');
      if (mounted) {
        SnackbarHelper.showError(context, '下载失败: $e');
      }
    }
  }

  Future<String> _getDownloadDirectory() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        throw Exception('系统下载目录不可用');
      }

      final appDownloadDir = Directory(
        '${downloadDir.path}${path.separator}ListenVision',
      );
      if (!await appDownloadDir.exists()) {
        await appDownloadDir.create(recursive: true);
      }

      return '${appDownloadDir.path}${path.separator}';
    } catch (e) {
      AppLogger.error('PlaylistDetailPage', '获取下载目录失败: $e');
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory(
          '${docDir.path}${path.separator}Downloads',
        );
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return '${fallbackDir.path}${path.separator}';
      } catch (e) {
        AppLogger.error('PlaylistDetailPage', '获取备用目录失败: $e');
        return '';
      }
    }
  }

  String _sanitizeTitle(String input) {
    const pattern =
        r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""'
        '·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _handleFavorite(dynamic item, WidgetRef ref) async {
    final bvid = item.bvid as String?;
    if (bvid == null) return;

    try {
      // 确保 Track 记录存在
      final trackDao = ref.read(trackDaoProvider);
      var track = await trackDao.getBySourceId(bvid);
      track ??= await trackDao.saveFromAudio(Audio(
          id: bvid,
          title: (item.title as String?)?.isNotEmpty == true ? item.title as String : '未知标题',
          artist: item.artist as String?,
          duration: item.duration as int?,
          coverUrl: item.coverUrl as String?,
        ));

      final added = await ref.read(favoriteTracksProvider.notifier).toggle(
        bvid,
        title: item.title as String?,
        artist: item.artist as String?,
        duration: item.duration as int?,
        coverUrl: item.coverUrl as String?,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, added ? '已添加到我喜欢' : '已从我喜欢移除');
      }
    } catch (e) {
      AppLogger.error('PlaylistDetailPage', '收藏失败: $e');
    }
  }

  void _showRemoveConfirmDialog(dynamic item, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从歌单移除'),
        content: Text('确定要从歌单中移除 "${item.title ?? '此歌曲'}" 吗？'),
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
    ).then((confirmed) {
      if (confirmed == true) {
        final bvid = item.bvid as String?;
        if (bvid != null && mounted) {
          ref
              .read(playlistDetailViewModelProvider(widget.playlistId).notifier)
              .removeItem(bvid);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已移除 "${item.title ?? '歌曲'}"'),
              action: SnackBarAction(
                label: '撤销',
                onPressed: () {
                  ref
                      .read(playlistDetailViewModelProvider(widget.playlistId).notifier)
                      .undoRemove();
                },
              ),
            ),
          );
        }
      }
    });
  }

  /// 播放歌单项（支持在线和本地音乐）
  Future<void> _playItem(dynamic item, WidgetRef ref) async {
    final bvid = item.bvid as String?;
    final localPath = item.localPath as String?;

    // 如果有本地路径，尝试通过 localId 播放本地音乐
    if (localPath != null && localPath.isNotEmpty) {
      await _playLocalMusic(localPath, ref);
      return;
    }

    // 否则使用 bvid 播放在线音乐
    if (bvid != null) {
      // 调用 ViewModel 的 playItem 方法
      final success = await ref
          .read(playlistDetailViewModelProvider(widget.playlistId).notifier)
          .playItem(bvid);

      if (success && mounted) {
        SnackbarHelper.showPlaying(
          context,
          item.title as String? ?? '未知标题',
          artist: item.artist as String?,
        );
      } else if (!success && mounted) {
        SnackbarHelper.showError(context, '播放失败，请重试');
      }
    }
  }

  /// 播放本地音乐（通过 localPath 查找对应的 LocalAudio）
  Future<bool> _playLocalMusic(String localPath, WidgetRef ref) async {
    try {
      AppLogger.debug('PlaylistDetailPage', '开始播放本地音乐: $localPath');

      // 从 LocalMusicViewModel 获取所有本地音乐
      final localMusicAsync = ref.read(localMusicViewModelProvider);

      final localAudio = await localMusicAsync.whenOrNull(
        data: (state) async {
          return state.map(
            initial: (_) => null,
            loading: (_) => null,
            loaded: (data) {
              AppLogger.debug(
                'PlaylistDetailPage',
                '本地音乐列表数量: ${data.audios.length}',
              );
              try {
                final found = data.audios.firstWhere(
                  (audio) => audio.filePath == localPath,
                );
                AppLogger.debug(
                  'PlaylistDetailPage',
                  '找到本地音频: ${found.title}, id: ${found.id}',
                );
                return found;
              } catch (_) {
                AppLogger.warn('PlaylistDetailPage', '未找到匹配的本地音频');
                return null;
              }
            },
            importing: (_) => null,
            error: (_) => null,
          );
        },
      );

      if (localAudio == null) {
        AppLogger.warn('PlaylistDetailPage', '本地音乐未找到: $localPath');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('本地音乐未找到，请重新导入')));
        }
        return false;
      }

      // 直接播放本地音频
      final playable = LocalPlayable(localAudio);
      await ref
          .read(playbackViewModelProvider.notifier)
          .play(playable);

      // 显示播放提示
      if (mounted) {
        SnackbarHelper.showPlaying(
          context,
          localAudio.title,
          artist: localAudio.artist,
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('PlaylistDetailPage', '播放本地音乐失败: $e');
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
      return false;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '歌单暂无歌曲',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref
                .read(
                  playlistDetailViewModelProvider(widget.playlistId).notifier,
                )
                .refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 播放全部
  Future<void> _playAll(WidgetRef ref, List items) async {
    if (items.isEmpty) return;

    // 显示加载状态
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('正在加载播放列表...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // 调用 ViewModel 的 playAll 方法
    final success = await ref
        .read(playlistDetailViewModelProvider(widget.playlistId).notifier)
        .playAll();

    if (!success && mounted) {
      SnackbarHelper.showError(context, '播放失败，请重试');
    }
  }

  void _onMenuAction(String action, WidgetRef ref) {
    switch (action) {
      case 'edit':
        _showEditDialog(ref);
        break;
      case 'delete':
        _showDeleteConfirmDialog(ref);
        break;
    }
  }

  void _showEditDialog(WidgetRef ref) {
    final playlist = ref
        .read(playlistDetailViewModelProvider(widget.playlistId))
        .valueOrNull
        ?.maybeWhen(loaded: (playlist, _, _) => playlist, orElse: () => null);
    if (playlist == null) return;

    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(
      text: playlist.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '歌单名称'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述（可选）'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(
                    playlistDetailViewModelProvider(widget.playlistId).notifier,
                  )
                  .updatePlaylist(
                    name: nameController.text,
                    description: descController.text.isEmpty
                        ? null
                        : descController.text,
                  );
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                if (success) {
                  // ignore: use_build_context_synchronously
                  SnackbarHelper.showSuccess(context, '保存成功');
                } else {
                  // ignore: use_build_context_synchronously
                  SnackbarHelper.showError(context, '保存失败');
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: const Text('确定要删除这个歌单吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(
                    playlistDetailViewModelProvider(widget.playlistId).notifier,
                  )
                  .deletePlaylist();
              if (mounted) {
                if (success) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context); // 关闭对话框
                  // ignore: use_build_context_synchronously
                  context.pop(); // 返回上一页
                } else {
                  // ignore: use_build_context_synchronously
                  SnackbarHelper.showError(context, '删除失败');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  // ==================== 批量操作功能 ====================

  /// 构建批量操作底部栏
  Widget _buildBatchActionBar(
    BatchOperationState batchState,
    PlaylistDetailViewModel viewModel,
  ) {
    final hasSelection = batchState.hasSelection;
    final isAllSelected = batchState.isAllSelected;

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
            // 全选/取消全选按钮
            TextButton.icon(
              onPressed: () => viewModel.toggleSelectAll(),
              icon: Icon(
                isAllSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
              label: Text(isAllSelected ? '取消全选' : '全选'),
            ),
            const Spacer(),
            // 删除按钮
            ElevatedButton.icon(
              onPressed: hasSelection
                  ? () => _showBatchRemoveConfirmDialog(batchState, viewModel)
                  : null,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text('删除(${batchState.selectedCount})'),
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

  /// 显示批量移除确认对话框
  void _showBatchRemoveConfirmDialog(
    BatchOperationState batchState,
    PlaylistDetailViewModel viewModel,
  ) {
    final selectedCount = batchState.selectedCount;
    final selectedBvids = batchState.selectedBvids.toList();

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量移除'),
        content: Text('确定要从歌单中移除选中的 $selectedCount 首歌曲吗？'),
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
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        // 显示进度对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final result = await viewModel.batchRemoveItems(selectedBvids);

        if (mounted) {
          Navigator.pop(context); // 关闭进度对话框

          // 显示结果提示
          if (result.isAllSuccess) {
            SnackbarHelper.showSuccess(
              context,
              '成功移除 ${result.success} 首歌曲',
            );
            viewModel.exitBatchMode();
          } else if (result.isPartialSuccess) {
            SnackbarHelper.showWarning(
              context,
              '移除完成：成功 ${result.success} 首，失败 ${result.failed} 首',
            );
          } else {
            SnackbarHelper.showError(
              context,
              '移除失败：${result.failedItems.length} 首歌曲未能移除',
            );
          }
        }
      }
    });
  }
}
