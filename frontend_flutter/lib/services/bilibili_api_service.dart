import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/app_logger.dart';
import '../models/audio.dart';
import '../models/subtitle.dart';
import '../models/recommendation.dart';
import 'bilibili_headers.dart';

class AudioStreamInfo {
  final String url;
  final int qualityId;
  final int size;
  final String codecs;

  const AudioStreamInfo({
    required this.url,
    required this.qualityId,
    required this.size,
    required this.codecs,
  });
}

class AudioStreamsData {
  final String bvid;
  final int cid;
  final String title;
  final List<AudioStreamInfo> streams;

  const AudioStreamsData({
    required this.bvid,
    required this.cid,
    required this.title,
    required this.streams,
  });
}

class BilibiliApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  BilibiliApiService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _baseUrl = 'https://api.bilibili.com';
  static const _passportUrl = 'https://passport.bilibili.com';

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

  Map<String, String> _buildHeaders({Map<String, String>? cookies}) {
    final headers = Map<String, String>.from(bilibiliHeaders);
    if (cookies != null) {
      headers['Cookie'] = _buildCookieHeader(cookies);
    }
    return headers;
  }

  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/view',
      queryParameters: {'bvid': bvid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    return data;
  }

  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    Map<String, String>? cookies,
  }) async {
    final videoInfo = await getVideoInfo(bvid);
    final cid = videoInfo['cid'];
    if (cid == null) throw Exception('无法获取 cid');

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

  Future<SubtitleData> getSubtitles(
    String bvid, {
    Map<String, String>? cookies,
  }) async {
    try {
      final videoInfo = await getVideoInfo(bvid);
      final cid = videoInfo['cid'];
      if (cid == null) {
        return SubtitleData(bvid: bvid, cid: 0, subtitles: []);
      }

      final playerResponse = await _dio.get(
        '$_baseUrl/x/player/v2',
        queryParameters: {'bvid': bvid, 'cid': cid},
        options: Options(headers: _buildHeaders(cookies: cookies)),
      );
      final playerData = _extractData(playerResponse.data);
      final subtitleMeta =
          playerData['subtitle']?['subtitles'] as List<dynamic>? ?? [];

      final subtitles = <SubtitleTrack>[];
      for (final meta in subtitleMeta) {
        final url = normalizeBilibiliUrl(meta['subtitle_url'] ?? '');
        if (url.isEmpty) continue;

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

        subtitles.add(SubtitleTrack(
          lan: meta['lan'] ?? '',
          lanDoc: meta['lan_doc'] ?? '',
          lines: lines,
        ));
      }

      return SubtitleData(
        bvid: bvid,
        cid: cid,
        subtitles: subtitles,
      );
    } catch (e) {
      AppLogger.warn('BilibiliApiService', '获取字幕失败 (可能需要登录): $e');
      return SubtitleData(
        bvid: bvid,
        cid: 0,
        subtitles: [],
        needLogin: true,
      );
    }
  }

  Future<List<Audio>> search({
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

    return result
        .where((item) => item['type'] == 'video' && item['bvid'] != null)
        .map((item) {
      return Audio.fromDto({
        'bvid': item['bvid'],
        'title': _cleanHtmlTags(item['title'] ?? ''),
        'author': item['author'] ?? '',
        'pic': normalizeBilibiliUrl(item['pic'] ?? ''),
        'duration': parseBilibiliDuration(item['duration']),
        'play': item['play'] ?? 0,
      });
    }).toList();
  }

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

  Future<List<Recommendation>> getRecommendations({int page = 1}) async {
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/popular',
      queryParameters: {'ps': 50, 'pn': page},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((item) => _parseRecommendation(item)).toList();
  }

  Future<List<Recommendation>> getRank({String type = 'music'}) async {
    final typeMap = {
      'music': 1,
      'hot': 0,
      'dance': 20,
      'game': 4,
      'knowledge': 36,
      'technology': 188,
      'life': 160,
    };
    final rid = typeMap[type] ?? 1;
    final response = await _dio.get(
      '$_baseUrl/x/web-interface/ranking/v2',
      queryParameters: {'rid': rid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((item) => _parseRecommendation(item)).toList();
  }

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

  Future<List<Recommendation>> getByCategory(
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
    return archives.map((item) => _parseRecommendation(item)).toList();
  }

  Future<Map<String, dynamic>> getUploaderInfo(int mid) async {
    final response = await _dio.get(
      '$_baseUrl/x/space/wbi/acc/info',
      queryParameters: {'mid': mid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    return data;
  }

  Future<Map<String, String>> refreshCookie(
      Map<String, String> cookies) async {
    final response = await _dio.post(
      '$_passportUrl/x/passport-login/web/cookie/refresh',
      options: Options(headers: _buildHeaders(cookies: cookies)),
    );
    final setCookie = response.headers['set-cookie'];
    return _parseCookies(setCookie ?? [], cookies);
  }

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

  String _cleanHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Recommendation _parseRecommendation(Map<String, dynamic> item) {
    return Recommendation.fromDto({
      'bvid': item['bvid'] ?? '',
      'title': _cleanHtmlTags(item['title'] ?? ''),
      'author': item['owner']?['name'] ?? item['author'] ?? '',
      'pic': normalizeBilibiliUrl(item['pic'] ?? item['cover'] ?? ''),
      'duration': parseBilibiliDuration(item['duration']).toString(),
      'play': item['stat']?['view'] ?? item['play'] ?? 0,
    });
  }

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
