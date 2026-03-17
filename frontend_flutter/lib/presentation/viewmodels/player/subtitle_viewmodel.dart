import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/subtitle_repository.dart';
import '../../../models/subtitle.dart';

part 'subtitle_viewmodel.g.dart';
part 'subtitle_viewmodel.freezed.dart';

/// 字幕状态
@freezed
abstract class SubtitleState with _$SubtitleState {
  const factory SubtitleState({
    @Default(null) SubtitleData? data,           // 字幕数据
    @Default(null) SubtitleTrack? activeTrack,   // 当前激活的语言
    @Default(-1) int currentLineIndex,           // 当前高亮行索引
    @Default(false) bool isLoading,
    @Default(false) bool isVisible,              // 字幕面板是否展开
    @Default(true) bool isSubtitleEnabled,       // 字幕是否开启（用户可通过菜单关闭）
    @Default(null) String? error,
    @Default(false) bool needLogin,              // 是否需要登录才能获取字幕
  }) = _SubtitleState;

  factory SubtitleState.fromJson(Map<String, dynamic> json) =>
      _$SubtitleStateFromJson(json);
}

@riverpod
class SubtitleViewModel extends _$SubtitleViewModel {
  int _loadRequestId = 0;

  @override
  SubtitleState build() => const SubtitleState();

  /// 加载字幕
  /// [cid] 可选，用于多P视频获取指定分P的字幕
  Future<void> loadSubtitle(String bvid, {int? cid, Duration initialPosition = Duration.zero}) async {
    // 检查 provider 是否仍然有效
    if (!ref.mounted) return;

    final requestId = ++_loadRequestId;

    // 检查是否需要重新加载（bvid 变化，或 cid 明确指定且变化）
    // 注意：如果 cid 为 null，总是重新加载（因为后端可能返回不同的 cid）
    if (cid != null && state.data?.bvid == bvid && state.data?.cid == cid && state.activeTrack != null && state.error == null) {
      updatePosition(initialPosition);
      return; // 已加载且可用
    }

    state = state.copyWith(
      data: null,
      activeTrack: null,
      currentLineIndex: -1,
      isLoading: true,
      error: null,
      needLogin: false,
    );

    try {
      final repo = ref.read(subtitleRepositoryProvider);
      final data = await repo.getSubtitle(bvid, cid: cid);

      if (requestId != _loadRequestId || !ref.mounted) {
        return;
      }

      if (data != null && data.subtitles.isNotEmpty) {
        // 默认选中中文字幕（支持 zh-Hans, zh-CN, ai-zh 等格式）
        final defaultTrack = data.subtitles.firstWhere(
          (t) => t.lan.contains('zh'),
          orElse: () => data.subtitles.first,
        );

        // 调试日志：记录字幕数据范围
        if (defaultTrack.lines.isNotEmpty) {
          final firstLine = defaultTrack.lines.first;
          final lastLine = defaultTrack.lines.last;
          AppLogger.info('SubtitleViewModel',
            '字幕加载成功: bvid=${data.bvid}, cid=${data.cid}, lan=${defaultTrack.lan}, '
            '总行数=${defaultTrack.lines.length}, '
            '时间范围[${firstLine.from}-${lastLine.to}s]');
        }

        state = state.copyWith(
          data: data,
          activeTrack: defaultTrack,
          isLoading: false,
          needLogin: false,
          isSubtitleEnabled: true,
        );
        updatePosition(initialPosition);
      } else {
        state = state.copyWith(
          data: data,
          activeTrack: null,
          currentLineIndex: -1,
          isLoading: false,
          needLogin: data?.needLogin ?? false,
        );
      }
    } catch (e) {
      if (requestId != _loadRequestId || !ref.mounted) {
        return;
      }

      state = state.copyWith(
        data: null,
        activeTrack: null,
        currentLineIndex: -1,
        isLoading: false,
        error: e.toString(),
        needLogin: false,
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
      // 调试日志：记录字幕匹配变化
      if (index >= 0 && index < lines.length) {
        final line = lines[index];
        AppLogger.debug('SubtitleViewModel',
          '字幕切换: index=$index, 播放位置=${seconds.toStringAsFixed(2)}s, '
          '字幕时间[${line.from.toStringAsFixed(2)}-${line.to.toStringAsFixed(2)}s], '
          '内容=${line.content.substring(0, line.content.length > 20 ? 20 : line.content.length)}');
      } else {
        AppLogger.debug('SubtitleViewModel', '字幕无匹配: index=$index, 播放位置=${seconds.toStringAsFixed(2)}s');
      }
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

  /// 开启/关闭字幕（不改变语言选择）
  void setSubtitleEnabled(bool enabled) {
    state = state.copyWith(isSubtitleEnabled: enabled);
  }

  /// 清除字幕（切歌时调用）
  void clear() {
    _loadRequestId++;
    state = const SubtitleState();
  }

  /// 二分查找：找到当前应该显示的字幕行
  /// 策略：找到最后一个 from <= position 的行
  /// 如果 position 处于字幕行之间的间隙，显示上一行（避免闪烁）
  /// 如果 position 在所有字幕之前，返回 -1
  int _findCurrentLine(List<SubtitleLine> lines, double position) {
    if (lines.isEmpty) return -1;

    // 如果 position 在第一条字幕之前，不显示
    if (position < lines.first.from) return -1;

    int low = 0, high = lines.length - 1;
    int result = -1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      final line = lines[mid];

      if (line.from <= position) {
        // 当前行开始时间 <= position，可能是目标行
        result = mid;
        low = mid + 1;
      } else {
        // 当前行开始时间 > position，往前找
        high = mid - 1;
      }
    }

    return result;
  }
}
