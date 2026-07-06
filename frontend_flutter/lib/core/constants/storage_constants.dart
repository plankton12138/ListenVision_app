/// 存储常量定义
///
/// 集中管理所有本地存储相关的配置

/// SharedPreferences 键名常量
///
/// 别名：StorageConstants（向后兼容）
class StorageKeys {
  // ==================== 设置相关 ====================

  /// 主题模式
  static const String themeMode = 'theme_mode';

  /// 语言设置
  static const String language = 'language';

  /// 自动播放
  static const String autoPlay = 'auto_play';

  /// 播放质量
  static const String playQuality = 'play_quality';

  /// 下载音频格式
  static const String downloadFormat = 'download_format';

  /// 下载封面
  static const String downloadCover = 'download_cover';

  // ==================== 缓存相关 ====================

  /// 歌单缓存
  static const String playlistsCache = 'playlists_cache';

  /// 收藏缓存
  static const String favoritesCache = 'favorites_cache';

  /// 搜索历史
  static const String searchHistory = 'search_history';

  /// 最近搜索
  static const String recentSearches = 'recent_searches';

  // ==================== 其他 ====================

  /// 首次启动
  static const String isFirstLaunch = 'is_first_launch';

  /// 最后播放的音频
  static const String lastPlayedAudio = 'last_played_audio';

  /// @deprecated 使用 [currentPlaybackPosition] 代替
  /// 播放位置（旧键，保留以兼容历史数据迁移）
  static const String playbackPosition = 'playback_position';

  // ==================== Phase 2 遗留问题: 统一播放列表持久化 ====================

  /// 统一播放列表（JSON）
  static const String unifiedPlaylist = 'unified_playlist';

  /// 当前播放索引
  static const String currentPlaylistIndex = 'current_playlist_index';

  /// 当前播放位置（秒）
  static const String currentPlaybackPosition = 'current_playback_position';

  /// 队列来源（JSON）
  static const String queueSource = 'queue_source';

  /// 播放模式
  static const String playMode = 'play_mode';

  /// 是否正在播放在线音频
  static const String isCurrentOnline = 'is_current_online';

  /// 最后播放索引
  static const String keyLastIndex = 'last_playlist_index';

  /// 是否是在线音频（恢复用）
  static const String keyWasOnline = 'was_online_audio';

  // ==================== Phase 3B: 播放控制设置 ====================

  /// 播放音量（0.0 - 1.0）
  static const String playbackVolume = 'playback_volume';

  /// 播放倍速（0.5x - 2.0x）
  static const String playbackSpeed = 'playback_speed';
}

/// StorageConstants 别名（向后兼容）
typedef StorageConstants = StorageKeys;

/// 存储过期时间常量
class StorageExpiry {
  /// 搜索历史保留时间（30天）
  static const Duration searchHistoryExpiry = Duration(days: 30);

  /// 缓存数据保留时间（1天）
  static const Duration cacheExpiry = Duration(days: 1);

}

/// 日志系统常量
class LogConstants {
  /// 日志目录名称
  static const String logDirectoryName = 'logs';

  /// 单个日志文件最大大小（5MB）
  static const int maxLogFileSize = 5 * 1024 * 1024;

  /// 最多保留的日志文件数量
  static const int maxLogFiles = 5;

  /// 日志文件名前缀
  static const String logFilePrefix = 'app';

  /// 日志文件扩展名
  static const String logFileExtension = '.log';

  /// 获取当前日志文件名（带日期）
  static String getCurrentLogFileName() {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '${logFilePrefix}_$dateStr$logFileExtension';
  }
}
