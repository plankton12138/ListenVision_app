import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../../models/subtitle.dart';

/// 字幕滚动展示组件
///
/// 功能：
/// 1. 自动跟随播放进度滚动
/// 2. 当前行高亮显示
/// 3. 点击字幕行可跳转播放位置
/// 4. 语言切换（多语言时显示切换按钮）
/// 5. 上下文显示（当前行上下各保留若干行）
class SubtitleView extends ConsumerStatefulWidget {
  final Function(Duration)? onSeek;

  const SubtitleView({super.key, this.onSeek});

  @override
  ConsumerState<SubtitleView> createState() => _SubtitleViewState();
}

class _SubtitleViewState extends ConsumerState<SubtitleView> {
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    // 监听手动滚动，暂时禁用自动滚动
    _scrollController.addListener(_onUserScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onUserScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserScroll() {
    if (_scrollController.position.activity!.isScrolling) {
      // 用户正在滚动
      if (_isAutoScrolling) {
        setState(() => _isAutoScrolling = false);
        // 3秒后恢复自动滚动
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isAutoScrolling = true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleState = ref.watch(subtitleViewModelProvider);
    final track = subtitleState.activeTrack;
    final isLoading = subtitleState.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (track == null || track.lines.isEmpty) {
      return _buildEmptyState(subtitleState);
    }

    // 自动滚动到当前行
    _scrollToCurrentLine(subtitleState.currentLineIndex);

    return Column(
      children: [
        // 语言切换栏（多语言时显示）
        if ((subtitleState.data?.subtitles.length ?? 0) > 1)
          _buildLanguageSwitcher(subtitleState),
        // 字幕列表
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: track.lines.length,
            // 增加 padding 使此时可以滚到底部
            padding: const EdgeInsets.symmetric(vertical: 100),
            itemBuilder: (context, index) {
              final line = track.lines[index];
              final isCurrent = index == subtitleState.currentLineIndex;
              return _buildSubtitleLine(line, isCurrent, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(SubtitleState state) {
    return Center(
      child: Text(
        state.error != null
            ? '获取字幕失败: ${state.error}'
            : '暂无字幕',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher(SubtitleState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 16),
            const SizedBox(width: 4),
            Text(
              state.activeTrack?.lanDoc ?? '未知语言',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onSelected: (lan) {
          ref.read(subtitleViewModelProvider.notifier).switchLanguage(lan);
        },
        itemBuilder: (context) {
          return state.data!.subtitles.map((t) {
            return PopupMenuItem(
              value: t.lan,
              child: Text(t.lanDoc),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildSubtitleLine(SubtitleLine line, bool isCurrent, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () {
        if (widget.onSeek != null) {
          widget.onSeek!(Duration(milliseconds: (line.from * 1000).toInt()));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: isCurrent ? 20 : 16,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
          child: Text(
            line.content,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _scrollToCurrentLine(int index) {
    if (!_isAutoScrolling || index < 0) return;
    
    // 确保列表已构建
    if (!_scrollController.hasClients) return;

    // 粗略估算：每行高度约为 50
    double offset = index * 50.0;
    
    // 尝试让当前行居中：减去一半容器高度 (假设容器高 400 左右)
    // 实际上我们在 Expanded 中，可以用 context.size 但不一定准。
    // 使用 ScrollPosition.viewportDimension
    final viewportHeight = _scrollController.position.viewportDimension;
    
    double centeredOffset = offset - (viewportHeight / 2) + 25; // +25 是半行高
    
    if (centeredOffset < 0) centeredOffset = 0;
    if (centeredOffset > _scrollController.position.maxScrollExtent) {
      centeredOffset = _scrollController.position.maxScrollExtent;
    }

    _scrollController.animateTo(
      centeredOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
