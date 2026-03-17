import 'dart:convert';

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

/// API 异常
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
  final String token;
  final String? refreshToken;
  final int userId;
  final String username;
  final String? email;
  final bool bilibiliBound;

  LoginResponseDto.fromJson(Map<String, dynamic> json)
      : token = json['token'] as String,
        refreshToken = json['refreshToken'] as String?,
        userId = json['userId'] as int? ?? _extractUserIdFromToken(json['token'] as String),
        username = json['username'] as String,
        email = json['email'] as String?,
        bilibiliBound = json['bilibiliBound'] as bool? ?? false;

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
      return json['userId'] as int? ?? 0;
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
      : qrcodeKey = json['qrcodeKey'] as String,
        qrcodeUrl = json['qrCodeUrl'] as String,
        expiresAt = json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now().add(const Duration(minutes: 3));
}

class BilibiliQRStatusDto {
  final String status; // pending, scanned, success, expired
  final Map<String, dynamic>? userInfo;

  BilibiliQRStatusDto.fromJson(Map<String, dynamic> json)
      : status = json['status'] as String,
        userInfo = json['userInfo'] as Map<String, dynamic>?;
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
        cover = json['cover'] as String?,
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
      : baseUrl = json['baseUrl'] as String? ?? json['url'] as String,
        url = json['url'] as String?,
        quality = json['quality'] as String?,
        codec = json['codec'] as String?,
        size = json['size'] as int?,
        contentType = json['content_type'] as String? ?? 'audio/mp4',
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

/// 网易云相关 DTO
class NeteaseQRCodeDto {
  final String qrimg;
  final String qrurl;
  final String key;

  NeteaseQRCodeDto.fromJson(Map<String, dynamic> json)
      : qrimg = json['qrimg'] as String,
        qrurl = json['qrurl'] as String,
        key = json['key'] as String;
}

class NeteaseQRStatusDto {
  final String status;
  final Map<String, dynamic>? userInfo;
  final String? message;

  NeteaseQRStatusDto.fromJson(Map<String, dynamic> json)
      : status = json['status'] as String,
        userInfo = json['userInfo'] as Map<String, dynamic>?,
        message = json['message'] as String?;
}

class NeteasePlaylistDto {
  final String id;
  final String name;
  final String? coverUrl;
  final int trackCount;
  final String? description;

  NeteasePlaylistDto.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString(),
        name = json['name'] as String,
        coverUrl = json['coverImgUrl'] as String? ??
            json['picUrl'] as String? ??
            json['cover'] as String?,
        trackCount = json['trackCount'] as int? ?? 0,
        description = json['description'] as String?;
}

class NeteaseSongDto {
  final String id;
  final String name;
  final List<NeteaseArtistDto> artists;
  final String? albumName;
  final String? albumPic;
  final int? duration;

  NeteaseSongDto.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString(),
        name = json['name'] as String,
        artists = (json['artists'] as List<dynamic>? ?? [])
            .map((e) => NeteaseArtistDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        albumName = json['album']?['name'] as String?,
        albumPic = json['album']?['picUrl'] as String?,
        duration = json['duration'] as int?;
}

class NeteaseArtistDto {
  final String id;
  final String name;

  NeteaseArtistDto.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString(),
        name = json['name'] as String;
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
        coverUrl = json['coverUrl'] as String? ?? json['cover_url'] as String?,
        itemCount = json['itemCount'] as int? ?? 0,
        createdAt = json['createdAt'] != null
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
