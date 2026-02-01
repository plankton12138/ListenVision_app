import 'package:flutter/material.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 收藏按钮组件
///
/// 用于在列表和播放器中显示收藏状态，支持点击切换
class FavoriteButton extends StatefulWidget {
  /// 当前收藏状态
  final bool isFavorited;

  /// 点击回调
  final VoidCallback onPressed;

  /// 按钮尺寸
  final double size;

  const FavoriteButton({
    super.key,
    required this.isFavorited,
    required this.onPressed,
    this.size = 24,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorited != oldWidget.isFavorited) {
      if (widget.isFavorited) {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IconButton(
          icon: Icon(
            widget.isFavorited ? Icons.favorite : Icons.favorite_border,
            color: widget.isFavorited
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
          iconSize: widget.size,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: widget.size,
            minHeight: widget.size,
          ),
          onPressed: () {
            AppLogger.logButtonClick(
              widget.isFavorited ? '取消收藏' : '收藏',
              'FavoriteButton',
            );
            widget.onPressed();
          },
        ),
      ),
    );
  }
}
