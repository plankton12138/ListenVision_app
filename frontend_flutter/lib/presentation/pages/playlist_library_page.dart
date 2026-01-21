// P2: 页面已迁移到 presentation/pages/
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/presentation/pages/playlist_detail_page.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 歌单库页面
///
/// 展示用户的所有歌单（系统歌单 + 用户歌单）
/// Phase 2: 完整的歌单管理功能
class PlaylistLibraryPage extends StatefulWidget {
  const PlaylistLibraryPage({super.key});

  @override
  _PlaylistLibraryPageState createState() => _PlaylistLibraryPageState();
}

class _PlaylistLibraryPageState extends State<PlaylistLibraryPage> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 延迟到 build 完成后检查登录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  /// 检查登录状态，未登录则跳转到登录页
  void _checkLoginAndLoad() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      showMySnackBar(context, '请先登录', Colors.orange, 1500);
      context.go('/login');
      return;
    }
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await playlistProvider.initialize(authProvider.user!.token);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 创建新歌单
  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '歌单名称',
                hintText: '请输入歌单名称',
              ),
              autofocus: true,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '请输入歌单描述',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await _createPlaylist(controller.text.trim(), descController.text.trim());
    }

    controller.dispose();
    descController.dispose();
  }

  Future<void> _createPlaylist(String name, String description) async {
    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      final newPlaylist = await playlistProvider.createPlaylist(
        authProvider.user!.token,
        name,
        description: description.isEmpty ? null : description,
      );

      if (newPlaylist != null && mounted) {
        showMySnackBar(context, '歌单创建成功', Colors.green, 1500);
      } else {
        showMySnackBar(context, '歌单创建失败', Colors.red, 2000);
      }
    } catch (e) {
      showMySnackBar(context, '创建失败: $e', Colors.red, 2000);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示歌单选项菜单
  void _showPlaylistOptions(Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑歌单'),
              onTap: () {
                Navigator.pop(context);
                _editPlaylist(playlist);
              },
            ),
            if (!playlist.isSystem)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除歌单', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePlaylist(playlist);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPlaylist(Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final descController = TextEditingController(text: playlist.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '歌单名称',
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updatePlaylist(playlist, controller.text.trim(), descController.text.trim());
    }

    controller.dispose();
    descController.dispose();
  }

  Future<void> _updatePlaylist(Playlist playlist, String name, String description) async {
    if (playlist.id == null) return;

    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await playlistProvider.updatePlaylist(
        authProvider.user!.token,
        playlist.id!,
        name: name,
        description: description.isEmpty ? null : description,
      );

      if (success && mounted) {
        showMySnackBar(context, '歌单已更新', Colors.green, 1500);
      } else {
        showMySnackBar(context, '更新失败', Colors.red, 2000);
      }
    } catch (e) {
      showMySnackBar(context, '更新失败: $e', Colors.red, 2000);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    if (playlist.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除歌单"${playlist.name}"吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await playlistProvider.deletePlaylist(
        authProvider.user!.token,
        playlist.id!,
      );

      if (success && mounted) {
        showMySnackBar(context, '歌单已删除', Colors.green, 1500);
      } else {
        showMySnackBar(context, '删除失败', Colors.red, 2000);
      }
    } catch (e) {
      showMySnackBar(context, '删除失败: $e', Colors.red, 2000);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '我的歌单',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(playlistProvider),
    );
  }

  Widget _buildBody(PlaylistProvider playlistProvider) {
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
              onPressed: _loadPlaylists,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (!playlistProvider.hasPlaylists) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.playlist_play,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '还没有歌单',
              style: TextStyle(
                fontSize: UIConstants.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '点击右下角按钮创建你的第一个歌单',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 使用 CustomScrollView 优化性能，按需构建子widget
    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      child: CustomScrollView(
        slivers: [
          // 系统歌单区
          if (playlistProvider.systemPlaylists.isNotEmpty)
            SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '系统歌单',
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildPlaylistCard(playlistProvider.systemPlaylists[index]),
                    ),
                    childCount: playlistProvider.systemPlaylists.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          // 用户歌单区
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, playlistProvider.systemPlaylists.isEmpty ? 16 : 0, 16, 8),
              child: Text(
                '我的歌单',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (playlistProvider.userPlaylists.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '还没有创建歌单，点击右下角按钮创建',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPlaylistCard(playlistProvider.userPlaylists[index]),
                ),
                childCount: playlistProvider.userPlaylists.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    IconData icon;
    Color iconColor;

    if (playlist.isFavorites) {
      icon = Icons.favorite;
      iconColor = Colors.red;
    } else if (playlist.isNowPlaying) {
      icon = Icons.play_circle;
      iconColor = Colors.blue;
    } else {
      icon = Icons.playlist_play;
      iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(playlist.name),
        subtitle: Text(
          [
            if (playlist.description != null) playlist.description,
            '${playlist.itemCount}首',
            if (playlist.playCount > 0) '播放${playlist.playCount}次',
          ].where((s) => s != null).join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playlist.itemCount > 0)
              Text(
                '${playlist.itemCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // 跳转到歌单详情页
          if (playlist.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailPage(playlistId: playlist.id!),
              ),
            );
          }
        },
        onLongPress: () {
          _showPlaylistOptions(playlist);
        },
      ),
    );
  }
}
