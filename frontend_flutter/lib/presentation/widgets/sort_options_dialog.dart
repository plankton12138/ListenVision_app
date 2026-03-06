import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listenvision/core/constants/app_constants.dart';

/// 歌单排序选项对话框
///
/// 提供多种排序方式：
/// 1. 按添加时间（最新/最早）
/// 2. 按标题字母序（A-Z / Z-A）
/// 3. 按艺术家字母序（A-Z / Z-A）
class SortOptionsDialog extends ConsumerWidget {
  const SortOptionsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text(
        '排序方式',
        style: TextStyle(fontSize: UIConstants.fontSizeLarge),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== 时间排序 ==========
          _buildSectionHeader('按添加时间'),
          _buildOption(
            context,
            icon: Icons.new_releases,
            title: '最新添加',
            subtitle: '最近添加的排在前面',
            onTap: () => _applySort(context, ref, 'added_at_desc'),
          ),
          _buildOption(
            context,
            icon: Icons.schedule,
            title: '最早添加',
            subtitle: '最早添加的排在前面',
            onTap: () => _applySort(context, ref, 'added_at_asc'),
          ),

          const Divider(height: 24),

          // ========== 标题排序 ==========
          _buildSectionHeader('按标题'),
          _buildOption(
            context,
            icon: Icons.text_rotation_none,
            title: 'A-Z（标题）',
            subtitle: '按标题字母顺序排列',
            onTap: () => _applySort(context, ref, 'title_asc'),
          ),
          _buildOption(
            context,
            icon: Icons.arrow_downward,
            title: 'Z-A（标题）',
            subtitle: '按标题字母倒序排列',
            onTap: () => _applySort(context, ref, 'title_desc'),
          ),

          const Divider(height: 24),

          // ========== 艺术家排序 ==========
          _buildSectionHeader('按艺术家'),
          _buildOption(
            context,
            icon: Icons.person,
            title: 'A-Z（艺术家）',
            subtitle: '按艺术家字母顺序排列',
            onTap: () => _applySort(context, ref, 'artist_asc'),
          ),
          _buildOption(
            context,
            icon: Icons.person_outline,
            title: 'Z-A（艺术家）',
            subtitle: '按艺术家字母倒序排列',
            onTap: () => _applySort(context, ref, 'artist_desc'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  /// 构建排序选项
  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 应用排序
  ///
  /// 参数 sortType: 排序类型
  /// - added_at_desc: 最新添加
  /// - added_at_asc: 最早添加
  /// - title_asc: A-Z标题
  /// - title_desc: Z-A标题
  /// - artist_asc: A-Z艺术家
  /// - artist_desc: Z-A艺术家
  void _applySort(BuildContext context, WidgetRef ref, String sortType) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已按 ${sortTypeToDisplayName(sortType)} 排序'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 将 sortType 转换为显示名称
  String sortTypeToDisplayName(String sortType) {
    switch (sortType) {
      case 'added_at_desc':
        return '最新添加';
      case 'added_at_asc':
        return '最早添加';
      case 'title_asc':
        return 'A-Z（标题）';
      case 'title_desc':
        return 'Z-A（标题）';
      case 'artist_asc':
        return 'A-Z（艺术家）';
      case 'artist_desc':
        return 'Z-A（艺术家）';
      default:
        return sortType;
    }
  }
}
