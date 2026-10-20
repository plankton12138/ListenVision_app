import 'package:listenvision/services/ffmpeg_service.dart';
import 'package:listenvision/core/constants/app_constants.dart';
import 'package:listenvision/presentation/viewmodels/settings/scan_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/library/local_music_viewmodel.dart';
import 'package:listenvision/presentation/widgets/my_drawer.dart';
import 'package:listenvision/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/system/theme_viewmodel.dart';
import '../../../core/storage/shared_storage_service.dart';

/// 设置页面
///
/// 提供主题切换、下载设置等应用设置选项
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeViewModelProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLocalMusicScanCard(context),
          const SizedBox(height: 16),
          _buildDarkModeCard(context, themeMode: themeMode),
          const SizedBox(height: 16),
          _buildDownloadFormatCard(context),
          const SizedBox(height: 16),
          _buildDownloadCoverCard(context),
        ],
      ),
    );
  }

  Widget _buildLocalMusicScanCard(BuildContext context) {
    final scanState = ref.watch(scanViewModelProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.library_music, size: 20),
              const SizedBox(width: 8),
              const Text(
                '本地音乐',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '扫描设备中的音频文件',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: scanState.maybeWhen(
              scanning: (current, total, fileName) {
                final progress = total > 0 ? current / total : 0.0;
                return Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      '正在扫描 ($current/$total): $fileName',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
              requestingPermission: () => const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('请求权限中...'),
                ],
              ),
              orElse: () => ElevatedButton.icon(
                onPressed: () => _startScan(context),
                icon: const Icon(Icons.search),
                label: const Text('扫描本地音乐'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          scanState.maybeWhen(
            completed: (result) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    result.summary,
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
            error: (message) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    await ref
        .read(scanViewModelProvider.notifier)
        .startScan(minDurationSeconds: 10);

    if (mounted) {
      final result = ref.read(scanViewModelProvider);
      result.maybeWhen(
        completed: (scanResult) {
          if (scanResult.addedCount > 0) {
            ref.read(localMusicViewModelProvider.notifier).refresh();
          }
          DialogHelper.showSnackBar(
            context,
            '扫描完成: ${scanResult.summary}',
            backgroundColor: scanResult.addedCount > 0
                ? Colors.green
                : Colors.grey[700]!,
          );
        },
        error: (message) {
          DialogHelper.showSnackBar(
            context,
            message,
            backgroundColor: Colors.red,
          );
        },
        orElse: () {},
      );
    }
  }

  /// 深色模式开关卡片
  Widget _buildDarkModeCard(
    BuildContext context, {
    required AppThemeMode themeMode,
  }) {
    final isDarkMode = themeMode == AppThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('深色模式', style: TextStyle(fontWeight: FontWeight.bold)),
          Switch(
            value: isDarkMode,
            onChanged: (_) =>
                ref.read(themeViewModelProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }

  /// 下载音频格式选择卡片
  Widget _buildDownloadFormatCard(BuildContext context) {
    final storage = SharedStorageService.instance;
    final canConvert = FfmpegService().supportsConversion;
    final currentFormat = canConvert ? storage.getDownloadFormat() : 'm4a';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('下载格式', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                !canConvert
                    ? '此平台支持 M4A 下载'
                    : currentFormat == 'mp3'
                    ? 'MP3 格式（需要安装 FFmpeg）'
                    : 'M4A 原始音频',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Switch(
            value: currentFormat == 'mp3',
            onChanged: !canConvert
                ? null
                : (isMp3) async {
                    final success = await storage.setDownloadFormat(
                      isMp3 ? 'mp3' : 'm4a',
                    );
                    if (success) {
                      setState(() {});
                    }
                  },
          ),
        ],
      ),
    );
  }

  /// 下载封面开关卡片
  Widget _buildDownloadCoverCard(BuildContext context) {
    final storage = SharedStorageService.instance;
    final downloadCover = storage.getDownloadCover();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.image, size: 20),
                  SizedBox(width: 8),
                  Text('下载封面', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                downloadCover ? '下载时同时保存封面图片' : '跳过封面下载以节省流量和存储',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Switch(
            value: downloadCover,
            onChanged: (value) async {
              await storage.setDownloadCover(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
