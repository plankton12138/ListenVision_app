import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 用户实体
@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String username,
    String? email,
    String? avatarUrl,
    @Default(false) bool isLoggedIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? token, // JWT token
  }) = _User;

  /// 从 JSON 创建
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// 从 DTO/后端响应创建（兼容旧格式）
  factory User.fromDto(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      isLoggedIn: true, // 从后端获取的用户表示已登录
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      token: json['token'] as String?,
    );
  }

  /// 是否有头像
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// 显示名称（优先使用 username）
  String get displayName => username.isNotEmpty ? username : '用户${id.substring(0, 6)}';

  /// 邮箱前缀
  String? get emailPrefix {
    if (email == null) return null;
    final atSignIndex = email!.indexOf('@');
    return atSignIndex > 0 ? email!.substring(0, atSignIndex) : email;
  }

  /// 判断token是否有效
  bool get hasValidToken => token != null && token!.isNotEmpty;

  /// 创建未登录的访客用户
  static const guest = User(
    id: 'guest',
    username: '访客',
    isLoggedIn: false,
  );

  /// 判断是否为访客
  bool get isGuest => id == 'guest' || !isLoggedIn;

  /// 解析 DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return null;
  }

  /// 转换为后端格式
  Map<String, dynamic> toDto() {
    return {
      'id': int.tryParse(id) ?? id,
      'username': username,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (token != null) 'token': token,
    };
  }
}
