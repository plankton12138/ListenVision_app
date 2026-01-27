import 'package:flutter/material.dart';

/// 应用常量定义
///
/// 集中管理所有应用级别的配置常量

// ==================== 应用信息 ====================

class AppInfo {
  static const String appName = 'ListenVision';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Listen to your favorite music';
}

// ==================== 系统歌单 ID ====================

class SystemPlaylistIds {
  /// 我喜欢歌单 ID
  static const int favorites = 1;

  /// 正在播放歌单 ID
  static const int nowPlaying = 2;

  /// 所有系统歌单 ID 列表
  static const List<int> all = [favorites, nowPlaying];
}

// ==================== 系统歌单名称 ====================

class SystemPlaylistNames {
  static const String favorites = '我喜欢';
  static const String nowPlaying = '正在播放';
}

// ==================== 数据库常量 ====================

class DatabaseConstants {
  /// 数据库名称
  static const String databaseName = 'listenvision.db';

  /// 数据库版本
  static const int databaseVersion = 1;

  /// 表名
  static const String usersTable = 'users';
  static const String playlistsTable = 'playlists';
  static const String playlistItemsTable = 'playlist_items';
  static const String playHistoryTable = 'play_history';
  static const String downloadsTable = 'downloads';
  static const String onlineQueueTable = 'online_queue';
  static const String bilibiliAccountsTable = 'bilibili_accounts';

  /// 分页大小
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

// ==================== 存储常量 ====================

class StorageConstants {
  /// 本地存储键名
  static const String keyToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFirstLaunch = 'first_launch';

  /// 加密存储键（需要加密的敏感数据）
  static const String encryptedKeyPrefix = 'enc_';
  static const String keyBilibiliCookie = '${encryptedKeyPrefix}bili_cookie';
  static const String keyBilibiliUid = '${encryptedKeyPrefix}bili_uid';
}

// ==================== 缓存常量 ====================

class CacheConstants {
  /// 默认缓存时间（毫秒）
  static const int defaultCacheDuration = 30 * 60 * 1000; // 30分钟

  /// 音频元数据缓存时间
  static const int audioMetadataCacheDuration = 24 * 60 * 60 * 1000; // 24小时

  /// 推荐内容缓存时间
  static const int recommendationCacheDuration = 60 * 60 * 1000; // 1小时

  /// 搜索结果缓存时间
  static const int searchCacheDuration = 10 * 60 * 1000; // 10分钟

  /// 最大缓存数量
  static const int maxCachedSearchResults = 100;
  static const int maxCachedMetadata = 500;
}

// ==================== B站常量 ====================

class BilibiliConstants {
  /// B站视频 URL
  static const String videoBaseUrl = 'https://www.bilibili.com/video/';

  /// BV号正则表达式
  static const String bvidPattern = r'BV[\w]{10}';

  /// B站头像默认 URL
  static const String defaultAvatar = 'https://static.hdslb.com/images/member/noface.gif';

  /// QR码登录状态
  static const String qrStatusNone = 'none';
  static const String qrStatusPending = 'pending';
  static const String qrStatusScanned = 'scanned';
  static const String qrStatusSuccess = 'success';
  static const String qrStatusExpired = 'expired';

  /// QR码有效期（秒）
  static const int qrCodeExpireTime = 180; // 3分钟

  /// QR码轮询间隔（毫秒）
  static const int qrPollInterval = 2000; // 2秒
}

// ==================== 播放常量 ====================

class PlaybackConstants {
  /// 默认音量 (0.0 - 1.0)
  static const double defaultVolume = 0.8;

  /// 最小/最大音量
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;

  /// 播放进度保存间隔（毫秒）
  static const int progressSaveInterval = 5000; // 5秒

  /// 播放模式
  static const String modeLoop = 'loop';       // 列表循环
  static const String modeSingle = 'single';   // 单曲循环
  static const String modeShuffle = 'shuffle'; // 随机播放
}

// ==================== 下载常量 ====================

class DownloadConstants {
  /// 同时下载任务数限制
  static const int maxConcurrentDownloads = 3;

  /// 下载超时时间（毫秒）
  static const int downloadTimeout = 60000; // 60秒

  /// 下载重试次数
  static const int maxRetryCount = 3;

  /// 默认下载目录名称
  static const String defaultDownloadDir = 'ListenVision Downloads';

  /// 音频文件格式
  static const List<String> supportedFormats = ['mp3', 'm4a', 'flac', 'ogg', 'wav'];
}

// ==================== UI 常量 ====================

class UIConstants {
  /// 图标尺寸（从 Dimens 迁移）
  static const double iconSmall = 22;
  static const double iconMedium = 28;
  static const double iconLarge = 42;

  /// 字体尺寸（从 Dimens 迁移）
  static const double fontSizeSmall = 12;
  static const double fontSizeMedium = 15;
  static const double fontSizeLarge = 19;
  static const double fontSizeXLarge = 24;
  /// 动画时长
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  /// SnackBar 显示时长
  static const Duration snackBarDurationShort = Duration(seconds: 1);
  static const Duration snackBarDurationNormal = Duration(seconds: 2);
  static const Duration snackBarDurationLong = Duration(seconds: 3);

  /// 对话框圆角
  static const double dialogBorderRadius = 12.0;

  /// 卡片圆角
  static const double cardBorderRadius = 8.0;

  /// 默认内边距
  static const double paddingSmall = 8.0;
  static const double paddingNormal = 16.0;
  static const double paddingLarge = 24.0;

  /// 默认间距
  static const double spacingSmall = 8.0;
  static const double spacingNormal = 16.0;
  static const double spacingLarge = 24.0;
}

// ==================== 正则表达式 ====================

class RegexPatterns {
  /// 邮箱验证
  static const String email =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// 密码验证（至少6位）
  static const String password = r'^.{6,}$';

  /// BV号提取
  static const String bvid = r'BV[\w]{10}';

  /// URL 验证
  static const String url =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$';
}

// ==================== 分页常量 ====================

class PaginationConstants {
  /// 搜索结果默认页大小
  static const int searchPageSize = 20;

  /// 播放历史默认页大小
  static const int historyPageSize = 20;

  /// 推荐内容默认数量
  static const int recommendationCount = 10;

  /// 最大页数（B站搜索限制）
  static const int maxSearchPage = 50;
}

// ==================== 主题常量 ====================

class ThemeConstants {
  /// 主题模式键
  static const String keyLightMode = 'light';
  static const String keyDarkMode = 'dark';
  static const String keySystemMode = 'system';

  /// 主色调
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.blueAccent;

  /// 错误颜色
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color successColor = Colors.green;
}
