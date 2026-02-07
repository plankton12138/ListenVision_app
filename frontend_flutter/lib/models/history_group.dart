import 'play_history.dart';

/// 播放历史分组
///
/// 用于将播放历史按时间分组显示
class HistoryGroup {
  /// 分组标签（如"刚刚"、"今天"、"昨天"等）
  final String label;

  /// 该分组的播放历史列表
  final List<PlayHistory> items;

  const HistoryGroup({
    required this.label,
    required this.items,
  });

  /// 按时间分组
  ///
  /// 将播放历史按时间分为：
  /// - 刚刚（1小时内）
  /// - 今天
  /// - 昨天
  /// - 更早（按日期显示）
  static List<HistoryGroup> groupByTime(List<PlayHistory> history) {
    final now = DateTime.now();
    final groups = <String, List<PlayHistory>>{};

    for (final item in history) {
      final diff = now.difference(item.playedAt);
      String key;

      if (diff.inMinutes < 60) {
        key = '刚刚';
      } else if (item.playedAt.day == now.day &&
          item.playedAt.month == now.month &&
          item.playedAt.year == now.year) {
        key = '今天';
      } else if (item.playedAt.day == now.day - 1 &&
          item.playedAt.month == now.month &&
          item.playedAt.year == now.year) {
        key = '昨天';
      } else {
        key = '${item.playedAt.year}年${item.playedAt.month}月${item.playedAt.day}日';
      }

      groups.putIfAbsent(key, () => []).add(item);
    }

    // 定义排序顺序
    final order = ['刚刚', '今天', '昨天'];

    final sortedEntries = groups.entries.toList()
      ..sort((a, b) {
        final aIndex = order.indexOf(a.key);
        final bIndex = order.indexOf(b.key);
        if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
        if (aIndex >= 0) return -1;
        if (bIndex >= 0) return 1;
        return b.key.compareTo(a.key);
      });

    return sortedEntries.map((e) => HistoryGroup(
      label: e.key,
      items: e.value,
    )).toList();
  }

  /// 分组中的歌曲数量
  int get count => items.length;
}
