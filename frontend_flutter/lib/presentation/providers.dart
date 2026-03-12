/// Riverpod Providers 统一定义
///
/// 本文件集中定义所有 Riverpod providers
library;

// ==================== Repository 层（本地优先架构）====================
export '../data/repositories/repository_providers.dart';

// ==================== 同步机制 ====================
export '../data/sync/sync_worker_provider.dart' show syncWorkerProvider;
export '../data/sync/sync_worker_provider.dart' show syncStatsProvider;
export '../data/sync/sync_worker_provider.dart' show hasPendingSyncTasksProvider;
export '../data/database/sync_queue_dao.dart' show SyncQueueStats;

// ==================== 认证相关 ====================
export 'viewmodels/auth/auth_viewmodel.dart' show authViewModelProvider;
export 'viewmodels/auth/auth_viewmodel.dart' show currentUserProvider;
export 'viewmodels/auth/auth_viewmodel.dart' show authTokenProvider;
export 'viewmodels/auth/auth_viewmodel.dart' show isLoggedInProvider;
export 'viewmodels/auth/auth_viewmodel.dart' show AuthState;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show platformAuthViewModelProvider;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show boundBilibiliAccount;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show isBilibiliBound;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show isBilibiliBoundProvider;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show QRLoginStatus;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show PlatformAuthState;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show PlatformAuthStateBound;
export 'viewmodels/auth/netease_auth_viewmodel.dart' show neteaseAuthViewModelProvider;
export 'viewmodels/auth/netease_auth_viewmodel.dart' show boundNeteaseAccount;
export 'viewmodels/auth/netease_auth_viewmodel.dart' show isNeteaseBound;
export 'viewmodels/auth/netease_auth_viewmodel.dart' show NeteaseQRLoginStatus;
export 'viewmodels/auth/netease_auth_viewmodel.dart' show NeteaseAuthState;
export 'viewmodels/auth/netease_auth_viewmodel.dart' show NeteaseAuthStateBound;
// ==================== 字幕 ====================
export 'viewmodels/player/subtitle_viewmodel.dart';
export '../data/repositories/subtitle_repository.dart';
export '../models/subtitle.dart';
// ==================== 播放器相关 ====================
export 'viewmodels/player/player_viewmodel.dart' show playerViewModelProvider;
export 'viewmodels/player/player_viewmodel.dart' show audioPlayerServiceProvider;
export 'viewmodels/player/queue_viewmodel.dart' show queueViewModelProvider;
export 'viewmodels/player/metadata_viewmodel.dart' show metadataViewModelProvider;
export 'viewmodels/player/metadata_viewmodel.dart' show metadataServiceProvider;

// ==================== 资源库相关 ====================
export 'viewmodels/library/playlist_viewmodel.dart' show playlistViewModelProvider;
export 'viewmodels/library/playlist_viewmodel.dart' show PlaylistState;
export 'viewmodels/library/playlist_detail_viewmodel.dart' show playlistDetailViewModelProvider;
export 'viewmodels/library/playlist_detail_viewmodel.dart' show PlaylistDetailState;
export 'viewmodels/library/history_viewmodel.dart' show historyViewModelProvider;
export 'viewmodels/library/history_viewmodel.dart' show historyStateProvider;
export 'viewmodels/library/history_viewmodel.dart' show HistoryState;
export 'viewmodels/library/history_viewmodel.dart' show PlayHistoryStats;
export '../../../models/play_history.dart' show PlayHistory;

// ==================== 发现相关 ====================
export 'viewmodels/discovery/search_viewmodel.dart' show searchViewModelProvider;
export 'viewmodels/discovery/explore_viewmodel.dart' show exploreViewModelProvider;
export 'viewmodels/discovery/explore_viewmodel.dart' show ExploreState;
export 'viewmodels/discovery/explore_viewmodel.dart' show ExploreType;
export 'viewmodels/discovery/explore_viewmodel.dart' show ExploreItem;

// ==================== 系统相关 ====================
export 'viewmodels/system/theme_viewmodel.dart' show themeViewModelProvider;
export 'viewmodels/system/theme_viewmodel.dart' show ThemeViewModel;
export 'viewmodels/system/download_viewmodel.dart' show downloadViewModelProvider;
