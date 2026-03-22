import '../../presentation/viewmodels/player/playback_viewmodel.dart';

/// 播放状态验证结果
class PlaybackStateValidationResult {
  /// 状态是否有效
  final bool isValid;

  /// 发现的问题列表
  final List<String> issues;

  const PlaybackStateValidationResult({
    required this.isValid,
    this.issues = const [],
  });
}

/// 播放状态验证器
///
/// 用于检测和修复播放状态的不一致问题，例如：
/// - isPlaying=true 但 currentPlayable=null
/// - isLoading 和 isPlaying 同时为 true
/// - isPlaying 和 isPaused 同时为 true
class PlaybackStateValidator {
  /// 验证状态完整性
  ///
  /// 检查以下规则：
  /// 1. 播放中必须有当前音频
  /// 2. 有效索引必须有对应音频
  /// 3. 加载中不应同时播放
  /// 4. 播放和暂停互斥
  static PlaybackStateValidationResult validate(PlaybackState state) {
    final issues = <String>[];

    // 规则 1: 播放中必须有当前音频
    if (state.isPlaying && state.currentPlayable == null) {
      issues.add('isPlaying=true 但 currentPlayable=null');
    }

    // 规则 2: 有效索引必须有对应音频
    if (state.currentIndex >= 0 && state.currentPlayable == null) {
      issues.add('currentIndex>=0 但 currentPlayable=null');
    }

    // 规则 3: 加载中不应同时播放
    if (state.isLoading && state.isPlaying) {
      issues.add('isLoading 和 isPlaying 同时为 true');
    }

    // 规则 4: 播放和暂停互斥
    if (state.isPlaying && state.isPaused) {
      issues.add('isPlaying 和 isPaused 同时为 true');
    }

    return PlaybackStateValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }

  /// 修复不一致状态
  ///
  /// 尝试自动修复以下问题：
  /// - isPlaying=true 但 currentPlayable=null -> 设置 isPlaying=false
  /// - isLoading 和 isPlaying 同时为 true -> 设置 isPlaying=false
  /// - isPlaying 和 isPaused 同时为 true -> 设置 isPaused=false
  static PlaybackState repair(PlaybackState state) {
    // 如果播放中但没有当前音频，停止播放
    if (state.isPlaying && state.currentPlayable == null) {
      return state.copyWith(isPlaying: false);
    }

    // 如果加载中和播放同时为 true，停止播放
    if (state.isLoading && state.isPlaying) {
      return state.copyWith(isPlaying: false);
    }

    // 如果播放和暂停同时为 true，取消暂停
    if (state.isPlaying && state.isPaused) {
      return state.copyWith(isPaused: false);
    }

    return state;
  }
}