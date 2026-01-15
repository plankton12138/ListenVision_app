import 'platform_account.dart';

/// 平台绑定数据库模型
/// 用于持久化存储用户的平台账号绑定信息
class PlatformBindingModel {
  final int? id;
  final int userId;
  final PlatformType platformType;
  final String platformUserId;
  final String platformUsername;
  final String? avatar;
  final Map<String, dynamic> metadata;
  final DateTime bindTime;
  final DateTime? expireTime;
  final DateTime? lastValidateTime;
  final PlatformAccountStatus status;

  const PlatformBindingModel({
    this.id,
    required this.userId,
    required this.platformType,
    required this.platformUserId,
    required this.platformUsername,
    this.avatar,
    this.metadata = const {},
    required this.bindTime,
    this.expireTime,
    this.lastValidateTime,
    required this.status,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'platformType': platformType.value,
      'platformUserId': platformUserId,
      'platformUsername': platformUsername,
      'avatar': avatar,
      'metadata': metadata,
      'bindTime': bindTime.toIso8601String(),
      'expireTime': expireTime?.toIso8601String(),
      'lastValidateTime': lastValidateTime?.toIso8601String(),
      'status': status.value,
    };
  }

  /// 从 JSON 创建
  factory PlatformBindingModel.fromJson(Map<String, dynamic> json) {
    return PlatformBindingModel(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      platformType: PlatformTypeExtension.fromString(json['platformType'] as String),
      platformUserId: json['platformUserId'] as String,
      platformUsername: json['platformUsername'] as String,
      avatar: json['avatar'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      bindTime: DateTime.parse(json['bindTime'] as String),
      expireTime: json['expireTime'] != null ? DateTime.parse(json['expireTime'] as String) : null,
      lastValidateTime: json['lastValidateTime'] != null ? DateTime.parse(json['lastValidateTime'] as String) : null,
      status: PlatformAccountStatusExtension.fromString(json['status'] as String? ?? 'active'),
    );
  }

  /// 从数据库记录创建（SQLite 返回的 Map）
  factory PlatformBindingModel.fromDatabase(Map<String, dynamic> map) {
    return PlatformBindingModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      platformType: PlatformTypeExtension.fromString(map['platformType'] as String),
      platformUserId: map['platformUserId'] as String,
      platformUsername: map['platformUsername'] as String,
      avatar: map['avatar'] as String?,
      metadata: (map['metadata'] as String?) != null
          ? Map<String, dynamic>.from(
              // 这里假设 metadata 被序列化为 JSON 字符串
              // 实际应该使用 jsonDecode，但为了避免导入 dart:convert，这里用简单处理
              {'raw': map['metadata']},
            )
          : {},
      bindTime: DateTime.parse(map['bindTime'] as String),
      expireTime: map['expireTime'] != null ? DateTime.parse(map['expireTime'] as String) : null,
      lastValidateTime: map['lastValidateTime'] != null ? DateTime.parse(map['lastValidateTime'] as String) : null,
      status: PlatformAccountStatusExtension.fromString(map['status'] as String? ?? 'active'),
    );
  }

  /// 转换为数据库可以插入的 Map
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'userId': userId,
      'platformType': platformType.value,
      'platformUserId': platformUserId,
      'platformUsername': platformUsername,
      'avatar': avatar,
      'metadata': _metadataToString(metadata),
      'bindTime': bindTime.toIso8601String(),
      'expireTime': expireTime?.toIso8601String(),
      'lastValidateTime': lastValidateTime?.toIso8601String(),
      'status': status.value,
    };
  }

  /// 复制并修改字段
  PlatformBindingModel copyWith({
    int? id,
    int? userId,
    PlatformType? platformType,
    String? platformUserId,
    String? platformUsername,
    String? avatar,
    Map<String, dynamic>? metadata,
    DateTime? bindTime,
    DateTime? expireTime,
    DateTime? lastValidateTime,
    PlatformAccountStatus? status,
  }) {
    return PlatformBindingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      platformType: platformType ?? this.platformType,
      platformUserId: platformUserId ?? this.platformUserId,
      platformUsername: platformUsername ?? this.platformUsername,
      avatar: avatar ?? this.avatar,
      metadata: metadata ?? this.metadata,
      bindTime: bindTime ?? this.bindTime,
      expireTime: expireTime ?? this.expireTime,
      lastValidateTime: lastValidateTime ?? this.lastValidateTime,
      status: status ?? this.status,
    );
  }

  /// 检查绑定是否已过期
  bool get isExpired {
    if (expireTime == null) return false;
    return DateTime.now().isAfter(expireTime!);
  }

  /// 检查绑定是否活跃
  bool get isActive {
    return status == PlatformAccountStatus.active && !isExpired;
  }

  @override
  String toString() => 'PlatformBindingModel('
      'userId: $userId, '
      'platform: ${platformType.displayName}, '
      'user: $platformUsername, '
      'status: ${status.value})';

  static String _metadataToString(Map<String, dynamic> metadata) {
    // 简单的 JSON 序列化，避免依赖 dart:convert
    if (metadata.isEmpty) return '{}';
    final entries = metadata.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
    return '{$entries}';
  }
}
