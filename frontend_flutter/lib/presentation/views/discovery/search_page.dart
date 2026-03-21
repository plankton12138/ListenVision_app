import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/core/state/state_utils.dart';
import 'package:listenvision/core/utils/app_logger.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/search_suggestion.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:listenvision/presentation/widgets/audio/audio_action_menu.dart';
import 'package:listenvision/presentation/widgets/common/download_status_indicator.dart';
import 'package:listenvision/presentation/widgets/common/snackbar_helper.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
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

  @override
  void dispose() {
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
    try {
      // 创建 Audio 对象
      final audio = Audio(
        id: item.bvid,
        title: item.title,
        artist: item.author,
        coverUrl: item.coverUrl,
        duration: item.duration,
      );

      // 创建 OnlinePlayable 对象（自动生成代理 URL）并添加到队列
      final playable = OnlinePlayable.withProxyUrl(audio);
      await ref.read(queueViewModelProvider.notifier).add(playable, playImmediately: true);

      // 通过 QueueViewModel 触发播放（避免与 PlayerViewModel 直接调用产生竞态）
      final queueIndex = ref.read(queueViewModelProvider).queue.length - 1;
      if (queueIndex >= 0) {
        await ref.read(queueViewModelProvider.notifier).playAt(queueIndex);
      }

      // 显示播放提示
      if (mounted) {
        SnackbarHelper.showPlaying(context, item.title, artist: item.author);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '播放失败: $e');
      }
    }
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
                      if (value.length >= 2) {
                        ref
                            .read(searchViewModelProvider.notifier)
                            .getSearchSuggestions(value);
                      }
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
                loading: (_) => const Center(child: CircularProgressIndicator()),
                resultsLoaded: (data) {
                  // DEBUG: 打印搜索结果变化
                  AppLogger.debug('SearchPage', '渲染结果: page=${data.currentPage}, results.length=${data.results.length}, first bvid=${data.results.isNotEmpty ? data.results.first.bvid : "empty"}');
                  return _buildResultsList(
                    data.results,
                    data.currentPage,
                    data.pageSize,
                    data.totalCount,
                    data.hasMore,
                  );
                },
                idle: (data) => _buildIdleState(
                  data.searchHistory,
                  data.suggestions,
                ),
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

    // 计算总页数
    final totalPages = totalCount > 0
        ? (totalCount / pageSize).ceil()
        : (hasMore ? currentPage + 1 : currentPage);

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
                title: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.author ?? '未知UP主'} · ${_formatDuration(item.duration)}',
                        overflow: TextOverflow.ellipsis,
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
        _buildPaginationBar(currentPage, totalPages, hasMore),
      ],
    );
  }

  /// 分页控制栏
  Widget _buildPaginationBar(int currentPage, int totalPages, bool hasMore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
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
          Text(
            '$currentPage/$totalPages',
            style: const TextStyle(fontSize: 16),
          ),
          // 下一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasMore
                ? () => _loadPage(currentPage + 1)
                : null,
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
    final query = currentState.valueOrNull?.map(
      initial: (_) => '',
      loading: (_) => '',
      resultsLoaded: (state) => state.query,
      idle: (_) => '',
      error: (_) => '',
    ) ?? '';
    AppLogger.debug('SearchPage', 'query=$query');
    if (query.isNotEmpty) {
      AppLogger.debug('SearchPage', '调用 search with page=$page');
      ref.read(searchViewModelProvider.notifier).search(query, page: page);
    }
  }


  /// 空闲状态（搜索历史和搜索建议）
  Widget _buildIdleState(List<String> history, List<SearchSuggestion> suggestions) {
    return ListView(
      children: [
        // 搜索建议
        if (suggestions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '搜索建议',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...suggestions.map((s) => ListTile(
                leading: const Icon(Icons.search, color: Colors.grey),
                title: _buildHighlightedText(s.name, s.value),
                dense: true,
                onTap: () {
                  _searchController.text = s.value;
                  _performSearch();
                },
              )),
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
          ...history.map((h) => ListTile(
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
              )),
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
        spans.add(TextSpan(
          text: htmlText.substring(lastEnd, match.start),
          style: const TextStyle(color: Colors.black87),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < htmlText.length) {
      spans.add(TextSpan(
        text: htmlText.substring(lastEnd),
        style: const TextStyle(color: Colors.black87),
      ));
    }

    if (spans.isEmpty) {
      return Text(plainText);
    }

    return RichText(
      text: TextSpan(children: spans, style: const TextStyle(fontSize: 16)),
    );
  }

  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
