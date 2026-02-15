import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'downloading_state_provider.g.dart';

/// 下载状态 Notifier
///
/// 管理当前正在下载的任务 ID 集合（内存状态）
@riverpod
class DownloadingState extends _$DownloadingState {
  @override
  Set<int> build() {
    return {};
  }

  /// 添加正在下载的任务 ID
  void add(int id) {
    state = {...state, id};
  }

  /// 移除正在下载的任务 ID
  void remove(int id) {
    final newSet = Set<int>.from(state)..remove(id);
    state = newSet;
  }

  /// 检查是否正在下载
  bool contains(int id) => state.contains(id);

  /// 清空所有
  void clear() {
    state = {};
  }
}
