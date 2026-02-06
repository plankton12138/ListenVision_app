import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 倍速按钮组件
///
/// 允许用户选择播放倍速（0.5x - 2.0x）
class SpeedButton extends ConsumerWidget {
  const SpeedButton({super.key});

  /// 倍速档位选项
  static const List<double> kSpeedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  /// 倍速显示文本
  static final Map<double, String> kSpeedLabels = {
    0.5: '0.5x',
    0.75: '0.75x',
    1.0: '1.0x',
    1.25: '1.25x',
    1.5: '1.5x',
    2.0: '2.0x',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerViewModelProvider);

    final currentSpeed = playerState.speed;
    final isDefaultSpeed = currentSpeed == 1.0;

    return IconButton(
      icon: Text(
        kSpeedLabels[currentSpeed] ?? '1.0x',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDefaultSpeed
              ? null
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      onPressed: () {
        AppLogger.logButtonClick('倍速按钮', 'SpeedButton',
          parameters: {'currentSpeed': currentSpeed});
        _showSpeedMenu(context, ref, currentSpeed);
      },
      tooltip: '播放倍速',
    );
  }

  /// 显示倍速选择菜单
  void _showSpeedMenu(BuildContext context, WidgetRef ref, double currentSpeed) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;

    showMenu<double>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + buttonSize.height + 8,
        offset.dx + buttonSize.width,
        offset.dy + buttonSize.height + 8,
      ),
      items: kSpeedOptions.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            children: [
              Text(kSpeedLabels[speed] ?? '$speed'),
              const Spacer(),
              // 当前选中的倍速显示勾选图标
              if (currentSpeed == speed)
                Icon(
                  Icons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedSpeed) {
      if (selectedSpeed != null) {
        AppLogger.logButtonClick('倍速选择-${kSpeedLabels[selectedSpeed]}', 'SpeedButton',
          parameters: {'speed': selectedSpeed});
        ref.read(playerViewModelProvider.notifier).setSpeed(selectedSpeed);
      }
    });
  }
}
