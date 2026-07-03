/// 播放状态枚举
///
/// 统一定义应用的播放状态，与 media_kit 的 Player.state 解耦
enum PlaybackStatus {
  /// 空闲状态 - 未加载任何音频
  idle,

  /// 加载中 - 正在加载音频源或元数据
  loading,

  /// 就绪 - 音频已加载，等待播放
  ready,

  /// 播放中
  playing,

  /// 已暂停
  paused,

  /// 播放完成
  completed,

  /// 错误状态
  error,
}

/// 播放状态扩展方法
extension PlaybackStatusExtension on PlaybackStatus {
  /// 是否可以播放
  bool get canPlay => this == PlaybackStatus.ready || this == PlaybackStatus.paused;

  /// 是否可以暂停
  bool get canPause => this == PlaybackStatus.playing;

  /// 是否正在播放（包括缓冲中）
  bool get isActive => this == PlaybackStatus.playing || this == PlaybackStatus.loading;

  /// 是否显示加载指示器
  bool get showLoading => this == PlaybackStatus.loading;

  /// 用户友好的状态描述
  String get description {
    switch (this) {
      case PlaybackStatus.idle:
        return '未播放';
      case PlaybackStatus.loading:
        return '加载中...';
      case PlaybackStatus.ready:
        return '准备就绪';
      case PlaybackStatus.playing:
        return '播放中';
      case PlaybackStatus.paused:
        return '已暂停';
      case PlaybackStatus.completed:
        return '播放完成';
      case PlaybackStatus.error:
        return '播放错误';
    }
  }
}
