/// 播放状态（不可变）
///
/// 提供统一的播放状态视图，减少状态分散在多个类中的问题。
/// 这个类聚合了来自 PlaybackController 的核心播放状态信息。
class PlaybackState {
  /// 是否正在播放
  final bool isPlaying;

  /// 是否已暂停
  final bool isPaused;

  /// 是否已完成
  final bool isCompleted;

  /// 是否正在加载
  final bool isLoading;

  /// 当前播放位置
  final Duration position;

  /// 音频总时长
  final Duration? duration;

  /// 错误消息（由外部管理）
  final String? errorMessage;

  const PlaybackState({
    this.isPlaying = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration,
    this.errorMessage,
  });

  /// 创建副本并选择性更新字段
  ///
  /// 返回一个新的 PlaybackState 实例，仅更新指定的字段。
  ///
  /// 注意：由于 Dart 类型系统限制，如果要将 errorMessage 设置为 null，
  /// 需要使用其他方式（例如创建新的 PlaybackState 实例）。
  PlaybackState copyWith({
    bool? isPlaying,
    bool? isPaused,
    bool? isCompleted,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 清除错误消息
  PlaybackState copyWithNoError() {
    return PlaybackState(
      isPlaying: isPlaying,
      isPaused: isPaused,
      isCompleted: isCompleted,
      isLoading: isLoading,
      position: position,
      duration: duration,
      errorMessage: null,
    );
  }

  @override
  String toString() {
    return 'PlaybackState(isPlaying: $isPlaying, isPaused: $isPaused, isCompleted: $isCompleted, isLoading: $isLoading, position: $position, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaybackState &&
        other.isPlaying == isPlaying &&
        other.isPaused == isPaused &&
        other.isCompleted == isCompleted &&
        other.isLoading == isLoading &&
        other.position == position &&
        other.duration == duration &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return isPlaying.hashCode ^
        isPaused.hashCode ^
        isCompleted.hashCode ^
        isLoading.hashCode ^
        position.hashCode ^
        duration.hashCode ^
        errorMessage.hashCode;
  }
}
