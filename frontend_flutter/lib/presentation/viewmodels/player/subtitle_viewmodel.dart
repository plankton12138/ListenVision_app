import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/subtitle_repository.dart';
import '../../../models/subtitle.dart';

part 'subtitle_viewmodel.freezed.dart';
part 'subtitle_viewmodel.g.dart';

/// 字幕状态
@freezed
class SubtitleState with _$SubtitleState {
  const factory SubtitleState({
    @Default(null) SubtitleData? data,           // 字幕数据
    @Default(null) SubtitleTrack? activeTrack,   // 当前激活的语言
    @Default(-1) int currentLineIndex,           // 当前高亮行索引
    @Default(false) bool isLoading,
    @Default(false) bool isVisible,              // 字幕面板是否展开
    @Default(null) String? error,
  }) = _SubtitleState;
}

@riverpod
class SubtitleViewModel extends _$SubtitleViewModel {
  @override
  SubtitleState build() => const SubtitleState();

  /// 加载字幕
  Future<void> loadSubtitle(String bvid) async {
    if (state.data?.bvid == bvid) return; // 已加载
    state = state.copyWith(isLoading: true, error: null);

    final repo = ref.read(subtitleRepositoryProvider);
    final data = await repo.getSubtitle(bvid);

    if (data != null && data.subtitles.isNotEmpty) {
      // 默认选中中文字幕，无中文则选第一个
      final defaultTrack = data.subtitles.firstWhere(
        (t) => t.lan.startsWith('zh'),
        orElse: () => data.subtitles.first,
      );
      state = state.copyWith(
        data: data,
        activeTrack: defaultTrack,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        data: data,
        activeTrack: null,
        isLoading: false,
      );
    }
  }

  /// 根据播放进度更新当前行（由 PlayerViewModel 调用）
  void updatePosition(Duration position) {
    final track = state.activeTrack;
    if (track == null) return;

    final seconds = position.inMilliseconds / 1000.0;
    final lines = track.lines;

    // 二分查找当前行
    int index = _findCurrentLine(lines, seconds);
    if (index != state.currentLineIndex) {
      state = state.copyWith(currentLineIndex: index);
    }
  }

  /// 切换字幕语言
  void switchLanguage(String lan) {
    if (state.data == null) return;
    
    final track = state.data!.subtitles.firstWhere(
      (t) => t.lan == lan,
      orElse: () => state.data!.subtitles.first,
    );
    state = state.copyWith(activeTrack: track, currentLineIndex: -1);
  }

  /// 切换字幕显示/隐藏
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// 清除字幕（切歌时调用）
  void clear() {
    state = const SubtitleState();
  }

  /// 二分查找：找到最后一个 from <= position 的行
  /// 注意：原始实现是找到 "from <= position 且 to > position"
  /// 但有些字幕行之间有空隙，或者长时间不说话，这种情况下也显示上一句（或者保持显示）可能更好，
  /// 或者如果不满足 interval 则显示 -1。
  /// 此处实现：显示 time 在 [from, to] 区间内的行。
  int _findCurrentLine(List<SubtitleLine> lines, double position) {
    if (lines.isEmpty) return -1;

    int low = 0, high = lines.length - 1;
    
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      final line = lines[mid];
      
      if (position >= line.from && position < line.to) {
        return mid;
      } else if (position < line.from) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return -1;
  }
}
