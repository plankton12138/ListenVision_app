/// 存储常量定义
///
/// 集中管理所有本地存储相关的配置

/// SharedPreferences 键名常量
///
/// 别名：StorageConstants（向后兼容）
class StorageKeys {
  // ==================== 认证相关 ====================

  /// 用户 token
  static const String keyToken = 'auth_token';

  /// 用户 ID
  static const String keyUserId = 'user_id';

  /// 用户名
  static const String keyUsername = 'username';

  /// 用户信息
  static const String userInfo = 'user_info';

  /// 用户 token (向后兼容)
  static const String userToken = 'auth_token';

  /// 用户 ID (向后兼容)
  static const String userId = 'user_id';

  /// 用户名 (向后兼容)
  static const String username = 'username';

  // ==================== B站相关 ====================

  /// B站 Cookie
  static const String bilibiliCookie = 'bilibili_cookie';

  /// B站账号信息
  static const String bilibiliAccount = 'bilibili_account';

  /// B站绑定状态
  static const String bilibiliBound = 'bilibili_bound';

  // ==================== 设置相关 ====================

  /// 主题模式
  static const String themeMode = 'theme_mode';

  /// 语言设置
  static const String language = 'language';

  /// 自动播放
  static const String autoPlay = 'auto_play';

  /// 播放质量
  static const String playQuality = 'play_quality';

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

  /// 播放位置
  static const String playbackPosition = 'playback_position';
}

/// StorageConstants 别名（向后兼容）
typedef StorageConstants = StorageKeys;

/// 存储过期时间常量
class StorageExpiry {
  /// 认证 token 有效期（7天）
  static const Duration tokenExpiry = Duration(days: 7);

  /// 搜索历史保留时间（30天）
  static const Duration searchHistoryExpiry = Duration(days: 30);

  /// 缓存数据保留时间（1天）
  static const Duration cacheExpiry = Duration(days: 1);

  /// B站 Cookie 有效期（30天）
  static const Duration bilibiliCookieExpiry = Duration(days: 30);
}
