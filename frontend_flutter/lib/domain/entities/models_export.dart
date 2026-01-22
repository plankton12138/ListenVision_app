/// Models Export - Clean Architecture 统一导出
///
/// 此文件作为项目领域实体的统一导出点
/// 遵循 Clean Architecture 原则，所有业务实体在 domain/entities/ 中定义

// ========== 领域 Entities ==========
// Clean Architecture 核心实体，使用 Freezed 生成
export 'audio.dart' show Audio;
export 'user.dart' show User;
export 'recommendation.dart';
export 'play_history.dart';
export 'playlist.dart' show Playlist, PlaylistItem, PlaylistDetail, PlaylistType, SystemPlaylistType;
export 'download_task.dart' show DownloadTask, DownloadStatus;

// ========== Phase 2: 可播放音频接口 ==========
// 统一本地音频和在线音频的播放接口
export 'playable_audio.dart' show PlayableAudio;
export 'local_playable.dart' show LocalPlayable;
export 'online_playable.dart' show OnlinePlayable;

// ========== 类型定义 ==========
// 类型别名和兼容类型在 domain_types.dart 中定义
