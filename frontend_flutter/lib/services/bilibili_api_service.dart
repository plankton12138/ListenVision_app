import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/errors/exceptions.dart';
import '../models/audio.dart';
import '../models/recommendation.dart';
import 'bilibili_headers.dart';

final bilibiliApiServiceProvider = Provider<BilibiliApiService>((ref) {
  return BilibiliApiService(dio: ref.watch(apiDioProvider));
});

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

  BilibiliApiService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  static const _baseUrl = 'https://api.bilibili.com';

  Future<Map<String, dynamic>> getVideoInfo(
    String bvid, {
    CancelToken? cancelToken,
  }) async {
    final response = await _get(
      '$_baseUrl/x/web-interface/view',
      queryParameters: {'bvid': bvid},
      cancelToken: cancelToken,
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    return data;
  }

  /// 检查视频是否仍然可访问
  ///
  /// 返回 true = 可访问；false = 明确不存在；null = 未能确认。
  /// 不会抛出异常，网络错误等临时性问题返回 null，保留已有状态。
  Future<bool?> checkVideoExists(String bvid) async {
    try {
      final response = await _get(
        '$_baseUrl/x/web-interface/view',
        queryParameters: {'bvid': bvid},
        options: Options(headers: bilibiliHeaders),
      );
      final body = response.data;
      if (body is Map && body['code'] == 0) return true;

      final code = body is Map ? (body['code'] ?? -1) : -1;
      if (code == -404 || code == 62002) return false;
      return null; // 临时问题：保留原状态
    } catch (_) {
      return null; // 网络错误不代表源可用或失效
    }
  }

  /// 批量检查视频是否存在（并发，带限制）
  ///
  /// 返回 `Map<String, bool?>`（bvid -> exists）。不会抛出异常。
  Future<Map<String, bool?>> batchCheckVideosExist(
    List<String> bvids, {
    int concurrency = 5,
  }) async {
    final results = <String, bool?>{};
    final semaphore = <Future<void>>[];
    int index = 0;

    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= bvids.length) break;
        results[bvids[i]] = await checkVideoExists(bvids[i]);
      }
    }

    for (int i = 0; i < concurrency.clamp(1, 5) && i < bvids.length; i++) {
      semaphore.add(worker());
    }
    await Future.wait(semaphore);
    return results;
  }

  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    int? cid,
    CancelToken? cancelToken,
  }) async {
    final elapsed = Stopwatch()..start();
    int resolvedCid;
    String title = '';

    if (cid != null) {
      resolvedCid = cid;
    } else {
      final videoInfo = await getVideoInfo(bvid, cancelToken: cancelToken);
      final c = videoInfo['cid'];
      if (c == null) throw Exception('无法获取 cid');
      resolvedCid = c is int ? c : int.parse('$c');
      title = videoInfo['title'] ?? '';
    }

    final response = await _get(
      '$_baseUrl/x/player/wbi/playurl',
      cancelToken: cancelToken,
      budget: const Duration(seconds: 30) - elapsed.elapsed,
      queryParameters: {
        'bvid': bvid,
        'cid': resolvedCid,
        'fnval': 16,
        'fnver': 0,
        'fourk': 1,
      },
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final dashAudio = data['dash']?['audio'] as List<dynamic>? ?? [];

    final streams = dashAudio.map((audio) {
      return AudioStreamInfo(
        url: normalizeBilibiliUrl(audio['baseUrl'] ?? audio['base_url'] ?? ''),
        qualityId: audio['id'] ?? 0,
        size: audio['size'] ?? 0,
        codecs: audio['codecs'] ?? '',
      );
    }).toList();

    return AudioStreamsData(
      bvid: bvid,
      cid: resolvedCid,
      title: title,
      streams: streams,
    );
  }

  /// 获取视频的分P列表
  ///
  /// 调用 x/web-interface/view 获取 pages 数组
  /// 返回视频的全部分P信息，单P视频返回1个元素的列表
  Future<List<AudioPage>> getVideoPages(
    String bvid, {
    CancelToken? cancelToken,
  }) async {
    final videoInfo = await getVideoInfo(bvid, cancelToken: cancelToken);
    final pages = videoInfo['pages'] as List<dynamic>? ?? [];
    return pages.map((page) {
      final cid = page['cid'];
      final duration = page['duration'];
      return AudioPage(
        cid: cid is int ? cid : (int.tryParse('$cid') ?? 0),
        title: _cleanHtmlTags(page['part'] ?? ''),
        duration: duration is int ? duration : (int.tryParse('$duration') ?? 0),
      );
    }).toList();
  }

  Future<List<Audio>> search({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _get(
      '$_baseUrl/x/web-interface/wbi/search/type',
      cancelToken: cancelToken,
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
            'videos': item['videos'] ?? 1,
          });
        })
        .toList();
  }

  Future<List<String>> getSearchSuggestions(
    String keyword, {
    CancelToken? cancelToken,
  }) async {
    final response = await _get(
      'https://s.search.bilibili.com/main/suggest',
      cancelToken: cancelToken,
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
    final response = await _get(
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
    final response = await _get(
      '$_baseUrl/x/web-interface/ranking/v2',
      queryParameters: {'rid': rid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((item) => _parseRecommendation(item)).toList();
  }

  Future<List<Map<String, dynamic>>> getZones() async {
    final response = await _get(
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
    final response = await _get(
      '$_baseUrl/x/web-interface/newlist',
      queryParameters: {'rid': tid, 'type': newest ? 1 : 0},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    final archives = data['archives'] as List<dynamic>? ?? [];
    return archives.map((item) => _parseRecommendation(item)).toList();
  }

  Future<Map<String, dynamic>> getUploaderInfo(int mid) async {
    final response = await _get(
      '$_baseUrl/x/space/wbi/acc/info',
      queryParameters: {'mid': mid},
      options: Options(headers: bilibiliHeaders),
    );
    final data = _extractData(response.data);
    return data;
  }

  Future<Response<dynamic>> _get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    Duration budget = const Duration(seconds: 30),
  }) {
    if (budget <= Duration.zero) throw NetworkException.timeout();
    return DioClient.get(
      _dio,
      url,
      queryParameters: queryParameters,
      headers: options?.headers,
      cancelToken: cancelToken,
      budget: budget,
    );
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

  /// 清理 HTML 标签并解码 HTML 实体
  ///
  /// B站 API 返回的标题等字段可能包含 HTML 标签和实体编码
  /// （如 &amp; &lt; &#39; 等），需要清理后才能用于 UI 展示。
  String _cleanHtmlTags(String text) {
    var result = text.replaceAll(RegExp(r'<[^>]*>'), '');
    result = _decodeHtmlEntities(result);
    return result;
  }

  /// 解码常见 HTML 实体
  ///
  /// 处理 B站 API 返回数据中常见的 HTML 实体编码。
  /// 覆盖：命名实体（&amp; &lt; &gt; &quot; &nbsp; &apos;）
  /// 以及十进制/十六进制数字实体（&#39; &#x27; 等）。
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&apos;', "'")
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)),
        )
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
        );
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
