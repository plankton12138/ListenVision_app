import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/player/queue_viewmodel.dart';
import 'queue_tab_view.dart';
import 'history_tab_view.dart';

/// 播放列表底部弹窗
///
/// 包含两个 Tab：正在播放和播放历史
class QueueBottomSheet extends ConsumerStatefulWidget {
  const QueueBottomSheet({super.key});

  /// 显示弹窗
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      // 点击背景区域关闭
      isDismissible: true,
      builder: (context) => const QueueBottomSheet(),
    );
  }

  @override
  ConsumerState<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends ConsumerState<QueueBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      // 点击内容区域之外不关闭（由子组件处理）
      onTap: () {},  // 空回调，防止事件冒泡
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.5, 0.7, 0.95],
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 顶部拖拽指示器区域（可点击关闭）
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildDragIndicator(theme),
                ),
              ),

              // TabBar
              _buildTabBar(context, ref),

              // TabView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    QueueTabView(scrollController: scrollController),
                    HistoryTabView(scrollController: scrollController),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建拖拽指示器
  Widget _buildDragIndicator(ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// 构建 TabBar
  Widget _buildTabBar(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueViewModelProvider);

    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: '正在播放(${queueState.queue?.tracks.length ?? 0})'),
        const Tab(text: '播放历史'),
      ],
      indicatorSize: TabBarIndicatorSize.label,
    );
  }
}
