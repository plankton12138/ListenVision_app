# Backend-Free Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete Python backend, adapt Flutter frontend to call B站 APIs directly with all data in local SQLite, no user account system.

**Architecture:** Flutter app calls B站 REST APIs directly via new `BilibiliApiService` + `BilibiliAuthService`. All data stored in local SQLite (existing schema minus sync fields). B站 QR login retained with cookies in `flutter_secure_storage`. `flutter_ffmpeg` added for audio format conversion. All auth/sync/netease code removed.

**Tech Stack:** Flutter 3.38.5, Dart 3.10.4, sqflite, flutter_secure_storage, flutter_ffmpeg, dio

---

## Task 1: Create BilibiliApiService — Direct B站 REST API Client

**Files:**
- Create: `frontend_flutter/lib/services/bilibili_api_service.dart`
- Create: `frontend_flutter/lib/services/bilibili_headers.dart`

**Purpose:** Single service that calls all B站 REST APIs directly, replacing the backend proxy layer and all three API client classes (ApiClient, BackendApiClient, BilibiliApiClient).

- [ ] **Step 1: Create B站 HTTP headers constant**

Create `frontend_flutter/lib/services/bilibili_headers.dart`:

```dart
/// B站 API 请求必须携带的 HTTP 头，绕过防盗链检测。
const Map<String, String> bilibiliHeaders = {
  'Referer': 'https://www.bilibili.com/',
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

/// 补全 protocol-less URL（以 // 开头的 URL 加上 https:）。
String normalizeBilibiliUrl(String url) {
  if (url.startsWith('//')) {
    return 'https:$url';
  }
  return url;
}

/// 解析 B站时长字符串 "mm:ss" 或 "hh:mm:ss" 为秒数。
int parseBilibiliDuration(String? durationStr) {
  if (durationStr == null || durationStr.isEmpty) return 0;
  try {
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } else if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    }
    return 0;
  } catch (_) {
    return 0;
  }
}
```

- [ ] **Step 2: Create BilibiliApiService class skeleton**

Create `frontend_flutter/lib/services/bilibili_api_service.dart`:

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/app_logger.dart';
import '../models/audio.dart';
import '../models/subtitle.dart';
import '../models/recommendation.dart';
import 'bilibili_headers.dart';

