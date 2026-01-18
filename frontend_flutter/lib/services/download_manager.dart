import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:demo/services/bilibiliApiService.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:metadata_god/metadata_god.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;

/// 下载管理器
///
/// Phase 1 改进：
/// - 优先使用后端 API 获取视频信息，HTML 解析作为降级方案
/// - 使用后端代理 URL 解决防盗链问题
/// - 保持原有的下载管理功能（断点续传、暂停/恢复等）
class DownloadManager with ChangeNotifier {
  late Database _database;
  List<Map<String, dynamic>> downloads = [];
  final Map<int, CancelToken> _cancelTokens = {};

  BilibiliApiService? _bilibiliApiService;

  /// 设置B站API服务
  void setBilibiliApiService(BilibiliApiService service) {
    _bilibiliApiService = service;
    debugPrint('【DownloadManager】已设置BilibiliApiService');
  }

  Future<void> _loadDownloads() async {
    downloads = await _database.query('downloads');
    notifyListeners();
  }

  Future<void> initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    debugPrint('数据库路径: ${path.join(directory.path, 'downloads.db')}');
    _database = await openDatabase(
      path.join(directory.path, 'downloads.db'),
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE downloads(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT,
          savePath TEXT,
          downloadedBytes INTEGER,
          totalBytes INTEGER,
          isPaused INTEGER,
          originalUrl TEXT,
          title TEXT
          )''',
        );
      },
      version: 1,
    );
    await _loadDownloads();
  }

  // ==================== 下载管理 ====================

  /// 添加下载任务
  Future<void> addDownload(BuildContext context, String url) async {
    // 检查是否为B站视频
    if (!url.startsWith('https://www.bilibili.com/video/') &&
        !url.startsWith('http://www.bilibili.com/video/')) {
      showMySnackBar(context, '仅支持B站视频下载', Colors.red, 500);
      return;
    }

    try {
      final bvid = _extractBvid(url);
      if (bvid == null || bvid.isEmpty) {
        showMySnackBar(context, '无法解析视频ID', Colors.red, 500);
        return;
      }

      String title;
      String author;
      String? picUrl;
      String audioBaseUrl;

      // 优先使用后端API
      final videoData = await _getVideoInfoFromBackend(bvid);
      if (videoData != null) {
        title = videoData['title'];
        author = videoData['author'];
        picUrl = videoData['pic'];
        audioBaseUrl = _bilibiliApiService!.getProxyAudioUrl(videoData['audioUrl']);
        debugPrint('【DownloadManager】使用后端API: $title');
      } else {
        // 降级：HTML解析
        final htmlData = await _getVideoInfoFromHtml(url);
        if (htmlData == null) {
          showMySnackBar(context, '获取视频信息失败', Colors.red, 500);
          return;
        }
        title = htmlData['title'];
        author = htmlData['author'];
        picUrl = htmlData['pic'];
        audioBaseUrl = htmlData['audioUrl'];
        debugPrint('【DownloadManager】使用HTML降级: $title');
      }

      final sanitizedTitle = sanitizeTitle(title);
      final savePath = await _pickDirectory();
      if (savePath == null) return;

      final audioFilePath = File('$savePath/$sanitizedTitle.m4a');

      int id = await _database.insert(
        'downloads',
        {
          'url': audioBaseUrl,
          'savePath': audioFilePath.path,
          'downloadedBytes': 0,
          'totalBytes': 0,
          'isPaused': 0,
          'originalUrl': url,
          'title': title,
        },
      );
      showMySnackBar(context, '已添加到下载列表: $title', Colors.green, 1000);
      await startDownload(audioBaseUrl, audioFilePath.path, url, id,
          videoData: {'title': title, 'author': author, 'pic': picUrl, 'bvid': bvid});
      await _loadDownloads();
    } catch (e) {
      debugPrint('下载失败: $e');
      showMySnackBar(context, '下载失败: $e', Colors.red, 1000);
    }
  }

  /// 开始下载
  Future<void> startDownload(
    String audioBaseUrl,
    String savePath,
    String originalUrl,
    int id, {
    Map<String, dynamic>? videoData,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;
    RandomAccessFile? raf;
    int totalBytes = 0;

    try {
      var response = await _database.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );
      int downloadedBytes = response.first['downloadedBytes'] as int;
      totalBytes = response.first['totalBytes'] as int;

      // 检查是否已下载完成
      if (downloadedBytes >= totalBytes && totalBytes > 0) {
        debugPrint('已下载完成');
        await _database.update('downloads', {'isPaused': 0},
            where: 'id = ?', whereArgs: [id]);
        return;
      }

      var dio = Dio();
      var options = Options(
        headers: {
          'Range': totalBytes > 0 ? 'bytes=$downloadedBytes-' : 'bytes=0-',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://www.bilibili.com/',
        },
        responseType: ResponseType.stream,
      );

      var resp = await dio.getUri(
        Uri.parse(audioBaseUrl),
        options: options,
        cancelToken: cancelToken,
      );

      // 处理content-range
      final contentRange = resp.headers.value('content-range');
      if (contentRange != null) {
        totalBytes = int.parse(contentRange.split('/').last);
      } else {
        final contentLength = resp.headers.value('content-length');
        if (contentLength != null) {
          totalBytes = int.parse(contentLength);
        }
      }

      final file = File(savePath);
      raf = await file.open(mode: FileMode.writeOnlyAppend);

      await for (var chunk in resp.data.stream) {
        if (cancelToken.isCancelled ||
            (await _database.query('downloads', where: 'id = ?', whereArgs: [id]))
                    .first['isPaused'] ==
                1) {
          break;
        }

        await raf.writeFrom(chunk);
        downloadedBytes += chunk.length as int;

        await _database.update(
          'downloads',
          {'downloadedBytes': downloadedBytes, 'totalBytes': totalBytes},
          where: 'id = ?',
          whereArgs: [id],
        );
        notifyListeners();
      }

      // 下载完成
      if (downloadedBytes >= totalBytes) {
        await _database.update('downloads', {'isPaused': 0},
            where: 'id = ?', whereArgs: [id]);
        await afterDownload(originalUrl, savePath, videoData: videoData);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 416) {
        debugPrint('下载已完成');
        await _database.update(
          'downloads',
          {'downloadedBytes': totalBytes, 'totalBytes': totalBytes, 'isPaused': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } finally {
      await raf?.close();
      _cancelTokens.remove(id);
      await _loadDownloads();
    }
  }

  /// 暂停下载
  Future<void> pauseDownload(int id) async {
    await _database.update('downloads', {'isPaused': 1},
        where: 'id = ?', whereArgs: [id]);
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);
    await _loadDownloads();
  }

  /// 恢复下载
  Future<void> resumeDownload(int id) async {
    await _database.update('downloads', {'isPaused': 0},
        where: 'id = ?', whereArgs: [id]);
    var download = await _database.query('downloads',
        where: 'id = ?', whereArgs: [id]);
    String url = download.first['url'] as String;
    String savePath = download.first['savePath'] as String;
    String originalUrl = download.first['originalUrl'] as String;
    startDownload(url, savePath, originalUrl, id);
    await _loadDownloads();
  }

  /// 删除下载
  Future<void> deleteDownload(int id) async {
    await _database.delete('downloads', where: 'id = ?', whereArgs: [id]);
    await _loadDownloads();
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    return await _database.query('downloads');
  }

  // ==================== 元数据写入 ====================

  /// 下载后处理：写入元数据
  Future<void> afterDownload(String url, String audioFilePath,
      {Map<String, dynamic>? videoData}) async {
    debugPrint('【afterDownload】处理文件: $audioFilePath');

    String title;
    String author;
    String imageUrl;

    // 优先使用传入的视频数据
    if (videoData != null) {
      title = videoData['title'] ?? '未知标题';
      author = videoData['author'] ?? '未知艺术家';
      imageUrl = videoData['pic'] ?? '';
    } else if (_bilibiliApiService != null) {
      final bvid = _extractBvid(url);
      if (bvid != null) {
        try {
          final info = await _bilibiliApiService!.getVideoInfo(bvid);
          title = info['title'] ?? '未知标题';
          author = info['owner']?['name'] ?? '未知艺术家';
          imageUrl = info['pic'] ?? '';
        } catch (e) {
          final htmlData = await _getVideoInfoFromHtml(url);
          if (htmlData != null) {
            title = htmlData['title'];
            author = htmlData['author'];
            imageUrl = htmlData['pic'] ?? '';
          } else {
            title = '未知标题';
            author = '未知艺术家';
            imageUrl = '';
          }
        }
      } else {
        title = '未知标题';
        author = '未知艺术家';
        imageUrl = '';
      }
    } else {
      final htmlData = await _getVideoInfoFromHtml(url);
      if (htmlData != null) {
        title = htmlData['title'];
        author = htmlData['author'];
        imageUrl = htmlData['pic'] ?? '';
      } else {
        title = '未知标题';
        author = '未知艺术家';
        imageUrl = '';
      }
    }

    // 下载封面图片
    Uint8List? imageBytes;
    try {
      if (_bilibiliApiService != null) {
        final picUrl = _bilibiliApiService!.getProxyImageUrl(imageUrl);
        final imageResponse = await http.get(Uri.parse(picUrl));
        imageBytes = imageResponse.bodyBytes;
      } else {
        final dio = Dio();
        final response = await dio.get(
          imageUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              'Referer': 'https://www.bilibili.com/',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ),
        );
        imageBytes = response.data as Uint8List;
      }
    } catch (e) {
      debugPrint('【afterDownload】封面下载失败: $e');
    }

    // 写入元数据
    try {
      final picture = imageBytes != null
          ? Picture(data: imageBytes, mimeType: 'image/jpeg')
          : null;

      await MetadataGod.writeMetadata(
        file: audioFilePath,
        metadata: Metadata(
          title: title,
          artist: author,
          album: url,
          picture: picture,
        ),
      );
      debugPrint('【afterDownload】元数据写入成功');
    } catch (e) {
      debugPrint('【afterDownload】元数据写入失败: $e');
    }
  }

  // ==================== 工具方法 ====================

  /// 从URL中提取BVID
  String? _extractBvid(String url) {
    final bvidRegex = RegExp(r'(BV[a-zA-Z0-9]{10})');
    final match = bvidRegex.firstMatch(url);
    return match?.group(1);
  }

  /// 通过后端API获取视频信息
  Future<Map<String, dynamic>?> _getVideoInfoFromBackend(String bvid) async {
    if (_bilibiliApiService == null) return null;

    try {
      final videoInfo = await _bilibiliApiService!.getVideoInfo(bvid);
      final audioStream = await _bilibiliApiService!.getAudioStream(bvid);

      return {
        'title': videoInfo['title'] ?? '未知标题',
        'author': videoInfo['owner']?['name'] ?? '未知艺术家',
        'pic': videoInfo['pic'],
        'audioUrl': audioStream['url'],
        'bvid': bvid,
      };
    } catch (e) {
      debugPrint('【DownloadManager】后端API失败: $e');
      return null;
    }
  }

  /// 从HTML获取视频信息（降级方案）
  Future<Map<String, dynamic>?> _getVideoInfoFromHtml(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://www.bilibili.com/',
        },
      );

      final document = parse(response.body);
      final title = document.querySelector('h1.video-title')?.attributes['title'];
      final author = document
              .querySelector('meta[itemprop="author"][name="author"]')
              ?.attributes['content'];

      // 获取封面URL
      String? picUrl = document.querySelector('meta[itemprop="image"]')?.attributes['content'];
      picUrl ??= document.querySelector('meta[property="og:image"]')?.attributes['content'];
      picUrl ??= document.querySelector('meta[name="twitter:image"]')?.attributes['content'];

      if (picUrl != null && picUrl.startsWith('//')) {
        picUrl = 'https:$picUrl';
      }

      // 获取音频URL
      final scripts = document.querySelectorAll('script');
      String? playInfoScript;
      for (final script in scripts) {
        if (script.text.contains('window.__playinfo__')) {
          playInfoScript = script.text;
          break;
        }
      }
      if (playInfoScript == null) return null;

      final jsonStr =
          playInfoScript.split('window.__playinfo__=')[1].split(';')[0].trim();
      final playInfo = jsonDecode(jsonStr);
      final audioBaseUrl = playInfo['data']['dash']['audio'][0]['baseUrl'];

      return {
        'title': title ?? '未知标题',
        'author': author ?? '未知艺术家',
        'audioUrl': audioBaseUrl,
        'pic': picUrl ?? '',
      };
    } catch (e) {
      debugPrint('【DownloadManager】HTML解析失败: $e');
      return null;
    }
  }

  /// 选择保存目录
  Future<String?> _pickDirectory() async {
    try {
      return await getDirectoryPath();
    } catch (e) {
      return null;
    }
  }

  /// 清理标题字符串
  String sanitizeTitle(String input) {
    const pattern =
        r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》《》""''·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
