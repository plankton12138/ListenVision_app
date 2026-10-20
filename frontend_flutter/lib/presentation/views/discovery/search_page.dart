import 'package:listenvision/core/utils/permission_helper.dart';
import 'package:dio/dio.dart';
import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/state/state_utils.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/presentation/widgets/video_pages_sheet.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/search_suggestion.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:listenvision/presentation/widgets/audio/audio_action_menu.dart';
import 'package:listenvision/presentation/widgets/common/download_status_indicator.dart';
import 'package:listenvision/presentation/widgets/common/marquee_text.dart';
import 'package:listenvision/presentation/widgets/common/snackbar_helper.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:listenvision/core/storage/shared_storage_service.dart';
import 'package:listenvision/core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 搜索页面
///
/// 仅支持B站网络搜索，用于发现新的音频内容
/// 本地音频通过"本地音乐"歌单单独管理
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _resultRequestId = 0;
  CancelToken? _resultToken;

  @override
  void dispose() {
    _resultRequestId++;
    _resultToken?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // 调用 SearchViewModel 执行B站搜索
    ref.read(searchViewModelProvider.notifier).search(query);
  }

  void _onResultTap(SearchResultItem item) async {
    final requestId = ++_resultRequestId;
    _resultToken?.cancel();
    final token = _resultToken = CancelToken();
    try {
      // B站搜索 API 不返回 videos 字段，需通过视频详情 API 获取分P数量
      final api = ref.read(bilibiliApiServiceProvider);
      final pages = await api.getVideoPages(item.bvid, cancelToken: token);

      if (!mounted || requestId != _resultRequestId || token.isCancelled) {
        return;
      }

      if (pages.length <= 1) {
        // 单P视频，直接播放
        await _playSingleAudio(
          bvid: item.bvid,
          title: item.title,
          artist: item.author,
          coverUrl: item.coverUrl,
          duration: item.duration,
        );
        return;
      }

      // 多P视频，弹出分P选择面板
      final videoCount = pages.length;
      VideoPagesSheet.show(
        context: context,
        title: item.title,
        pages: pages,
        totalDuration: item.duration,
        onPlayPage: (page) {
          final episodeTitle = _extractEpisodeTitle(item.title, page.title);
          _playSingleAudio(
            bvid: item.bvid,
            title: episodeTitle,
            albumTitle: item.title,
            artist: item.author,
            coverUrl: item.coverUrl,
            duration: page.duration,
            cid: page.cid,
            videos: videoCount,
          );
        },
        onPlayAll: () {
          _playAllPages(
            bvid: item.bvid,
            albumTitle: item.title,
            artist: item.author,
            coverUrl: item.coverUrl,
            pages: pages,
            videos: videoCount,
          );
        },
        onDownloadPage: (page) {
          final episodeTitle = _extractEpisodeTitle(item.title, page.title);
          _downloadPage(
            bvid: item.bvid,
            cid: page.cid,
            title: episodeTitle,
            albumTitle: item.title,
            artist: item.author,
            coverUrl: item.coverUrl,
          );
        },
        onDownloadAll: () {
          _downloadAllPages(
            bvid: item.bvid,
            title: item.title,
            artist: item.author,
            coverUrl: item.coverUrl,
            pages: pages,
          );
        },
      );
    } catch (e) {
      if (mounted && requestId == _resultRequestId && !token.isCancelled) {
        // 降级：API 失败时作为单P播放
        await _playSingleAudio(
          bvid: item.bvid,
          title: item.title,
          artist: item.author,
          coverUrl: item.coverUrl,
          duration: item.duration,
        );
      }
    }
  }

  /// 播放单首音频
  Future<void> _playSingleAudio({
    required String bvid,
    required String title,
    String? albumTitle,
    String? artist,
    String? coverUrl,
    int? duration,
    int? cid,
    int videos = 1,
  }) async {
    try {
      final audio = Audio(
        id: bvid,
        title: title,
        albumTitle: albumTitle,
        artist: artist,
        coverUrl: coverUrl,
        duration: duration,
        cid: cid,
        videos: videos,
      );

      final playable = OnlinePlayable.withProxyUrl(audio);
      final queueNotifier = ref.read(queueViewModelProvider.notifier);
      await queueNotifier.add(playable, playImmediately: true);

      final queueState = ref.read(queueViewModelProvider);
      final queueIndex = queueState.queue?.currentIndex ?? -1;
      final tracks = queueState.queue?.tracks;
      if (queueIndex >= 0 && tracks != null && queueIndex < tracks.length) {
        ref
            .read(playbackViewModelProvider.notifier)
            .play(tracks[queueIndex], index: queueIndex);
      }

      if (mounted) {
        SnackbarHelper.showPlaying(context, title, artist: artist);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }

  /// 播放所有分P
  Future<void> _playAllPages({
    required String bvid,
    required String albumTitle,
    String? artist,
    String? coverUrl,
    required List<AudioPage> pages,
    int videos = 1,
  }) async {
    try {
      final queueNotifier = ref.read(queueViewModelProvider.notifier);

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final episodeTitle = _extractEpisodeTitle(albumTitle, page.title);
        final audio = Audio(
          id: bvid,
          title: episodeTitle,
          albumTitle: albumTitle,
          artist: artist,
          coverUrl: coverUrl,
          duration: page.duration,
          cid: page.cid,
          videos: videos,
        );
        final playable = OnlinePlayable.withProxyUrl(audio);
        // 第一首立即播放，其余仅加入队列
        await queueNotifier.add(playable, playImmediately: i == 0);
      }

      if (mounted) {
        SnackbarHelper.showToast('已添加 ${pages.length} 首到播放队列');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
  }

  /// 获取下载目录路径
  Future<String> _getDownloadDirectory() async {
    if (!await PermissionHelper.requestManageStoragePermission()) {
      throw const FileSystemException('需要存储权限才能保存到下载目录');
    }
    final downloadDir = await getDownloadsDirectory();
    if (downloadDir == null) {
      throw Exception('系统下载目录不可用');
    }
    final appDownloadDir = Directory(
      '${downloadDir.path}${p.separator}ListenVision',
    );
    if (!await appDownloadDir.exists()) {
      await appDownloadDir.create(recursive: true);
    }
    return '${appDownloadDir.path}${p.separator}';
  }

  /// 下载单P音频
  Future<void> _downloadPage({
    required String bvid,
    required int cid,
    required String title,
    String? albumTitle,
    String? artist,
    String? coverUrl,
  }) async {
    try {
      final downloadNotifier = ref.read(downloadViewModelProvider.notifier);
      final sanitizedTitle = title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .trim();
      final ext = SharedStorageService.instance.getDownloadFormat();
      final downloadDir = await _getDownloadDirectory();
      final savePath = '$downloadDir$sanitizedTitle.$ext';

      await downloadNotifier.addDownload(
        bvid: bvid,
        cid: cid,
        savePath: savePath,
        title: title,
        albumTitle: albumTitle,
        artist: artist,
        coverUrl: coverUrl,
      );
      if (mounted) {
        SnackbarHelper.showToast('已添加到下载队列', color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '下载失败: $e');
      }
    }
  }

  /// 下载所有分P
  Future<void> _downloadAllPages({
    required String bvid,
    required String title,
    String? artist,
    String? coverUrl,
    required List<AudioPage> pages,
  }) async {
    try {
      final downloadNotifier = ref.read(downloadViewModelProvider.notifier);
      final ext = SharedStorageService.instance.getDownloadFormat();
      final downloadDir = await _getDownloadDirectory();
      int successCount = 0;

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final episodeTitle = _extractEpisodeTitle(title, page.title);
        final sanitizedTitle = episodeTitle
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
            .trim();
        final savePath = '$downloadDir$sanitizedTitle.$ext';

        try {
          await downloadNotifier.addDownload(
            bvid: bvid,
            cid: page.cid,
            savePath: savePath,
            title: episodeTitle,
            albumTitle: title,
            artist: artist,
            coverUrl: coverUrl,
          );
          successCount++;
        } catch (_) {
          // 单P失败不影响其他分P
        }
      }

      if (mounted) {
        SnackbarHelper.showToast('已添加 $successCount/${pages.length} 首到下载队列');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '下载失败: $e');
      }
    }
  }

  /// 从分集标题中提取纯净的分集名（移除视频标题的前缀）
  ///
  /// 部分UP主在每集的 part 前加了视频标题，例如：
  ///   视频标题: "【陶喆】华语R&B...合集 - 无损音乐合集"
  ///   分集标题: "【陶喆】华语R&B...合集 - 005. 陶喆-Melody"
  ///   提取后:   "005. 陶喆-Melody"
  String _extractEpisodeTitle(String videoTitle, String pageTitle) {
    if (pageTitle == videoTitle) return pageTitle;

    // 找到最长公共前缀
    int commonLen = 0;
    final maxLen = pageTitle.length < videoTitle.length
        ? pageTitle.length
        : videoTitle.length;
    for (int i = 0; i < maxLen; i++) {
      if (pageTitle[i] != videoTitle[i]) break;
      commonLen = i + 1;
    }

    // 公共前缀足够长（≥5字符）且剩余部分非空，则剥离
    if (commonLen >= 5) {
      String episode = pageTitle.substring(commonLen).trimLeft();
      episode = episode.replaceFirst(RegExp(r'^[-–—\s]+'), '').trim();
      if (episode.isNotEmpty) return episode;
    }

    return pageTitle;
  }

  /// 显示操作菜单
  void _showActionMenu(SearchResultItem item) {
    AudioActionMenu.show(
      context,
      bvid: item.bvid,
      title: item.title,
      artist: item.author,
      coverUrl: item.coverUrl,
      duration: item.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '搜索B站',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: '搜索B站音频...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (value) {
                      // 获取搜索建议
                      ref
                          .read(searchViewModelProvider.notifier)
                          .getSearchSuggestions(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          // 平台指示器（简洁显示）
          _buildPlatformIndicator(),
          // 搜索结果或状态
          Expanded(
            child: searchState.when(
              data: (state) => state.map(
                initial: (_) => _buildInitialState(),
                loading: (_) =>
                    const Center(child: CircularProgressIndicator()),
                resultsLoaded: (data) {
                  // DEBUG: 打印搜索结果变化
                  AppLogger.debug(
                    'SearchPage',
                    '渲染结果: page=${data.currentPage}, results.length=${data.results.length}, first bvid=${data.results.isNotEmpty ? data.results.first.bvid : "empty"}',
                  );
                  return _buildResultsList(
                    data.results,
                    data.currentPage,
                    data.pageSize,
                    data.totalCount,
                    data.hasMore,
                  );
                },
                idle: (data) =>
                    _buildIdleState(data.searchHistory, data.suggestions),
                error: (data) => Center(child: Text('错误: ${data.message}')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('错误: $err')),
            ),
          ),
        ],
      ),
    );
  }

  /// 初始状态
  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('请输入关键词搜索B站音频'),
        ],
      ),
    );
  }

  /// 平台指示器（简洁显示当前平台）
  Widget _buildPlatformIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_library,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bilibili',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '搜索B站视频音频内容',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 搜索结果列表
  Widget _buildResultsList(
    List<SearchResultItem> results,
    int currentPage,
    int pageSize,
    int totalCount,
    bool hasMore,
  ) {
    if (results.isEmpty) {
      return const Center(child: Text('未找到结果'));
    }

    return Column(
      children: [
        // 结果列表
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return ListTile(
                leading: item.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ImageHelper.cachedNetworkImage(
                          item.coverUrl!,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 80,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note),
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                title: Row(
                  children: [
                    Expanded(
                      child: MarqueeText(item.title, maxLines: 2),
                    ),
                    if (item.videos > 1)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '共${item.videos}P',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: MarqueeText(
                        '${item.author ?? '未知UP主'} · ${_formatDuration(item.duration)}',
                      ),
                    ),
                    // 下载状态指示器
                    DownloadStatusIndicator(bvid: item.bvid, size: 16),
                  ],
                ),
                onTap: () => _onResultTap(item),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showActionMenu(item),
                  tooltip: '更多操作',
                ),
              );
            },
          ),
        ),
        // 分页控制栏
        _buildPaginationBar(currentPage, totalCount, pageSize, hasMore),
      ],
    );
  }

  /// 分页控制栏
  Widget _buildPaginationBar(
    int currentPage,
    int totalCount,
    int pageSize,
    bool hasMore,
  ) {
    // 格式化页码显示
    String pageText;
    if (totalCount > 0) {
      final totalPages = (totalCount / pageSize).ceil();
      pageText = '$currentPage/$totalPages';
    } else if (hasMore) {
      pageText = '$currentPage / ...';
    } else {
      pageText = '$currentPage';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => _loadPage(currentPage - 1)
                : null,
            tooltip: '上一页',
          ),
          // 页码信息
          Text(pageText, style: const TextStyle(fontSize: 16)),
          // 下一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasMore ? () => _loadPage(currentPage + 1) : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }

  /// 加载指定页
  void _loadPage(int page) {
    AppLogger.debug('SearchPage', '_loadPage called: page=$page');
    final currentState = ref.read(searchViewModelProvider);
    final query =
        currentState.valueOrNull?.map(
          initial: (_) => '',
          loading: (_) => '',
          resultsLoaded: (state) => state.query,
          idle: (_) => '',
          error: (_) => '',
        ) ??
        '';
    AppLogger.debug('SearchPage', 'query=$query');
    if (query.isNotEmpty) {
      AppLogger.debug('SearchPage', '调用 search with page=$page');
      ref.read(searchViewModelProvider.notifier).search(query, page: page);
    }
  }

  /// 空闲状态（搜索历史和搜索建议）
  Widget _buildIdleState(
    List<String> history,
    List<SearchSuggestion> suggestions,
  ) {
    return ListView(
      children: [
        // 搜索建议
        if (suggestions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('搜索建议', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...suggestions.map(
            (s) => ListTile(
              leading: const Icon(Icons.search, color: Colors.grey),
              title: _buildHighlightedText(s.name, s.value),
              dense: true,
              onTap: () {
                _searchController.text = s.value;
                _performSearch();
              },
            ),
          ),
        ],
        // 搜索历史
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(searchViewModelProvider.notifier)
                        .clearSearchHistory();
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          ...history.map(
            (h) => ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(h),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  ref
                      .read(searchViewModelProvider.notifier)
                      .removeFromHistory(h);
                },
              ),
              dense: true,
              onTap: () {
                _searchController.text = h;
                _performSearch();
              },
            ),
          ),
        ],
        // 为空状态
        if (history.isEmpty && suggestions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '输入关键词开始搜索B站音频',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(String htmlText, String plainText) {
    final regex = RegExp(r'<em class="suggest_high_light">(.*?)</em>');
    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in regex.allMatches(htmlText)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: htmlText.substring(lastEnd, match.start),
            style: const TextStyle(color: Colors.black87),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < htmlText.length) {
      spans.add(
        TextSpan(
          text: htmlText.substring(lastEnd),
          style: const TextStyle(color: Colors.black87),
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(plainText);
    }

    return RichText(
      text: TextSpan(children: spans, style: const TextStyle(fontSize: 16)),
    );
  }

  /// 格式化时长
  String _formatDuration(int? seconds) => AudioPage.formatDuration(seconds);
}
