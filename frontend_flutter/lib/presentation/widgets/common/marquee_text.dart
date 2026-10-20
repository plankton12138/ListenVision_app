import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// 宽度不足时自动跑马灯滚动的文本组件
///
/// 文本在可用宽度内放得下时保持普通 [Text]（超过 [maxLines] 行则省略），
/// 放不下时改为横向滚动，保证长标题也能完整看到。
class MarqueeText extends StatelessWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.velocity = 30.0,
    this.blankSpace = 48.0,
    this.pauseAfterRound = const Duration(seconds: 1),
    this.textDirection,
  });

  /// 要显示的文本
  final String text;

  /// 文本样式
  final TextStyle? style;

  /// 放得下时最多显示的行数
  final int maxLines;

  /// 文本对齐方式
  final TextAlign textAlign;

  /// 滚动速度（像素/秒）
  final double velocity;

  /// 相邻两遍文本之间的空白宽度
  final double blankSpace;

  /// 每轮滚动结束后的停顿时间
  final Duration pauseAfterRound;

  /// 文本方向
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = textDirection ?? Directionality.of(context);
    // 按 Text 的样式合并规则合并默认样式，保证测量宽度与实际渲染宽度一致
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle =
        style == null ? defaultStyle : defaultStyle.merge(style);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final overflow = _overflow(maxWidth, effectiveStyle, textScaler,
            direction);

        if (!overflow) {
          return Text(
            text,
            style: effectiveStyle,
            maxLines: maxLines,
            textAlign: textAlign,
            overflow: TextOverflow.ellipsis,
            textDirection: direction,
          );
        }

        return SizedBox(
          height: _lineHeight(effectiveStyle, textScaler, direction),
          child: Marquee(
            text: text,
            style: effectiveStyle,
            textDirection: direction,
            velocity: velocity,
            blankSpace: blankSpace,
            pauseAfterRound: pauseAfterRound,
          ),
        );
      },
    );
  }

  /// 判断文本是否超出可用宽度（即需要滚动）
  bool _overflow(
    double maxWidth,
    TextStyle style,
    TextScaler textScaler,
    TextDirection direction,
  ) {
    if (!maxWidth.isFinite) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: direction,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    final overflow = painter.didExceedMaxLines;
    painter.dispose();
    return overflow;
  }

  /// 计算单行文本高度，用于给跑马灯一个确定的高度
  double _lineHeight(
    TextStyle style,
    TextScaler textScaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: '音', style: style),
      maxLines: 1,
      textDirection: direction,
      textScaler: textScaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
