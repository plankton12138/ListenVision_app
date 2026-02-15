import '../../core/utils/app_logger.dart';

/// 下载槽位状态
enum DownloadSlotStatus {
  /// 空闲
  idle,
  /// 占用中
  occupied,
  /// 预留（暂停后保留槽位）
  reserved,
}

/// 下载槽位管理器
///
/// 解决问题：暂停后重新开始时，实际并发数可能超过限制。
///
/// 原理：
/// - 普通下载时，槽位状态为 occupied
/// - 暂停时，槽位状态变为 reserved（保留槽位）
/// - 恢复时，reserved 槽位直接变为 occupied
/// - 删除任务时，才真正释放槽位
///
/// 这样可以确保：
/// 1. 暂停的任务保留其槽位优先级
/// 2. 恢复时可以立即开始下载（无需等待槽位）
/// 3. 并发数不会因为暂停/恢复而超过限制
class DownloadSlotManager {
  final int maxSlots;
  final Map<int, DownloadSlotStatus> _slots = {};

  DownloadSlotManager({this.maxSlots = 3});

  /// 获取当前占用数（仅 occupied）
  int get occupiedCount => _slots.values
      .where((s) => s == DownloadSlotStatus.occupied)
      .length;

  /// 获取总预留数（包括 reserved）
  int get totalReservedCount => _slots.length;

  /// 是否有空闲槽位
  bool get hasAvailableSlot => occupiedCount < maxSlots;

  /// 获取槽位使用情况（用于调试）
  Map<String, int> get slotStats => {
    'occupied': occupiedCount,
    'reserved': _slots.values.where((s) => s == DownloadSlotStatus.reserved).length,
    'total': _slots.length,
    'maxSlots': maxSlots,
  };

  /// 占用槽位
  ///
  /// 返回 true 表示成功占用，false 表示无可用槽位
  bool occupySlot(int taskId) {
    if (!hasAvailableSlot) {
      AppLogger.warn('DownloadSlotManager', '无可用槽位: $slotStats');
      return false;
    }

    _slots[taskId] = DownloadSlotStatus.occupied;
    AppLogger.info('DownloadSlotManager', '占用槽位: taskId=$taskId, $slotStats');
    return true;
  }

  /// 释放槽位
  void releaseSlot(int taskId) {
    final removed = _slots.remove(taskId);
    if (removed != null) {
      AppLogger.info('DownloadSlotManager', '释放槽位: taskId=$taskId, $slotStats');
    }
  }

  /// 预留槽位（暂停时调用，保留槽位不释放）
  void reserveSlot(int taskId) {
    _slots[taskId] = DownloadSlotStatus.reserved;
    AppLogger.info('DownloadSlotManager', '预留槽位: taskId=$taskId, $slotStats');
  }

  /// 恢复槽位（从 reserved 变为 occupied）
  ///
  /// 如果任务已有 reserved 槽位，直接升级为 occupied
  /// 否则尝试获取新槽位
  ///
  /// 返回 true 表示成功恢复，false 表示槽位不足
  bool restoreSlot(int taskId) {
    if (_slots[taskId] == DownloadSlotStatus.reserved) {
      _slots[taskId] = DownloadSlotStatus.occupied;
      AppLogger.info('DownloadSlotManager', '恢复槽位: taskId=$taskId, $slotStats');
      return true;
    }
    return occupySlot(taskId);
  }

  /// 检查任务是否有槽位（无论是 occupied 还是 reserved）
  bool hasSlot(int taskId) => _slots.containsKey(taskId);

  /// 检查任务是否正在占用槽位（occupied 状态）
  bool isOccupied(int taskId) => _slots[taskId] == DownloadSlotStatus.occupied;

  /// 检查任务是否预留槽位（reserved 状态）
  bool isReserved(int taskId) => _slots[taskId] == DownloadSlotStatus.reserved;

  /// 清理所有槽位
  void clear() {
    final count = _slots.length;
    _slots.clear();
    if (count > 0) {
      AppLogger.info('DownloadSlotManager', '清理所有槽位: $count 个');
    }
  }

  /// 获取所有槽位中的任务 ID
  List<int> get allTaskIds => _slots.keys.toList();

  /// 获取占用中的任务 ID
  List<int> get occupiedTaskIds => _slots.entries
      .where((e) => e.value == DownloadSlotStatus.occupied)
      .map((e) => e.key)
      .toList();

  /// 获取预留的任务 ID
  List<int> get reservedTaskIds => _slots.entries
      .where((e) => e.value == DownloadSlotStatus.reserved)
      .map((e) => e.key)
      .toList();
}
