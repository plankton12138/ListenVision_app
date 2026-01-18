import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/bilibili_provider.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// 搜索页面
///
/// 搜索B站视频并支持下载
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final DownloadManager _downloadManager = DownloadManager();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 1;

  // 从 BilibiliProvider 获取数据（使用 Builder 避免在事件处理中使用 watch）
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _searchError;

  // 保存 Provider 引用，避免在 dispose 中使用 context
  BilibiliProvider? _bilibiliProvider;

  @override
  void initState() {
    super.initState();
    _downloadManager.initDatabase();

    // 从 Provider 获取初始状态，并保存引用
    _bilibiliProvider = context.read<BilibiliProvider>();
    _results = _bilibiliProvider!.searchResults;
    _isLoading = _bilibiliProvider!.isSearching;
    _searchError = _bilibiliProvider!.searchError;

    // 监听 Provider 变化
    _bilibiliProvider!.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    // 使用保存的引用，而不是通过 context 获取
    _bilibiliProvider?.removeListener(_onProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted || _bilibiliProvider == null) return;
    setState(() {
      _results = _bilibiliProvider!.searchResults;
      _isLoading = _bilibiliProvider!.isSearching;
      _searchError = _bilibiliProvider!.searchError;
    });
  }

  /// 搜索B站视频
  ///
  /// Phase 1 改进：通过后端API搜索，不再直接调用B站
  Future<void> _searchBilibili(BuildContext context, String keyword, {int page = 1}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 最大页数限制
    if (page > 50) {
      showMySnackBar(context, '已达到最大页数', Colors.red, 1000);
      return;
    }

    setState(() {
      _currentPage = page;
    });

    final provider = context.read<BilibiliProvider>();
    final success = await provider.searchBilibili(keyword, page: page);

    if (!success && mounted) {
      final error = provider.searchError ?? '未知错误';
      showMySnackBar(context, '搜索失败: $error', Colors.red, 2000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '搜索',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(context),
          // 搜索结果
          _buildSearchResults(),
        ],
      ),
      drawer: const MyDrawer(),
      persistentFooterButtons: _results.isEmpty
          ? [] // 无搜索结果
          : [
              // 页码显示
              Text(
                '第 $_currentPage 页',
                style: const TextStyle(color: Colors.black),
              ),
              // 上一页按钮
              if (_currentPage > 1)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    _searchBilibili(context, _searchController.text, page: _currentPage - 1);
                  },
                  child: const Text(
                    '上一页',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              // 下一页按钮
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  _searchBilibili(context, _searchController.text, page: _currentPage + 1);
                },
                child: const Text(
                  '下一页',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Flexible(
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: '搜索视频',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入搜索关键词';
                  }
                  return null;
                },
                onFieldSubmitted: (value) {
                  _searchBilibili(context, value);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _searchBilibili(context, _searchController.text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: $_searchError'),
            ElevatedButton(
              onPressed: () {
                context.read<BilibiliProvider>().clearError();
              },
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('未找到结果'));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final item = _results[index];
          // 清理HTML标签
          String rawTitle = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
          // 后端返回 'cover' 字段，不是 'pic'
          String picUrl = item['cover'] ?? item['pic'] ?? '';

          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: ListTile(
              // Phase 1 改进：使用代理URL加载图片，解决防盗链问题
              leading: Image.network(
                context.read<BilibiliProvider>().getProxyImageUrl(
                  picUrl.startsWith('http') ? picUrl : 'https:$picUrl',
                ),
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
              title: SizedBox(
                height: 35,
                child: Text(
                  rawTitle,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              subtitle: Text(
                'UP: ${item['author'] ?? '未知'} \n播放: ${item['play'] ?? '0'} \n时长: ${item['duration'] ?? '--:--'}',
                style: const TextStyle(fontSize: 8),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // 优先使用 bvid，如果不存在则使用 arcurl
                  String bvid = item['bvid'] ?? '';
                  if (bvid.isNotEmpty) {
                    // 构造标准B站视频URL
                    _downloadManager.addDownload(context, 'https://www.bilibili.com/video/$bvid');
                  } else {
                    String url = item['arcurl'] ?? item['url'] ?? '';
                    if (url.isNotEmpty) {
                      _downloadManager.addDownload(context, url);
                    }
                  }
                },
              ),
              onTap: () async {
                String url = item['arcurl'] ?? item['url'] ?? '';
                if (url.isEmpty && item['bvid'] != null) {
                  url = 'https://www.bilibili.com/video/${item['bvid']}';
                }
                if (url.isNotEmpty) {
                  final Uri uri = Uri.parse(url);
                  await launchUrl(uri);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
