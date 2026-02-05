import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
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

  void _onResultTap(SearchResultItem item) {
    // 导航到播放器页面，播放B站音频
    context.push('/player?bvid=${item.bvid}');
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
              initial: () => _buildInitialState(),
              loading: () => const Center(child: CircularProgressIndicator()),
              resultsLoaded: (results, query, platform) =>
                  _buildResultsList(results),
              idle: (history, suggestions, platform) =>
                  _buildIdleState(history, suggestions),
              error: (message) => Center(child: Text('错误: $message')),
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
  Widget _buildResultsList(List<SearchResultItem> results) {
    if (results.isEmpty) {
      return const Center(child: Text('未找到结果'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: item.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.coverUrl!,
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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
          subtitle: Text(
            '${item.author ?? '未知UP主'} · ${_formatDuration(item.duration)}',
          ),
          onTap: () => _onResultTap(item),
        );
      },
    );
  }

  /// 空闲状态（搜索历史和搜索建议）
  Widget _buildIdleState(List<String> history, List<String> suggestions) {
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
                title: Text(s),
                dense: true,
                onTap: () {
                  _searchController.text = s;
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

  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
