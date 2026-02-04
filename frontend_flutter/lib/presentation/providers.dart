/// Riverpod Providers 统一定义
///
/// 本文件集中定义所有 Riverpod providers
library;

// ==================== 认证相关 ====================
export 'viewmodels/auth/auth_viewmodel.dart' show authViewModelProvider;
export 'viewmodels/auth/auth_viewmodel.dart' show currentUser;
export 'viewmodels/auth/auth_viewmodel.dart' show authToken;
export 'viewmodels/auth/auth_viewmodel.dart' show isLoggedIn;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show platformAuthViewModelProvider;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show boundPlatformAccount;
export 'viewmodels/auth/platform_auth_viewmodel.dart' show isBilibiliBound;

// TODO: 分阶段添加其他 ViewModels 的 providers
// ==================== 播放器相关 ====================
// export 'viewmodels/player/player_viewmodel.dart';
// export 'viewmodels/player/queue_viewmodel.dart';
// export 'viewmodels/player/metadata_viewmodel.dart';

// ==================== 资源库相关 ====================
// export 'viewmodels/library/playlist_viewmodel.dart';
// export 'viewmodels/library/history_viewmodel.dart';

// ==================== 发现相关 ====================
// export 'viewmodels/discovery/search_viewmodel.dart';

// ==================== 系统相关 ====================
// export 'viewmodels/system/theme_viewmodel.dart';
// export 'viewmodels/system/download_viewmodel.dart';
