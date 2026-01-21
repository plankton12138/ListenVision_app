/// Models Export - Clean Architecture 统一导出
///
/// 此文件作为项目领域实体和平台账号基础设施的统一导出点
/// 遵循 Clean Architecture 原则，所有业务实体在 domain/entities/ 中定义

// ========== Imports ==========
import 'dart:typed_data';
import 'package:demo/models/audio_model.dart' as local_audio;
import 'package:demo/domain/entities/audio.dart' as online_audio;

// ========== 平台账号基础设施 ==========
// 这些文件定义了跨平台账号绑定的抽象接口
// 不属于纯粹的领域实体，而是基础设施代码，保留在 models/ 中
export '../../models/platform_account.dart' show PlatformType, PlatformAccount, PlatformAccountStatus;
export '../../models/bilibili_account.dart' show BilibiliAccount, BilibiliUserInfo;
export '../../models/platform_binding_model.dart' show PlatformBindingModel;

// ========== 领域 Entities ==========
// Clean Architecture 核心实体，使用 Freezed 生成
export 'audio.dart' show Audio;
export 'user.dart' show User;
export 'recommendation.dart';
export 'play_history.dart';
export 'playlist.dart' show Playlist, PlaylistItem, PlaylistDetail, PlaylistType, SystemPlaylistType;

// ========== 兼容性类型定义 ==========
// 注意：类型别名和兼容类型已移至 domain_types.dart
// 此处保留空注释作为迁移标记

// ========== 兼容性扩展 ==========
//
// 保留必要的兼容层用于本地 Audio 和在线 Audio 之间的转换

/// 在线 Audio 的兼容性扩展
/// 转换为本地 Audio 格式（用于本地数据库兼容）
extension OnlineAudioCompatibilityExtension on online_audio.Audio {
  /// 转换为本地 Audio 格式
  local_audio.Audio toLocalAudio({String? filePath, Uint8List? albumArt, bool isFavorite = false}) {
    return local_audio.Audio(
      id: int.tryParse(id),
      filePath: filePath ?? '',
      title: title,
      artist: artist ?? '未知艺术家',
      duration: duration ?? 0,
      albumArt: albumArt,
      url: streamUrl,
      isFavorite: isFavorite,
    );
  }
}

/// 本地 Audio 的兼容性扩展
/// 转换为在线 Audio 格式
extension LocalAudioCompatibilityExtension on local_audio.Audio {
  /// 转换为在线 Audio 格式
  online_audio.Audio toOnlineAudio() {
    return online_audio.Audio(
      id: id?.toString() ?? url ?? '',
      title: title,
      artist: artist,
      duration: duration,
      coverUrl: null,
      streamUrl: url,
    );
  }
}

// ========== 类型转换辅助函数 ==========

/// 类型转换工具类
class ModelConverter {
  /// 将在线 Audio 列表转换为本地格式
  static List<local_audio.Audio> audioListToLocal(List<online_audio.Audio> onlineAudios) {
    return onlineAudios.map((a) => a.toLocalAudio()).toList();
  }

  /// 将本地 Audio 列表转换为在线格式
  static List<online_audio.Audio> audioListToOnline(List<local_audio.Audio> localAudios) {
    return localAudios.map((a) => a.toOnlineAudio()).toList();
  }

  /// 安全地将 dynamic 转换为 int
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 安全地将 dynamic 转换为 String
  static String asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// 安全地将 dynamic 转换为 bool
  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}
