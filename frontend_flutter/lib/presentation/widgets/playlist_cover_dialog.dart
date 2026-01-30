import 'package:flutter/material.dart';
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 歌单封面选择对话框
///
/// Phase 5: 歌单封面管理功能
/// 提供多种封面选择方式：
/// 1. 推荐封面（预设渐变色和图案）
/// 2. 本地图片选择（预留，待实现）
/// 3. 自定义 URL 输入（预留，待实现）
class PlaylistCoverDialog extends StatefulWidget {
  final String? currentCoverUrl;
  final Function(String coverUrl)? onCoverSelected;

  const PlaylistCoverDialog({
    super.key,
    this.currentCoverUrl,
    this.onCoverSelected,
  });

  @override
  _PlaylistCoverDialogState createState() => _PlaylistCoverDialogState();
}

class _PlaylistCoverDialogState extends State<PlaylistCoverDialog> {
  String? _selectedCoverUrl;

  @override
  void initState() {
    super.initState();
    _selectedCoverUrl = widget.currentCoverUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            _buildHeader(context),
            // 封面选项
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('推荐封面'),
                    _buildRecommendedCovers(context),
                    const SizedBox(height: 24),
                    _buildSectionHeader('自定义'),
                    _buildCustomOptions(context),
                  ],
                ),
              ),
            ),
            // 底部按钮
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// 构建对话框头部
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '选择封面',
            style: TextStyle(
              fontSize: UIConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              AppLogger.logButtonClick('关闭-封面选择', 'PlaylistCoverDialog');
              Navigator.pop(context);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// 构建推荐封面网格
  Widget _buildRecommendedCovers(BuildContext context) {
    final covers = _getRecommendedCovers();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: covers.length,
      itemBuilder: (context, index) {
        final cover = covers[index];
        final isSelected = _selectedCoverUrl == cover['url'];

        return GestureDetector(
          onTap: () {
            AppLogger.logButtonClick('选择封面-${cover['url']}', 'PlaylistCoverDialog');
            setState(() {
              _selectedCoverUrl = cover['url'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 2,
              ),
              gradient: cover['gradient'] as LinearGradient?,
              color: cover['color'],
            ),
            child: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  )
                : cover['icon'] != null
                    ? Icon(cover['icon'], color: Colors.white54, size: 32)
                    : null,
          ),
        );
      },
    );
  }

  /// 获取推荐封面列表
  List<Map<String, dynamic>> _getRecommendedCovers() {
    return [
      {
        'url': 'gradient_sunset',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFFEC89A)],
        ),
      },
      {
        'url': 'gradient_ocean',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        ),
      },
      {
        'url': 'gradient_forest',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38F9D7), Color(0xFF43E97B)],
        ),
      },
      {
        'url': 'gradient_night',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      },
      {
        'url': 'gradient_cherry',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEB3349), Color(0xFFF45C43)],
        ),
      },
      {
        'url': 'gradient_sky',
        'gradient': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
        ),
      },
      {
        'url': 'solid_red',
        'color': Colors.red.shade400,
      },
      {
        'url': 'solid_blue',
        'color': Colors.blue.shade400,
      },
      {
        'url': 'solid_green',
        'color': Colors.green.shade400,
      },
      {
        'url': 'solid_orange',
        'color': Colors.orange.shade400,
      },
      {
        'url': 'solid_purple',
        'color': Colors.purple.shade400,
      },
      {
        'url': 'solid_teal',
        'color': Colors.teal.shade400,
      },
      {
        'url': 'music_note',
        'color': Colors.grey.shade800,
        'icon': Icons.music_note,
      },
    ];
  }

  /// 构建自定义选项
  Widget _buildCustomOptions(BuildContext context) {
    return Column(
      children: [
        _buildCustomOption(
          context,
          icon: Icons.photo_library,
          title: '从相册选择',
          subtitle: '从手机相册选择图片',
          onTap: () {
            AppLogger.logButtonClick('从相册选择', 'PlaylistCoverDialog');
            // 图片选择功能需要 image_picker 包，当前暂未实现
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('图片选择功能开发中'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildCustomOption(
          context,
          icon: Icons.link,
          title: '输入图片链接',
          subtitle: '使用网络图片URL',
          onTap: () {
            AppLogger.logButtonClick('输入图片链接', 'PlaylistCoverDialog');
            _showUrlInputDialog(context);
          },
        ),
      ],
    );
  }

  /// 构建自定义选项卡片
  Widget _buildCustomOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// 显示URL输入对话框
  void _showUrlInputDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入图片链接'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.logButtonClick('取消-图片链接', 'PlaylistCoverDialog');
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                AppLogger.logButtonClick('确定-图片链接', 'PlaylistCoverDialog',
                  parameters: {'url': url});
                setState(() {
                  _selectedCoverUrl = url;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                AppLogger.logButtonClick('取消-封面选择', 'PlaylistCoverDialog');
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _selectedCoverUrl != null
                  ? () {
                      AppLogger.logButtonClick('确定-封面选择', 'PlaylistCoverDialog',
                        parameters: {'coverUrl': _selectedCoverUrl});
                      widget.onCoverSelected?.call(_selectedCoverUrl!);
                      Navigator.pop(context, _selectedCoverUrl);
                    }
                  : null,
              child: const Text('确定'),
            ),
          ),
        ],
      ),
    );
  }
}
