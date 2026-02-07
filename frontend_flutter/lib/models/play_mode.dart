/// 播放模式
///
/// 定义音频播放的循环模式
enum PlayMode {
  /// 顺序播放
  sequence,

  /// 列表循环
  loopAll,

  /// 随机播放
  shuffle,

  /// 单曲循环
  loopOne,
}

/// PlayMode 扩展
extension PlayModeExtension on PlayMode {
  /// 显示名称
  String get displayName {
    switch (this) {
      case PlayMode.sequence:
        return '顺序';
      case PlayMode.loopAll:
        return '列表循环';
      case PlayMode.shuffle:
        return '随机';
      case PlayMode.loopOne:
        return '单曲循环';
    }
  }

  /// 图标
  String get icon {
    switch (this) {
      case PlayMode.sequence:
        return '🔀';
      case PlayMode.loopAll:
        return '🔁';
      case PlayMode.shuffle:
        return '🔀';
      case PlayMode.loopOne:
        return '🔂';
    }
  }

  /// 切换到下一个模式
  PlayMode next() {
    final values = PlayMode.values;
    final currentIndex = values.indexOf(this);
    return values[(currentIndex + 1) % values.length];
  }

  /// 是否为循环模式
  bool get isLoop => this == PlayMode.loopAll || this == PlayMode.loopOne;

  /// 是否为单曲循环
  bool get isLoopOne => this == PlayMode.loopOne;

  /// 是否为随机播放
  bool get isShuffle => this == PlayMode.shuffle;
}
