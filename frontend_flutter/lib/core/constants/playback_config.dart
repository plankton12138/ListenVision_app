/// 音频播放配置
///
/// 集中管理所有播放相关的常量配置
class PlaybackConfig {
  // 私有构造函数，防止实例化
  PlaybackConfig._();

  // ==================== 超时配置 ====================

  /// 本地音频源加载超时
  static const Duration localSourceTimeout = Duration(seconds: 5);

  /// 在线音频源加载超时
  static const Duration onlineSourceTimeout = Duration(seconds: 10);

  /// 时长等待超时
  static const Duration durationWaitTimeout = Duration(seconds: 5);

  // ==================== 间隔配置 ====================

  /// 播放位置保存间隔
  static const Duration positionSaveInterval = Duration(seconds: 5);

  /// 播放进度更新间隔
  static const Duration progressUpdateInterval = Duration(seconds: 30);

  // ==================== 防抖/节流配置 ====================

  /// 播放操作防抖延迟
  static const Duration playDebounceDelay = Duration(milliseconds: 300);

  /// 切歌操作节流延迟
  static const Duration skipThrottleDelay = Duration(milliseconds: 500);

  /// 设置保存防抖延迟
  static const Duration settingsDebounceDelay = Duration(seconds: 2);

  /// 保存防抖延迟
  static const Duration saveDebounceDelay = Duration(milliseconds: 500);

  // ==================== 缓存配置 ====================

  /// 封面缓存最大数量
  static const int maxCoverCacheSize = 50;

  /// 播放队列最大长度
  static const int maxQueueLength = 10;

  // ==================== 状态更新配置 ====================

  /// 最小状态更新间隔
  static const Duration minStateUpdateInterval = Duration(milliseconds: 50);

  /// 状态保护基础时长
  static const Duration protectionBaseDuration = Duration(milliseconds: 500);

  /// 状态保护最大时长
  static const Duration protectionMaxDuration = Duration(seconds: 1);

  // ==================== 网络配置 ====================

  /// 预加载字节数
  static const int preloadBytes = 1024 * 512; // 512KB
}
