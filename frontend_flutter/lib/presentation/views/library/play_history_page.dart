import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 播放历史页面
///
/// 显示用户的播放历史记录
/// 使用 Riverpod 的 HistoryViewModel
class PlayHistoryPage extends ConsumerWidget {
  const PlayHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '播放历史',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: <Widget>[
          // 清空历史按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            iconSize: UIConstants.iconMedium,
            onPressed: () {
              // TODO: 清空播放历史
            },
          ),
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: !isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('请先登录'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('去登录'),
                  ),
                ],
              ),
            )
          : const Center(
              child: Text('播放历史待实现'),
            ),
    );
  }
}
