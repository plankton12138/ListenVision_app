import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/domain/entities/domain_types.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:demo/core/utils/app_logger.dart';

/// 播放历史页面
///
/// 展示用户的播放历史记录
/// 完整的播放历史管理功能
class PlayHistoryPage extends StatefulWidget {
  const PlayHistoryPage({super.key});

  @override
  _PlayHistoryPageState createState() => _PlayHistoryPageState();
}

/// 筛选类型枚举
enum HistoryFilterType {
  all,      // 全部
  today,    // 今天
  week,     // 本周
  month,    // 本月
}

class _PlayHistoryPageState extends State<PlayHistoryPage> {
  bool _isLoading = false;
  String? _errorMessage;

  // 搜索和筛选状态
  String _searchQuery = '';
  HistoryFilterType _filterType = HistoryFilterType.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 延迟到 build 完成后检查登录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 检查登录状态，未登录则跳转到登录页
  void _checkLoginAndLoad() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      DialogHelper.showSnackBar(context, '请先登录', backgroundColor: Colors.orange, duration: 1500);
      context.go('/login');
      return;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final historyProvider = context.read<PlayHistoryProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await historyProvider.initialize();
    } catch (e) {
      AppLogger.error('PlayHistoryPage', '初始化失败: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有播放历史吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();

    try {
      await historyProvider.clearHistory(authProvider.user!.token);
      if (mounted) {
        DialogHelper.showSnackBar(context, '播放历史已清空', backgroundColor: Colors.green, duration: 1500);
      }
    } catch (e) {
      AppLogger.error('PlayHistoryPage', '清空播放历史失败: $e');
      if (mounted) {
        DialogHelper.showSnackBar(context, '清空失败: $e', backgroundColor: Colors.red, duration: 2000);
      }
    }
  }

  /// 播放历史记录项
  ///
  /// 支持在线音频和本地音频的播放
  Future<void> _playHistoryItem(PlayHistoryItem item) async {
    final audioProvider = context.read<AudioProvider>();
    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();

    try {
      DialogHelper.showSnackBar(context, '正在加载...', backgroundColor: Colors.blue, duration: 1000);

      // 判断是本地音频还是在线音频
      final audioId = item.audio.id;
      final isLocalAudio = _isLocalPath(audioId);

      if (isLocalAudio) {
        // 本地音频：检查文件是否存在
        final file = File(audioId);
        if (!file.existsSync()) {
          if (mounted) {
            DialogHelper.showSnackBar(context, '文件不存在: ${audioId.split(RegExp(r'[\\/]')).last}', backgroundColor: Colors.red, duration: 2000);
          }
          return;
        }

        // 播放本地音频
        await audioProvider.loadAudio(audioId);

        if (mounted) {
          DialogHelper.showSnackBar(context, '开始播放: ${item.audio.title}', backgroundColor: Colors.green, duration: 1500);
        }
      } else {
        // 在线音频：使用后端代理URL播放（而不是直接使用B站原始URL）
        // MPV 无法直接播放 B站的 .m4s 流（防盗链、URL过长等问题）
        final proxyUrl = '${ApiConstants.fullBaseUrl}/bilibili/proxy/audio/$audioId';

        // 播放在线音频
        await audioProvider.playOnlineAudio(
          audio: item.audio,
          proxyUrl: proxyUrl,
        );

        // 记录播放历史（已登录用户）
        if (authProvider.isLoggedIn) {
          await historyProvider.recordPlay(
            bvid: item.audio.id,
            title: item.audio.title,
            artist: item.audio.artist,
            coverUrl: item.audio.coverUrl,
            duration: item.audio.duration,
          );
        }

        if (mounted) {
          DialogHelper.showSnackBar(context, '开始播放: ${item.audio.title}', backgroundColor: Colors.green, duration: 1500);
        }
      }
    } catch (e) {
      AppLogger.error('PlayHistoryPage', '播放失败: $e');
      if (mounted) {
        DialogHelper.showSnackBar(context, '播放失败: $e', backgroundColor: Colors.red, duration: 2000);
      }
    }
  }

  /// 处理收藏按钮点击
  Future<void> _handleFavoriteToggle(
    BuildContext context,
    PlaylistProvider playlistProvider,
    PlayHistoryItem item,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final audio = item.audio;

    final wasFavorited = playlistProvider.isFavorited(audio.id);

    try {
      await playlistProvider.toggleFavorite(
        authProvider.user!.token!,
        audio.id,
        title: audio.title,
        artist: audio.artist,
        duration: audio.duration,
        coverUrl: audio.coverUrl,
      );

      if (context.mounted) {
        DialogHelper.showSnackBar(
          context,
          wasFavorited ? '已取消收藏' : '已添加到我喜欢',
          backgroundColor: wasFavorited ? Colors.grey : Colors.green,
        );
      }
    } catch (e) {
      AppLogger.error('PlayHistoryPage', '收藏操作失败: $e');
      if (context.mounted) {
        DialogHelper.showSnackBar(
          context,
          '操作失败: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// 判断路径是否为本地文件路径
  bool _isLocalPath(String path) {
    // Windows 路径: C:\... 或 \\server\...
    // Unix/Linux 路径: /home/...
    // 相对路径: ./... 或 ../...

    // 检查是否以驱动器字母开头（Windows）
    if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return true;

    // 检查是否以 / 开头（Unix/Linux 绝对路径）
    if (path.startsWith('/') || path.startsWith('\\')) return true;

    // 检查是否包含文件扩展名（常见音频格式）
    final audioExtensions = ['.mp3', '.flac', '.m4a', '.wav', '.ogg', '.wma', '.aac', '.opus'];
    for (final ext in audioExtensions) {
      if (path.toLowerCase().endsWith(ext)) return true;
    }

    // 检查是否以相对路径标记开头
    if (path.startsWith('./') || path.startsWith('../') || path.startsWith('.\\')) return true;

    // 默认为在线音频（BVID 格式）
    return false;
  }

  /// 根据筛选条件和搜索关键词过滤历史记录
  List<PlayHistoryItem> _filterHistory(List<PlayHistoryItem> history) {
    var filtered = history;

    // 应用时间筛选
    if (_filterType != HistoryFilterType.all) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      filtered = filtered.where((item) {
        final playedAt = item.playedAt;

        switch (_filterType) {
          case HistoryFilterType.today:
            return playedAt.isAfter(todayStart) || playedAt.isAtSameMomentAs(todayStart);
          case HistoryFilterType.week:
            final weekAgo = todayStart.subtract(const Duration(days: 7));
            return playedAt.isAfter(weekAgo) || playedAt.isAtSameMomentAs(weekAgo);
          case HistoryFilterType.month:
            final monthAgo = todayStart.subtract(const Duration(days: 30));
            return playedAt.isAfter(monthAgo) || playedAt.isAtSameMomentAs(monthAgo);
          case HistoryFilterType.all:
            return true;
        }
      }).toList();
    }

    // 应用搜索筛选
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        final title = item.audio.title.toLowerCase();
        final artist = (item.audio.artist ?? '').toLowerCase();
        return title.contains(query) || artist.contains(query);
      }).toList();
    }

    return filtered;
  }

  /// 获取筛选类型显示名称
  String _getFilterLabel(HistoryFilterType type) {
    switch (type) {
      case HistoryFilterType.all:
        return '全部';
      case HistoryFilterType.today:
        return '今天';
      case HistoryFilterType.week:
        return '本周';
      case HistoryFilterType.month:
        return '本月';
    }
  }

  Future<void> _removeItem(PlayHistoryItem item) async {
    final authProvider = context.read<AuthProvider>();
    final historyProvider = context.read<PlayHistoryProvider>();
    await historyProvider.removeHistoryItem(
      authProvider.user?.token,
      item.audio.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<PlayHistoryProvider>();
    final history = historyProvider.history;
    final filteredHistory = _filterHistory(history);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放历史',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: '清空历史',
            ),
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
          // 搜索和筛选栏
          _buildFilterBar(history.isNotEmpty),
          // 历史列表
          Expanded(child: _buildBody(filteredHistory, history.isNotEmpty)),
        ],
      ),
    );
  }

  /// 构建搜索和筛选栏
  Widget _buildFilterBar(bool hasHistory) {
    if (!hasHistory) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 筛选按钮
          FilterChip(
            label: Text(_getFilterLabel(_filterType)),
            avatar: const Icon(Icons.filter_list, size: 18),
            selected: _filterType != HistoryFilterType.all,
            onSelected: (_) => _showFilterDialog(),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          const SizedBox(width: 12),
          // 搜索框
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索歌曲或歌手',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选播放历史'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HistoryFilterType.values.map((type) {
            return RadioListTile<HistoryFilterType>(
              title: Text(_getFilterLabel(type)),
              value: type,
              groupValue: _filterType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filterType = value;
                  });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(List<PlayHistoryItem> filteredHistory, bool hasOriginalHistory) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 没有历史记录
    if (!hasOriginalHistory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '还没有播放记录',
              style: TextStyle(
                fontSize: UIConstants.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '去搜索或发现页面找些音乐听听吧',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 筛选后为空
    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              '没有找到相关记录',
              style: TextStyle(
                fontSize: UIConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '试试调整筛选条件或搜索关键词',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredHistory.length,
        itemBuilder: (context, index) {
          final item = filteredHistory[index];
          return _buildHistoryCard(item, index);
        },
      ),
    );
  }

  Widget _buildHistoryCard(PlayHistoryItem item, int index) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _removeItem(item);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildItemCover(item),
          title: Text(
            item.audio.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (item.audio.artist != null) item.audio.artist,
                  _formatDuration(item.audio.duration ?? 0),
                ].join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              // 播放进度条
              if (item.audio.duration != null && item.audio.duration! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: item.progressPercent,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '播放至 ${_formatProgress(item.progress, item.audio.duration!)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              // 播放时间
              Text(
                item.playedAtFormatted,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 收藏按钮
              Consumer<PlaylistProvider>(
                builder: (context, playlistProvider, _) {
                  return FavoriteButton(
                    isFavorited: playlistProvider.isFavorited(item.audio.id),
                    size: 24,
                    onPressed: () => _handleFavoriteToggle(
                      context,
                      playlistProvider,
                      item,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              // 播放按钮
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () => _playHistoryItem(item),
              ),
            ],
          ),
          onTap: () => _playHistoryItem(item),
        ),
      ),
    );
  }

  Widget _buildItemCover(PlayHistoryItem item) {
    final coverUrl = item.audio.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          coverUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover();
          },
        ),
      );
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey),
    );
  }

  String _formatProgress(int progress, int duration) {
    final progressMin = progress ~/ 60;
    final progressSec = progress % 60;
    final durationMin = duration ~/ 60;
    final durationSec = duration % 60;
    return '${progressMin.toString().padLeft(2, '0')}:${progressSec.toString().padLeft(2, '0')} / ${durationMin.toString().padLeft(2, '0')}:${durationSec.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
