/// Models Export - Clean Architecture 统一导出
///
/// 此文件作为项目领域实体的统一导出点
/// 遵循 Clean Architecture 原则，所有业务实体在 domain/entities/ 中定义

// ========== Imports ==========
import 'dart:typed_data';

// ========== 领域 Entities ==========
// Clean Architecture 核心实体，使用 Freezed 生成
export 'audio.dart' show Audio;
export 'user.dart' show User;
export 'recommendation.dart';
export 'play_history.dart';
export 'playlist.dart' show Playlist, PlaylistItem, PlaylistDetail, PlaylistType, SystemPlaylistType;
export 'download_task.dart' show DownloadTask, DownloadStatus;

// ========== 类型定义 ==========
// 类型别名和兼容类型在 domain_types.dart 中定义
