/// Models Export - 渐进式迁移的过渡导出文件
///
/// 此文件作为旧 models 到新 entities 的过渡桥梁
/// 当所有文件迁移完成后，此文件将被删除
///
/// 迁移指南：
/// 1. 将 import 'package:demo/models/xxx.dart'
/// 2. 改为 import 'package:demo/domain/entities/models_export.dart'
/// 3. 后续再统一改为 import 'package:demo/domain/entities/xxx.dart'

// ========== 平台账号（保留在 models/ 中）==========
// 这些文件定义了跨平台账号绑定的抽象接口
// 不属于纯粹的领域实体，而是基础设施代码
export '../../models/platform_account.dart';
export '../../models/bilibili_account.dart';
export '../../models/platform_binding_model.dart';

// ========== 旧 models（标记为已弃用，保留兼容性）==========
// @Deprecated('使用 domain/entities/playlist.dart 代替')
export '../../models/playlist.dart show
  Playlist,
  PlaylistItem,
  PlaylistType,
  SystemPlaylistType,
  PlaylistDetail;

// @Deprecated('使用 domain/entities/play_history.dart 代替')
export '../../models/play_history.dart show
  PlayHistoryItem,
  PlayHistoryStats;

// @Deprecated('使用 domain/entities/recommendation.dart 代替')
export '../../models/recommendation.dart show
  RecommendationItem,
  BiliPlaylist,
  BiliPlaylistStatistic,
  BiliAudioPreview,
  BiliPlaylistsResponse,
  PersonalizedResponse,
  CategoryRecommendation,
  CategoryRecommendationResponse,
  MusicRecommendationResponse;

// ========== 新 Entities ==========
// 这些是新架构的 Clean Architecture entities
export 'audio.dart' show Audio;
export 'user.dart' show User;
export 'recommendation.dart' show Recommendation, RecommendationType, BiliPlaylistStats, RecommendationResponse, PersonalizedResponse;
export 'play_history.dart' show PlayHistory, PlayHistoryStats;
export 'playlist.dart' show Playlist, PlaylistItem, PlaylistDetail, PlaylistType, SystemPlaylistType;
