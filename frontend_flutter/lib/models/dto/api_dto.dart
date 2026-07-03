import 'dart:convert';

// 注意：如需处理 API 异常，请使用
// import 'package:listen_vision/core/errors/exceptions.dart';
// 中的 ApiServerException

/// API 响应包装类
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: dataParser != null && json['data'] != null
          ? dataParser(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  /// 当成功时获取数据，否则抛出异常
  T getDataOrThrow() {
    if (success && data != null) {
      return data!;
    }
    throw ApiException(error ?? message ?? '请求失败');
  }
}

/// API 异常（已废弃）
///
/// 请使用 core/errors/exceptions.dart 中的 ApiServerException
@Deprecated('请使用 ApiServerException 替代')
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// 认证相关 DTO
class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponseDto {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
  final int userId;
  final String username;
  final String? email;
  final bool bilibiliBound;

  LoginResponseDto.fromJson(Map<String, dynamic> json)
      : accessToken = json['access_token'] as String,
        refreshToken = json['refresh_token'] as String?,
        expiresIn = json['expires_in'] as int? ?? 3600,
        userId = json['user']?['id'] as int? ?? _extractUserIdFromToken(json['access_token'] as String),
        username = json['user']?['username'] as String? ?? '',
        email = json['user']?['email'] as String?,
        bilibiliBound = json['bilibili_bound'] as bool? ?? false;

  /// 从 JWT token 中提取 userId（当响应中没有 userId 时）
  static int _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 0;

      // 解码 payload (添加必要的填充)
      String payload = parts[1];
      final padded = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Url.decode(padded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return json['user_id'] as int? ?? json['userId'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

class RegisterRequestDto {
  final String username;
  final String email;
  final String password;
  final String? captchaCode;

  const RegisterRequestDto({
    required this.username,
    required this.email,
    required this.password,
    this.captchaCode,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (captchaCode != null) 'captchaCode': captchaCode,
      };
}

/// B站相关 DTO
class BilibiliQRCodeDto {
  final String qrcodeKey;
  final String qrcodeUrl;
  final DateTime expiresAt;

  BilibiliQRCodeDto.fromJson(Map<String, dynamic> json)
      : qrcodeKey = json['qrcode_key'] as String? ?? json['qrcodeKey'] as String,
        qrcodeUrl = json['qr_url'] as String? ?? json['qrcode_url'] as String? ?? json['qrCodeUrl'] as String,
        expiresAt = json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : json['expiresAt'] != null
                ? DateTime.parse(json['expiresAt'] as String)
                : json['expires_in'] != null
                    ? DateTime.now().add(Duration(seconds: (json['expires_in'] as num).toInt()))
                    : DateTime.now().add(const Duration(minutes: 3));
}

class BilibiliQRStatusDto {
  final String status; // pending, scanned, success, expired
  final Map<String, dynamic>? userInfo;

  BilibiliQRStatusDto.fromJson(Map<String, dynamic> json)
      : status = json['status'] as String,
        userInfo = json['user_info'] as Map<String, dynamic>? ?? json['userInfo'] as Map<String, dynamic>?;
}

class BilibiliVideoDto {
  final String bvid;
  final String title;
  final String? cover;
  final int? duration;
  final Map<String, dynamic>? owner;
  final int? cid;

  BilibiliVideoDto.fromJson(Map<String, dynamic> json)
      : bvid = json['bvid'] as String,
        title = json['title'] as String,
        cover = json['cover'] as String? ?? json['pic'] as String?,
        duration = json['duration'] as int?,
        owner = json['owner'] as Map<String, dynamic>?,
        cid = json['cid'] as int?;
}

class BilibiliAudioDto {
  final String baseUrl;
  final String? url;
  final String? quality;
  final String? codec;
  final int? size;
  final String contentType;
  final int duration;
  final bool seekable;

  BilibiliAudioDto.fromJson(Map<String, dynamic> json)
      : baseUrl = json['base_url'] as String? ?? json['baseUrl'] as String? ?? json['url'] as String,
        url = json['url'] as String?,
        quality = json['quality'] as String?,
        codec = json['codec'] as String?,
        size = json['size'] as int?,
        contentType = json['content_type'] as String? ?? json['contentType'] as String? ?? 'audio/mp4',
        duration = json['duration'] as int? ?? 0,
        seekable = json['seekable'] as bool? ?? true;
}

class BilibiliSearchResultDto {
  final String bvid;
  final String title;
  final String? cover;
  final String? duration;
  final String author;

  BilibiliSearchResultDto.fromJson(Map<String, dynamic> json)
      : bvid = json['bvid'] as String,
        title = json['title'] as String,
        cover = json['cover'] as String?,
        duration = json['duration'] as String?,
        author = json['author'] as String? ?? '未知';
}

/// 歌单相关 DTO
class PlaylistDto {
  final int id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int itemCount;
  final DateTime? createdAt;

  PlaylistDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String,
        description = json['description'] as String?,
        coverUrl = json['cover_url'] as String? ?? json['coverUrl'] as String?,
        itemCount = json['item_count'] as int? ?? json['itemCount'] as int? ?? 0,
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : null;
}

class CreatePlaylistRequestDto {
  final String name;
  final String? description;

  const CreatePlaylistRequestDto({required this.name, this.description});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
      };
}

/// 播放历史相关 DTO
class PlayHistoryDto {
  final int id;
  final String bvid;
  final String? title;
  final String? artist;
  final String? coverUrl;
  final int duration;
  final int progress;
  final int playCount;
  final DateTime lastPlayedAt;

  PlayHistoryDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        bvid = json['bvid'] as String,
        title = json['title'] as String?,
        artist = json['artist'] as String?,
        coverUrl = json['cover_url'] as String? ?? json['coverUrl'] as String?,
        duration = json['duration'] as int? ?? 0,
        progress = json['progress'] as int? ?? 0,
        playCount = json['play_count'] as int? ?? json['playCount'] as int? ?? 1,
        lastPlayedAt = DateTime.parse(json['last_played_at'] as String? ?? json['lastPlayedAt'] as String? ?? DateTime.now().toIso8601String());
}