/// B站 REST API 直连服务。
/// 所有方法直接调用 B站公开或需登录 API，不经过任何后端代理。
class BilibiliApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  BilibiliApiService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _baseUrl = 'https://api.bilibili.com';
  static const _passportUrl = 'https://passport.bilibili.com';

  // ---- cookie 管理 ----

  /// 从本地安全存储读取 B站 登录态。
  Future<Map<String, String>?> getStoredCookies() async {
    final sessdata = await _secureStorage.read(key: 'bilibili_sessdata');
    final biliJct = await _secureStorage.read(key: 'bilibili_jct');
    final dedeuserid = await _secureStorage.read(key: 'bilibili_dedeuserid');
    if (sessdata == null || biliJct == null || dedeuserid == null) return null;
    return {
      'sessdata': sessdata,
      'bili_jct': biliJct,
      'dedeuserid': dedeuserid,
    };
  }

  /// 将 cookie map 转为 Cookie 请求头字符串。
  String _buildCookieHeader(Map<String, String> cookies) {
    final parts = <String>[];
    if (cookies['sessdata'] != null && cookies['sessdata']!.isNotEmpty) {
      parts.add('SESSDATA=${cookies['sessdata']}');
    }
    if (cookies['bili_jct'] != null && cookies['bili_jct']!.isNotEmpty) {
      parts.add('bili_jct=${cookies['bili_jct']}');
    }
    if (cookies['dedeuserid'] != null && cookies['dedeuserid']!.isNotEmpty) {
      parts.add('DedeUserID=${cookies['dedeuserid']}');
    }
    return parts.join('; ');
  }

  /// 构建带 B站 headers 和可选 cookie 的请求头。
  Map<String, String> _buildHeaders({Map<String, String>? cookies}) {
    final headers = Map<String, String>.from(bilibiliHeaders);
    if (cookies != null) {
      headers['Cookie'] = _buildCookieHeader(cookies);
    }
    return headers;
  }

  // ---- 视频信息 ----

  /// 获取视频信息。
  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/view',
      queryParameters: {'bvid': bvid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    return data;
  }

  // ---- 音频流 ----

  /// 获取 DASH 音频流列表（按码率降序）。
  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    Map<String, String>? cookies,
  }) async {
    // 先获取 cid
    final videoInfo = await getVideoInfo(bvid);
    final cid = videoInfo['cid'];
    if (cid == null) throw Exception('无法获取 cid');

    // 调用 playurl API 获取 DASH 流
    final response = await _dio.get(
      '$_baseUrl/x/player/wbi/playurl',
      queryParameters: {
        'bvid': bvid,
        'cid': cid,
        'fnval': 16,
        'fnver': 0,
        'fourk': 1,
      },
      options: Options(headers: _buildHeaders(cookies: cookies)),
    );
    final data = _extractData(response.data);
    final dashAudio = data['dash']?['audio'] as List<dynamic>? ?? [];

    final streams = dashAudio.map((audio) {
      return AudioStreamInfo(
        url: normalizeBilibiliUrl(
          audio['baseUrl'] ?? audio['base_url'] ?? '',
        ),
        qualityId: audio['id'] ?? 0,
        size: audio['size'] ?? 0,
        codecs: audio['codecs'] ?? '',
      );
    }).toList();

    return AudioStreamsData(
      bvid: bvid,
      cid: cid ?? 0,
      title: videoInfo['title'] ?? '',
      streams: streams,
    );
  }

  // ---- 字幕 ----

  /// 获取字幕数据。返回字幕列表或 needLogin=true。
  Future<SubtitleResponse> getSubtitles(
    String bvid, {
    Map<String, String>? cookies,
  }) async {
    try {
      final videoInfo = await getVideoInfo(bvid);
      final cid = videoInfo['cid'];
      if (cid == null) return SubtitleResponse(bvid: bvid, needLogin: false, subtitles: []);

      // 获取字幕元数据
      final playerResponse = await _dio.get(
        '$_baseUrl/x/player/v2',
        queryParameters: {'bvid': bvid, 'cid': cid},
        options: Options(headers: _buildHeaders(cookies: cookies)),
      );
      final playerData = _extractData(playerResponse.data);
      final subtitleMeta = playerData['subtitle']?['subtitles'] as List<dynamic>? ?? [];

      final subtitles = <SubtitleInfo>[];
      for (final meta in subtitleMeta) {
        final url = normalizeBilibiliUrl(meta['subtitle_url'] ?? '');
        if (url.isEmpty) continue;

        // 获取字幕 JSON
        final subResponse = await _dio.get(
          url,
          options: Options(headers: bilibiliHeaders),
        );
        final body = subResponse.data['body'] as List<dynamic>? ?? [];
        final lines = body.map((line) {
          return SubtitleLine(
            from: (line['from'] as num?)?.toDouble() ?? 0.0,
            to: (line['to'] as num?)?.toDouble() ?? 0.0,
            content: line['content'] ?? '',
          );
        }).toList();

        subtitles.add(SubtitleInfo(
          lan: meta['lan'] ?? '',
          lanDoc: meta['lan_doc'] ?? '',
          lines: lines,
        ));
      }

      return SubtitleResponse(
        bvid: bvid,
        cid: cid,
        needLogin: false,
        subtitles: subtitles,
      );
    } catch (e) {
      AppLogger.warn('BilibiliApiService', '获取字幕失败 (可能需要登录): $e');
      return SubtitleResponse(bvid: bvid, needLogin: true, subtitles: []);
    }
  }

  // ---- 搜索 ----

  /// 搜索 B站视频。
  Future<BilibiliSearchResponse> search({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/wbi/search/type',
      queryParameters: {
        'search_type': 'video',
        'keyword': keyword,
        'page': page,
        'page_size': pageSize,
      },
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final result = data['result'] as List<dynamic>? ?? [];

    final videos = result.where((item) {
      return item['type'] == 'video' && item['bvid'] != null;
    }).map((item) {
      return BilibiliSearchItem(
        bvid: item['bvid'] ?? '',
        title: _cleanHtmlTags(item['title'] ?? ''),
        author: item['author'] ?? '',
        cover: normalizeBilibiliUrl(item['pic'] ?? ''),
        duration: parseBilibiliDuration(item['duration']),
        playCount: item['play'] ?? 0,
        danmakuCount: item['video_review'] ?? 0,
      );
    }).toList();

    return BilibiliSearchResponse(
      videos: videos,
      total: data['numResults'] ?? 0,
      page: page,
      pageSize: pageSize,
    );
  }

  /// 搜索建议。
  Future<List<String>> getSearchSuggestions(String keyword) async {
    final response = await _dio.get(
      'https://s.search.bilibili.com/main/suggest',
      queryParameters: {'term': keyword},
      options: Options(headers: bilibiliHeaders),
    );
    final data = response.data;
    if (data is Map && data['result'] != null) {
      final tags = data['result']['tag'] as List<dynamic>?;
      if (tags != null) {
        return tags.map((t) => t['value']?.toString() ?? '').toList();
      }
    }
    return [];
  }

  // ---- 推荐与排行 ----

  /// 获取首页推荐。
  Future<List<RecommendationItem>> getRecommendations({int page = 1}) async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/popular',
      queryParameters: {'ps': 50, 'pn': page},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((item) => _parseRecommendationItem(item)).toList();
  }

  /// 获取排行榜。
  Future<List<RecommendationItem>> getRank({String type = 'music'}) async {
    final typeMap = {
      'music': 1, 'hot': 0, 'dance': 20, 'game': 4,
      'knowledge': 36, 'technology': 188, 'life': 160,
    };
    final rid = typeMap[type] ?? 1;
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/ranking/v2',
      queryParameters: {'rid': rid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((item) => _parseRecommendationItem(item)).toList();
  }

  /// 获取分区列表。
  Future<List<Map<String, dynamic>>> getZones() async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/archive/zone',
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final zones = <Map<String, dynamic>>[];
    for (final category in data as List<dynamic>? ?? []) {
      final tid = category['tid'];
      final name = category['name'];
      for (final subCat in category['list'] ?? []) {
        zones.add({
          'tid': subCat['tid'] ?? tid,
          'name': subCat['name'] ?? name,
          'parent_name': name,
        });
      }
    }
    return zones;
  }

  /// 按分区获取视频。
  Future<List<RecommendationItem>> getByCategory(
    int tid, {
    bool newest = false,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/newlist',
      queryParameters: {'rid': tid, 'type': newest ? 1 : 0},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final archives = data['archives'] as List<dynamic>? ?? [];
    return archives.map((item) => _parseRecommendationItem(item)).toList();
  }

  /// 获取 UP 主信息。
  Future<Map<String, dynamic>> getUploaderInfo(int mid) async {
    final response = await _dio.get(
      '$_baseUrl/x/space/wbi/acc/info',
      queryParameters: {'mid': mid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    return data;
  }

  /// 刷新 B站 cookie（延长登录有效期）。
  Future<Map<String, String>> refreshCookie(Map<String, String> cookies) async {
    final response = await _dio.post(
      '$_passportUrl/x/passport-login/web/cookie/refresh',
      options: Options(headers: _buildHeaders(cookies: cookies)),
    );
    final setCookie = response.headers['set-cookie'] as List<String>?;
    return _parseCookies(setCookie ?? [], cookies);
  }

  // ---- 私有辅助 ----

  /// 提取 B站 API 响应中的 data 字段，检查 code。
  Map<String, dynamic> _extractData(dynamic responseBody) {
    if (responseBody is! Map) {
      throw Exception('B站 API 响应格式异常');
    }
    final code = responseBody['code'];
    if (code != 0) {
      final msg = responseBody['message'] ?? '未知错误';
      throw BilibiliApiException(code ?? -1, msg.toString());
    }
    return responseBody['data'] as Map<String, dynamic>? ?? {};
  }

  /// 清理 HTML 标签。
  String _cleanHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 解析 recommendation item。
  RecommendationItem _parseRecommendationItem(Map<String, dynamic> item) {
    return RecommendationItem(
      bvid: item['bvid'] ?? '',
      title: _cleanHtmlTags(item['title'] ?? ''),
      author: item['owner']?['name'] ?? item['author'] ?? '',
      cover: normalizeBilibiliUrl(item['pic'] ?? item['cover'] ?? ''),
      duration: parseBilibiliDuration(item['duration']),
      playCount: item['stat']?['view'] ?? item['play'] ?? 0,
      danmakuCount: item['stat']?['danmaku'] ?? item['video_review'] ?? 0,
    );
  }

  /// 从 set-cookie 响应头解析 cookie 值。
  Map<String, String> _parseCookies(
    List<String> setCookieHeaders,
    Map<String, String> fallback,
  ) {
    final result = Map<String, String>.from(fallback);
    for (final header in setCookieHeaders) {
      for (final part in header.split(';')) {
        final trimmed = part.trim();
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx == -1) continue;
        final key = trimmed.substring(0, eqIdx);
        final value = trimmed.substring(eqIdx + 1);
        if (key == 'SESSDATA') result['sessdata'] = value;
        if (key == 'bili_jct') result['bili_jct'] = value;
        if (key == 'DedeUserID') result['dedeuserid'] = value;
      }
    }
    return result;
  }
}

/// B站 API 异常。
class BilibiliApiException implements Exception {
  final int code;
  final String message;
  BilibiliApiException(this.code, this.message);

  String get userMessage {
    return switch (code) {
      -101 => 'B站账号未登录或已过期',
      -403 => '访问被拒绝',
      -404 => '资源不存在',
      -400 => '请求参数错误',
      _ => 'B站 API 错误 ($code): $message',
    };
  }

  @override
  String toString() => 'BilibiliApiException($code, "$message")';
}
```

- [ ] **Step 3: Run flutter analyze to verify compilation**

```bash
cd frontend_flutter && flutter analyze
```

Expected: May have errors about missing model classes (defined later). Fix import issues.

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/services/bilibili_headers.dart frontend_flutter/lib/services/bilibili_api_service.dart
git commit -m "feat: add BilibiliApiService for direct B站 API access

Replace backend proxy layer with direct B站 REST API calls from Flutter."
```

---

## Task 2: Create BilibiliAuthService — QR Code Login Flow

**Files:**
- Create: `frontend_flutter/lib/services/bilibili_auth_service.dart`

**Purpose:** Port the QR code login flow from Python `bilibili_auth_service.py` to Dart. This service is only for B站 binding — there is no user account system.

- [ ] **Step 1: Create BilibiliAuthService**

Create `frontend_flutter/lib/services/bilibili_auth_service.dart`:

```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/app_logger.dart';
import 'bilibili_headers.dart';

/// B站 登录状态。
enum BilibiliQRStatus { pending, scanned, expired, success, error }

/// B站 账号信息。
class BilibiliAccount {
  final String sessdata;
  final String biliJct;
  final String dedeuserid;
  final String? username;
  final String? avatarUrl;

  BilibiliAccount({
    required this.sessdata,
    required this.biliJct,
    required this.dedeuserid,
    this.username,
    this.avatarUrl,
  });
}

/// B站 QR 码登录服务。
/// 直接调用 B站 passport API，cookie 存储在 flutter_secure_storage。
class BilibiliAuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  BilibiliAuthService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _passportUrl = 'https://passport.bilibili.com';

  /// 生成 QR 码。返回 qrcode_key 和 QR 图片 URL。
  Future<Map<String, String>> generateQRCode() async {
    final response = await _dio.get(
      '$_passportUrl/x/passport-login/web/qrcode/generate',
      options: Options(headers: bilibiliHeaders),
    );
    final data = response.data['data'];
    if (data == null) throw Exception('生成QR码失败');
    return {
      'qrcode_key': data['qrcode_key']?.toString() ?? '',
      'qr_url': data['url']?.toString() ?? '',
    };
  }

  /// 轮询 QR 码状态。
  /// 返回 (状态, 账号信息?) — 仅在 success 时有账号信息。
  Future<(BilibiliQRStatus, BilibiliAccount?)> checkQRCode(
    String qrcodeKey,
  ) async {
    try {
      final response = await _dio.get(
        '$_passportUrl/x/passport-login/web/qrcode/poll',
        queryParameters: {'qrcode_key': qrcodeKey},
        options: Options(headers: bilibiliHeaders),
      );
      final data = response.data['data'];
      final code = data?['code'] ?? -1;

      switch (code) {
        case 0:
          // 登录成功，从响应头提取 cookie
          final cookies = _extractCookies(response);
          if (cookies['sessdata'] == null) {
            return (BilibiliQRStatus.error, null);
          }
          final account = BilibiliAccount(
            sessdata: cookies['sessdata']!,
            biliJct: cookies['bili_jct'] ?? '',
            dedeuserid: cookies['dedeuserid'] ?? '',
          );
          // 获取用户名和头像
          final userInfo = await _fetchUserInfo(cookies);
          final fullAccount = BilibiliAccount(
            sessdata: account.sessdata,
            biliJct: account.biliJct,
            dedeuserid: account.dedeuserid,
            username: userInfo['name'],
            avatarUrl: userInfo['face'],
          );
          // 保存到安全存储
          await _saveAccount(fullAccount);
          return (BilibiliQRStatus.success, fullAccount);

        case 86090:
          return (BilibiliQRStatus.scanned, null);

        case 86038:
          return (BilibiliQRStatus.expired, null);

        default:
          return (BilibiliQRStatus.pending, null);
      }
    } catch (e) {
      AppLogger.error('BilibiliAuthService', '检查QR码状态失败: $e');
      return (BilibiliQRStatus.error, null);
    }
  }

  /// 检查是否有已保存的 B站 账号。
  Future<BilibiliAccount?> getStoredAccount() async {
    final sessdata = await _secureStorage.read(key: 'bilibili_sessdata');
    if (sessdata == null || sessdata.isEmpty) return null;
    final biliJct = await _secureStorage.read(key: 'bilibili_jct') ?? '';
    final dedeuserid = await _secureStorage.read(key: 'bilibili_dedeuserid') ?? '';
    final username = await _secureStorage.read(key: 'bilibili_username');
    final avatarUrl = await _secureStorage.read(key: 'bilibili_avatar');
    return BilibiliAccount(
      sessdata: sessdata,
      biliJct: biliJct,
      dedeuserid: dedeuserid,
      username: username,
      avatarUrl: avatarUrl,
    );
  }

  /// 解绑（删除本地存储的 cookie）。
  Future<void> unbind() async {
    await _secureStorage.delete(key: 'bilibili_sessdata');
    await _secureStorage.delete(key: 'bilibili_jct');
    await _secureStorage.delete(key: 'bilibili_dedeuserid');
    await _secureStorage.delete(key: 'bilibili_username');
    await _secureStorage.delete(key: 'bilibili_avatar');
  }

  /// 是否已绑定 B站。
  Future<bool> isBound() async {
    final account = await getStoredAccount();
    return account != null;
  }

  /// 获取已存储的 cookie map（供其他 Service 使用）。
  Future<Map<String, String>?> getStoredCookies() async {
    final account = await getStoredAccount();
    if (account == null) return null;
    return {
      'sessdata': account.sessdata,
      'bili_jct': account.biliJct,
      'dedeuserid': account.dedeuserid,
    };
  }

  // ---- 私有 ----

  void _saveAccount(BilibiliAccount account) async {
    await _secureStorage.write(key: 'bilibili_sessdata', value: account.sessdata);
    await _secureStorage.write(key: 'bilibili_jct', value: account.biliJct);
    await _secureStorage.write(key: 'bilibili_dedeuserid', value: account.dedeuserid);
    if (account.username != null) {
      await _secureStorage.write(key: 'bilibili_username', value: account.username);
    }
    if (account.avatarUrl != null) {
      await _secureStorage.write(key: 'bilibili_avatar', value: account.avatarUrl);
    }
  }

  Map<String, String> _extractCookies(Response response) {
    final result = <String, String>{};
    final setCookie = response.headers['set-cookie'] as List<String>? ?? [];
    for (final header in setCookie) {
      for (final part in header.split(';')) {
        final trimmed = part.trim();
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx == -1) continue;
        final key = trimmed.substring(0, eqIdx);
        final value = trimmed.substring(eqIdx + 1);
        if (key == 'SESSDATA') result['sessdata'] = value;
        if (key == 'bili_jct') result['bili_jct'] = value;
        if (key == 'DedeUserID') result['dedeuserid'] = value;
      }
    }
    return result;
  }

  Future<Map<String, String>> _fetchUserInfo(Map<String, String> cookies) async {
    try {
      final cookieStr = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      final response = await _dio.get(
        'https://api.bilibili.com/x/web-interface/nav',
        options: Options(headers: {
          ...bilibiliHeaders,
          'Cookie': cookieStr,
        }),
      );
      final data = response.data['data'];
      return {
        'name': data?['uname']?.toString() ?? '',
        'face': data?['face']?.toString() ?? '',
      };
    } catch (_) {
      return {'name': '', 'face': ''};
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend_flutter/lib/services/bilibili_auth_service.dart
git commit -m "feat: add BilibiliAuthService for QR code login flow

Port QR login logic from Python backend to Dart. Cookies stored in
flutter_secure_storage instead of backend database."
```

---

## Task 3: Create FfmpegService — Audio Format Conversion

**Files:**
- Create: `frontend_flutter/lib/services/ffmpeg_service.dart`
- Modify: `frontend_flutter/pubspec.yaml` — add `flutter_ffmpeg` dependency

- [ ] **Step 1: Add flutter_ffmpeg dependency**

```bash
cd frontend_flutter
flutter pub add flutter_ffmpeg
```

- [ ] **Step 2: Create FfmpegService**

Create `frontend_flutter/lib/services/ffmpeg_service.dart`:

```dart
import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import '../core/utils/app_logger.dart';

/// 支持的输出音频格式。
enum AudioOutputFormat {
  m4a('m4a'),
  mp3('mp3'),
  aac('aac');

  final String extension;
  const AudioOutputFormat(this.extension);
}

/// 音频格式转换服务，封装 flutter_ffmpeg。
class FfmpegService {
  final FlutterFFmpeg _ffmpeg = FlutterFFmpeg();

  /// 音频格式转换。
  /// [inputPath] 源文件路径，[outputFormat] 目标格式。
  /// 返回转换后的文件路径。
  Future<String> convert({
    required String inputPath,
    required AudioOutputFormat outputFormat,
  }) async {
    final outputPath = _buildOutputPath(inputPath, outputFormat);
    if (await File(outputPath).exists()) {
      AppLogger.info('FfmpegService', '输出文件已存在，跳过转换: $outputPath');
      return outputPath;
    }

    // m4a → m4a 无需转换
    if (inputPath.endsWith('.m4a') && outputFormat == AudioOutputFormat.m4a) {
      return inputPath;
    }

    final arguments = _buildArguments(inputPath, outputPath, outputFormat);
    AppLogger.info('FfmpegService', '开始转换: $inputPath → $outputPath');

    final result = await _ffmpeg.executeWithArguments(arguments);
    if (result != 0) {
      throw FfmpegException('音频格式转换失败，返回码: $result');
    }

    AppLogger.info('FfmpegService', '转换完成: $outputPath');
    return outputPath;
  }

  /// 取消当前转换任务。
  Future<void> cancel() async {
    await _ffmpeg.cancel();
  }

  /// 检查 ffmpeg 是否可用。
  Future<bool> isAvailable() async {
    try {
      final version = await _ffmpeg.getFFmpegVersion();
      return version.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _ffmpeg.release();
  }

  // ---- 私有 ----

  String _buildOutputPath(String inputPath, AudioOutputFormat format) {
    final dir = Directory(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last;
    final nameWithoutExt =
        baseName.contains('.') ? baseName.substring(0, baseName.lastIndexOf('.')) : baseName;
    return '$dir$Platform.pathSeparator$nameWithoutExt.${format.extension}';
  }

  List<String> _buildArguments(
    String inputPath,
    String outputPath,
    AudioOutputFormat format,
  ) {
    final args = <String>['-i', inputPath, '-y'];

    switch (format) {
      case AudioOutputFormat.mp3:
        args.addAll(['-c:a', 'libmp3lame', '-b:a', '192k']);
        break;
      case AudioOutputFormat.aac:
        args.addAll(['-c:a', 'aac', '-b:a', '192k']);
        break;
      case AudioOutputFormat.m4a:
        args.addAll(['-c:a', 'copy']); // 不改编码，只换容器
        break;
    }

    args.add(outputPath);
    return args;
  }
}

class FfmpegException implements Exception {
  final String message;
  FfmpegException(this.message);

  @override
  String toString() => 'FfmpegException: $message';
}
```

- [ ] **Step 3: Wire FfmpegService into download pipeline**

In `frontend_flutter/lib/services/bilibili_downloader.dart`, after downloading the m4s file and renaming to m4a, add an optional conversion step:

In the `download()` method (after line 135 where metadata is written), add:
```dart
// 格式转换（如果请求非 m4a 格式）
if (format != null && format != AudioOutputFormat.m4a) {
  final ffmpeg = FfmpegService();
  try {
    final convertedPath = await ffmpeg.convert(
      inputPath: audioPath,
      outputFormat: format,
    );
    // 删除原始 m4a 文件
    await File(audioPath).delete();
    audioPath = convertedPath;
  } finally {
    ffmpeg.dispose();
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/services/ffmpeg_service.dart frontend_flutter/pubspec.yaml frontend_flutter/lib/services/bilibili_downloader.dart
git commit -m "feat: add FfmpegService for audio format conversion

Encapsulate flutter_ffmpeg for m4a→mp3/aac conversion. Wired into
BilibiliDownloader as optional post-download step."
```

---

## Task 4: Delete Netease Files

**Files:**
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/netease_auth_viewmodel.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/netease_auth_viewmodel.freezed.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/netease_auth_viewmodel.g.dart`
- Delete: `frontend_flutter/lib/presentation/views/discovery/netease_playlist_detail_page.dart`
- Delete: `frontend_flutter/lib/presentation/views/discovery/netease_playlist_detail_page.freezed.dart`
- Delete: `frontend_flutter/lib/presentation/views/discovery/netease_playlist_detail_page.g.dart`
- Delete: `frontend_flutter/lib/presentation/widgets/netease_cellphone_login_dialog.dart`
- Modify: `frontend_flutter/lib/presentation/providers.dart`
- Modify: `frontend_flutter/lib/core/network/api_client.dart`
- Modify: `frontend_flutter/lib/core/network/endpoints.dart`
- Modify: `frontend_flutter/lib/core/constants/api_constants.dart`
- Modify: `frontend_flutter/lib/data/api/backend_api_client.dart`

- [ ] **Step 1: Delete all 7 netease files**

```bash
cd frontend_flutter
rm lib/presentation/viewmodels/auth/netease_auth_viewmodel.dart
rm lib/presentation/viewmodels/auth/netease_auth_viewmodel.freezed.dart
rm lib/presentation/viewmodels/auth/netease_auth_viewmodel.g.dart
rm lib/presentation/views/discovery/netease_playlist_detail_page.dart
rm lib/presentation/views/discovery/netease_playlist_detail_page.freezed.dart
rm lib/presentation/views/discovery/netease_playlist_detail_page.g.dart
rm lib/presentation/widgets/netease_cellphone_login_dialog.dart
```

- [ ] **Step 2: Remove Netease exports from providers.dart**

Edit `frontend_flutter/lib/presentation/providers.dart` — remove the Netease import:
```dart
// DELETE this line:
export 'viewmodels/auth/netease_auth_viewmodel.dart';
```

- [ ] **Step 3: Remove Netease methods from ApiClient**

Edit `frontend_flutter/lib/core/network/api_client.dart` — delete methods at lines 241-391 (all methods from `getNeteaseQRCode` through `getNeteaseLyric`).

- [ ] **Step 4: Remove Netease endpoints from Endpoints**

Edit `frontend_flutter/lib/core/network/endpoints.dart` — delete lines 57-73 (the Netease section).

- [ ] **Step 5: Remove Netease constants from ApiConstants**

Edit `frontend_flutter/lib/core/constants/api_constants.dart` — delete `NeteaseEndpoints` class (lines 122-137).

- [ ] **Step 6: Remove Netease methods from BackendApiClient**

Edit `frontend_flutter/lib/data/api/backend_api_client.dart` — delete lines 693-788 (all Netease methods).

- [ ] **Step 7: Run flutter analyze to verify no broken imports**

```bash
cd frontend_flutter && flutter analyze
```

Expected: No Netease-related import errors. Other errors from pending work are expected.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: remove all Netease integration code

Backend never implemented Netease — only stubs existed. Removing all
Netease API client methods, viewmodels, pages, and constants."
```

---

## Task 5: Delete Auth System Files

**Files:**
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/auth_viewmodel.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/auth_viewmodel.freezed.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/auth_viewmodel.g.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/platform_auth_viewmodel.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/platform_auth_viewmodel.freezed.dart`
- Delete: `frontend_flutter/lib/presentation/viewmodels/auth/platform_auth_viewmodel.g.dart`
- Modify: `frontend_flutter/lib/presentation/providers.dart`
- Modify: `frontend_flutter/lib/data/repositories/auth_repository.dart`
- Modify: `frontend_flutter/lib/core/network/dio_client.dart`
- Modify: `frontend_flutter/lib/core/network/api_client.dart`
- Modify: `frontend_flutter/lib/core/network/endpoints.dart`
- Modify: `frontend_flutter/lib/core/constants/api_constants.dart`
- Modify: `frontend_flutter/lib/data/api/backend_api_client.dart`

- [ ] **Step 1: Delete 6 auth viewmodel files**

```bash
cd frontend_flutter
rm lib/presentation/viewmodels/auth/auth_viewmodel.dart
rm lib/presentation/viewmodels/auth/auth_viewmodel.freezed.dart
rm lib/presentation/viewmodels/auth/auth_viewmodel.g.dart
rm lib/presentation/viewmodels/auth/platform_auth_viewmodel.dart
rm lib/presentation/viewmodels/auth/platform_auth_viewmodel.freezed.dart
rm lib/presentation/viewmodels/auth/platform_auth_viewmodel.g.dart
```

- [ ] **Step 2: Remove auth exports from providers.dart**

Edit `frontend_flutter/lib/presentation/providers.dart` — remove:
```dart
// DELETE:
export 'viewmodels/auth/auth_viewmodel.dart';
export 'viewmodels/auth/platform_auth_viewmodel.dart';
```

- [ ] **Step 3: Delete auth methods from ApiClient**

Edit `frontend_flutter/lib/core/network/api_client.dart` — delete methods: `login`, `register`, `getCurrentUser` (lines 46-87). Also delete B站 auth methods that now go through `BilibiliAuthService`: `getBilibiliQRCode`, `checkBilibiliQRStatus`, `getBilibiliBindStatus`, `unbindBilibili` (lines 89-130).

- [ ] **Step 4: Delete auth + sync methods from ApiClient**

In `frontend_flutter/lib/core/network/api_client.dart` — also delete all sync methods: `getCloudFavorites`, `getCloudPlaylists`, `getCloudHistory`, `getCloudChanges`, `getSyncStatus` (lines 613-672).

- [ ] **Step 5: Delete auth endpoints from Endpoints**

Edit `frontend_flutter/lib/core/network/endpoints.dart` — delete auth section (lines 9-17) and sync section (lines 103-107).

- [ ] **Step 6: Delete auth constants from ApiConstants**

Edit `frontend_flutter/lib/core/constants/api_constants.dart` — delete `AuthEndpoints` class (lines 46-58).

- [ ] **Step 7: Simplify BackendApiClient — delete auth methods**

Edit `frontend_flutter/lib/data/api/backend_api_client.dart` — delete methods `login`, `register`, `verifyEmail`, `logout`, `deleteAccount`, `getCurrentUser`, `sendVerificationCode`, `resetPassword` (lines 72-195). Also delete all sync methods (lines 809-866). Also delete Netease methods (may have been deleted in Task 3 already).

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: delete user auth system — registration, login, JWT tokens

App is now fully local with no user accounts. B站 QR login handled by
BilibiliAuthService directly."
```

---

## Task 6: Database Schema V9 Migration

**Files:**
- Modify: `frontend_flutter/lib/data/database/app_database.dart`

- [ ] **Step 1: Update _createDB — remove synced_at from tracks**

In `frontend_flutter/lib/data/database/app_database.dart`, in `_createDB()` method:
- Remove `synced_at $textNullableType` from the `tracks` CREATE TABLE (line 87)
- Remove `synced_at TEXT` from the `playlists` CREATE TABLE (line 424)
- Remove `server_id TEXT` from the `playlists` CREATE TABLE (line 412)
- Bump version to 9 (line 34: `version: 9`)

- [ ] **Step 2: Add V9 migration method**

Add a new method and register it in `_onUpgrade`:

```dart
// In _onUpgrade, after the V8 block:
if (oldVersion < 9) {
  await _upgradeToV9(db);
}

// New method:
Future<void> _upgradeToV9(Database db) async {
  AppLogger.info('AppDatabase', '升级数据库到 V9：删除服务端同步字段');

  // 1. 重建 tracks 表（移除 synced_at）
  await db.execute('''
    CREATE TABLE tracks_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source_id TEXT NOT NULL UNIQUE,
      source_type TEXT NOT NULL,
      title TEXT NOT NULL,
      artist TEXT,
      album TEXT,
      duration INTEGER,
      cover_url TEXT,
      cover_blob BLOB,
      bvid TEXT,
      uploader TEXT,
      uploader_mid TEXT,
      play_count INTEGER,
      local_path TEXT,
      is_downloaded INTEGER DEFAULT 0,
      is_favorite INTEGER DEFAULT 0,
      local_play_count INTEGER DEFAULT 0,
      last_played_at TEXT,
      added_at TEXT,
      updated_at TEXT,
      created_at TEXT
    )
  ''');

  await db.execute('''
    INSERT INTO tracks_new
    SELECT id, source_id, source_type, title, artist, album, duration,
           cover_url, cover_blob, bvid, uploader, uploader_mid, play_count,
           local_path, is_downloaded, is_favorite, local_play_count,
           last_played_at, added_at, updated_at, created_at
    FROM tracks
  ''');

  await db.execute('DROP TABLE tracks');
  await db.execute('ALTER TABLE tracks_new RENAME TO tracks');

  // 重建索引
  await db.execute('CREATE INDEX idx_tracks_source_id ON tracks(source_id)');
  await db.execute('CREATE INDEX idx_tracks_source_type ON tracks(source_type)');
  await db.execute('CREATE INDEX idx_tracks_is_downloaded ON tracks(is_downloaded)');
  await db.execute('CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite)');

  // 2. 重建 playlists 表（移除 server_id 和 synced_at）
  await db.execute('''
    CREATE TABLE playlists_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      cover_url TEXT,
      cover_blob BLOB,
      type TEXT DEFAULT 'user',
      system_type TEXT,
      is_public INTEGER DEFAULT 0,
      play_count INTEGER DEFAULT 0,
      item_count INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''');

  await db.execute('''
    INSERT INTO playlists_new
    SELECT id, name, description, cover_url, cover_blob, type, system_type,
           is_public, play_count, item_count, created_at, updated_at
    FROM playlists
  ''');

  await db.execute('DROP TABLE playlists');
  await db.execute('ALTER TABLE playlists_new RENAME TO playlists');

  // 重建索引
  await db.execute('CREATE INDEX idx_playlists_type ON playlists(type)');
  await db.execute('CREATE INDEX idx_playlists_system_type ON playlists(system_type)');

  AppLogger.info('AppDatabase', 'V9 迁移完成');
}
```

- [ ] **Step 3: Update insertOrUpdateTrack — remove synced_at reference**

In `insertOrUpdateTrack()` method (line 599), no changes needed since `synced_at` was never written in the INSERT. But verify the code doesn't reference it.

- [ ] **Step 4: Commit**

```bash
git add frontend_flutter/lib/data/database/app_database.dart
git commit -m "feat: V9 database migration — remove server sync fields

Drop synced_at from tracks, drop server_id and synced_at from playlists.
All data is now purely local."
```

---

## Task 7: Refactor Repositories — Remove Backend Calls

**Files:**
- Modify: `frontend_flutter/lib/data/repositories/auth_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/playlist_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/history_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/search_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/track_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/download_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/subtitle_repository.dart`

- [ ] **Step 1: Rewrite auth_repository.dart — B站 cookie state only**

Replace the entire file with a minimal version that only queries `BilibiliAuthService` for B站 binding status:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/bilibili_auth_service.dart';

class AuthRepository {
  final BilibiliAuthService _bilibiliAuth;

  AuthRepository({BilibiliAuthService? bilibiliAuth})
      : _bilibiliAuth = bilibiliAuth ?? BilibiliAuthService();

  Future<bool> isBilibiliBound() => _bilibiliAuth.isBound();
  Future<BilibiliAccount?> getBilibiliAccount() => _bilibiliAuth.getStoredAccount();
  Future<void> unbindBilibili() => _bilibiliAuth.unbind();
}
```

- [ ] **Step 2: Simplify playlist_repository.dart — delete backend methods**

Delete these methods and their bodies: `getUserPlaylists`, `getPlaylistDetail`, `getPlaylistItems`, `createPlaylist`, `updatePlaylist`, `deletePlaylist`, `addPlaylistItem`, `removePlaylistItem`, `getFavorites`, `toggleFavorite`, `isFavorite`, `saveNowPlaying`, `syncPlaylistsToLocal`.

Keep only local DAO methods: `getLocalPlaylists`, `getLocalUserPlaylists`, `getLocalSystemPlaylists`.

- [ ] **Step 3: Rewrite history_repository.dart — local SQLite only**

Replace with local-only implementation using `AppDatabase` directly (no backend calls):

```dart
import '../database/app_database.dart';

class PlayHistoryRepository {
  final AppDatabase _db;
  PlayHistoryRepository({AppDatabase? db})
      : _db = db ?? AppDatabase.instance;

  Future<List<Map<String, dynamic>>> getPlayHistory({int limit = 20}) =>
      _db.getRecentPlayHistory(limit: limit);

  Future<void> addPlayHistory(Map<String, dynamic> history) =>
      _db.insertPlayHistory(history);

  Future<void> clearAllHistory() => _db.clearPlayHistory();
}
```

Delete all `BackendApiClient` usage. Delete `deletePlayHistory` and `updatePlayHistory` if they can be done via local DB ops.

- [ ] **Step 4: Simplify search_repository.dart — local search + direct B站**

Replace `searchBilibili` to use `BilibiliApiService` instead of `BilibiliApiClient`. Replace `searchLocal` to use local SQLite directly instead of `BackendApiClient`. Keep `getSearchSuggestions` using `BilibiliApiService`.

- [ ] **Step 5: Simplify track_repository.dart — use BilibiliApiService**

Replace `_bilibiliApi` (BilibiliApiClient) with `_bilibiliService` (BilibiliApiService). Update `getTrackByBvid`, `search`, `downloadAudio` to call the new service.

- [ ] **Step 6: Simplify download_repository.dart — remove backend URLs**

Update `_downloadWithBackendService` to not go through SSE backend. Keep `_downloadWithBilibiliDownloader` (already uses direct B站 CDN). Remove `getProxyAudioUrl`, `getProxyImageUrl` — replace with direct URL construction. Update `getDownloadUrl` to use `BilibiliApiService`.

- [ ] **Step 7: Simplify subtitle_repository.dart — use BilibiliApiService**

Replace `_apiClient.getBilibiliSubtitle()` with `_bilibiliService.getSubtitles()`.

- [ ] **Step 8: Commit**

```bash
git add frontend_flutter/lib/data/repositories/
git commit -m "refactor: simplify repositories — remove backend API calls

All repositories now use local SQLite + direct BilibiliApiService calls
instead of going through backend proxy APIs."
```

---

## Task 8: Clean Up Network Layer and Constants

**Files:**
- Modify: `frontend_flutter/lib/core/network/dio_client.dart`
- Modify: `frontend_flutter/lib/core/network/api_client.dart`
- Modify: `frontend_flutter/lib/core/network/endpoints.dart`
- Modify: `frontend_flutter/lib/core/constants/api_constants.dart`
- Delete: `frontend_flutter/lib/data/api/backend_api_client.dart`
- Delete: `frontend_flutter/lib/data/api/bilibili_api_client.dart`

- [ ] **Step 1: Remove JWT token logic from DioClient**

Edit `frontend_flutter/lib/core/network/dio_client.dart`:
- Delete `_shouldAttemptTokenRefresh` method (line 102)
- Delete `_handleTokenRefresh` method (line 133)
- Delete `updateToken` method (line 206)
- Delete `currentToken` getter (line 218)
- Remove the 401 interceptor from `_createDio` (the onError handler that calls `_shouldAttemptTokenRefresh`)
- Keep the `_createDio`, get/post/put/delete, download, and error handling methods (they're still needed for local HTTP operations)

- [ ] **Step 2: Delete backend_api_client.dart and bilibili_api_client.dart**

```bash
cd frontend_flutter
rm lib/data/api/backend_api_client.dart
rm lib/data/api/bilibili_api_client.dart
```

- [ ] **Step 3: Remove remaining auth+netease+sync constants from api_constants.dart**

In `frontend_flutter/lib/core/constants/api_constants.dart`, delete:
- `HistoryEndpoints` class (never called locally — history is SQLite only)
- `SearchEndpoints` class (local search is SQLite, B站 search via BilibiliApiService)
- `RecommendationEndpoints` class (replaced by BilibiliApiService)
- `BilibiliEndpoints` class (replaced by BilibiliApiService)
- `AudioEndpoints` class (replaced by BilibiliApiService)
- `EndpointPathExtension` (no longer needed)
- `PlatformAudioFormat` class
- Only keep `ApiConstants` (base URL no longer needed but minimally keep the class) and `BilibiliConstants` (QR status codes)

- [ ] **Step 4: Clean up api_client.dart — remove all methods that call backend**

`ApiClient` (at `lib/core/network/api_client.dart`) should be emptied of all backend-only methods. Since all B站 calls now go through `BilibiliApiService`, and all data operations are local, this file may be removable entirely. Check if any code still imports it. If not, delete it.

- [ ] **Step 5: Run flutter analyze and fix all import errors**

```bash
cd frontend_flutter && flutter analyze 2>&1 | head -100
```

Fix any remaining import errors. Common issues:
- ViewModels importing deleted files
- Provider declarations referencing deleted types
- Wildcard exports in providers.dart

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: clean up network layer — remove JWT, delete legacy API clients

Deleting BackendApiClient, BilibiliApiClient, and all backend-oriented
endpoint constants. DioClient no longer manages JWT tokens."
```

---

## Task 9: Clean Up ViewModels, UI and Settings Page

**Files:**
- Modify: `frontend_flutter/lib/presentation/providers.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/discovery/explore_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/library/playlist_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/system/download_viewmodel.dart`
- All files in `lib/presentation/views/` that reference deleted providers

- [ ] **Step 1: Update providers.dart to export new providers**

Edit `frontend_flutter/lib/presentation/providers.dart`:
- Remove netease and auth exports (already done in Tasks 3-4)
- Add export for `BilibiliAuthService`:
```dart
export '../../services/bilibili_auth_service.dart';
```
- Keep existing exports for player, queue, metadata, playlist, history, search, explore, theme, download, subtitle

- [ ] **Step 2: Fix SearchViewModel**

Edit `frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart`:
- Remove `BackendApiClient` import and usage
- Replace B站 search calls with `BilibiliApiService` 
- Remove `searchBackendApiClient` provider

- [ ] **Step 3: Fix ExploreViewModel**

Edit `frontend_flutter/lib/presentation/viewmodels/discovery/explore_viewmodel.dart`:
- Remove `BackendApiClient` import and usage (the `NeteaseExploreViewModel` class if it still exists)
- Remove `exploreBackendApiClient` provider

- [ ] **Step 4: Simplify HistoryViewModel**

Edit `frontend_flutter/lib/presentation/viewmodels/library/history_viewmodel.dart`:
- If it calls backend API for history, replace with local `AppDatabase` queries
- History is already in local SQLite, so minimal changes expected

- [ ] **Step 5: Simplify PlaylistViewModel and PlaylistDetailViewModel**

Remove any backend API calls for playlist sync. Keep local DAO operations.

- [ ] **Step 6: Fix DownloadViewModel**

Remove any backend URL references. Downloads go through `BilibiliApiService` + direct CDN.

- [ ] **Step 7: Search for remaining broken references**

```bash
cd frontend_flutter
grep -rn "BackendApiClient\|backend_api_client" lib/presentation/ --include="*.dart" || echo "None found"
grep -rn "BilibiliApiClient\|bilibili_api_client" lib/presentation/ --include="*.dart" || echo "None found"
grep -rn "NeteaseAuth\|netease_auth" lib/ --include="*.dart" || echo "None found"
grep -rn "AuthViewModel\|auth_viewmodel" lib/ --include="*.dart" || echo "None found"
grep -rn "PlatformAuth\|platform_auth" lib/ --include="*.dart" || echo "None found"
```

Fix any remaining references.

- [ ] **Step 8: Add B站 QR login entry to settings page**

In `frontend_flutter/lib/presentation/views/system/settings_page.dart`:
- Find the account/auth section and replace it with a simplified B站 binding section
- Display B站 bind status (bound username / "未绑定")
- "绑定B站账号" button → triggers `BilibiliAuthService.generateQRCode()` → show QR image → poll status
- "解绑" button (if bound) → calls `BilibiliAuthService.unbind()`

Minimal implementation — just a `ListTile` in settings that shows status and navigates to a simple QR display dialog.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "refactor: update ViewModels to use local data and BilibiliApiService

All ViewModels now reference BilibiliApiService for B站 data and local
SQLite for persistent data. No more BackendApiClient dependencies."
```

---

## Task 10: Delete Python Backend Directory and Final Cleanup

**Files:**
- Delete: `listen-vision-api-python/` (entire directory)
- Modify: `frontend_flutter/` — remaining cleanup
- Modify: `CLAUDE.md` — update project documentation
- Modify: `frontend_flutter/lib/services/` — remove download_service.dart SSE code

- [ ] **Step 1: Delete Python backend**

```bash
cd c:/Projects/listen-vision-audio-app
rm -rf listen-vision-api-python/
```

- [ ] **Step 2: Remove SSE download path from DownloadService**

In `frontend_flutter/lib/services/download_service.dart`, delete:
- `downloadAudio` method (SSE-based, uses backend endpoint)
- `_processSSEStream` method
- `_processSSEEvent` method
- `getDownloadUrl` method (returns backend URL)
- Keep `simpleDownload` for direct CDN downloads
- Keep utility methods: `generateFileName`, `buildSavePath`

- [ ] **Step 3: Update CLAUDE.md**

Remove backend-related sections:
- Delete "Python 后端（主后端）" from project structure
- Delete the entire "常用命令 → 后端" section
- Update architecture diagram: remove API Client layer, add B站 direct layer
- Update "认证架构" — remove "主账号" and "游客模式", keep "平台绑定 (B站QR码，Cookie加密存储)"
- Update the project structure table
- Remove references to `listen-vision-api-python/` directory

- [ ] **Step 4: Run final flutter analyze**

```bash
cd frontend_flutter && flutter analyze
```

Expected: Clean, no errors.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: delete Python backend, final cleanup

Complete removal of listen-vision-api-python directory. Remove SSE
download path. Update CLAUDE.md to reflect backend-free architecture."
```

---

## Task 11: Run Code Generation and Verify

**Files:**
- Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 1: Run code generation**

```bash
cd frontend_flutter
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generates new .g.dart and .freezed.dart files for any modified state classes.

- [ ] **Step 2: Run flutter analyze again**

```bash
cd frontend_flutter && flutter analyze
```

Expected: Clean, no errors after generation.

- [ ] **Step 3: Run flutter test**

```bash
cd frontend_flutter && flutter test
```

Check for test failures. Tests that reference deleted files (auth, netease, backend_api_client) will fail — delete or update them.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: run code generation and fix test references"
```
