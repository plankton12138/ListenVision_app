import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:dio/dio.dart';
import 'package:demo/core/utils/permission_helper.dart';

/// 音频元数据加载器
///
/// 职责：
/// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）
/// 2. 从网络加载在线音频封面
/// 3. 从文件路径提取元数据（后备方案）
/// 4. 元数据缓存管理
class AudioMetadataLoader {
  // ==================== 缓存 ====================

  /// 封面缓存（URL -> Uint8List）
  final Map<String, Uint8List> _coverCache = {};

  /// 缓存大小限制
  static const int _maxCacheSize = 50;

  // ==================== Dio 实例 ====================

  final Dio _dio = Dio();

  // ==================== 单例模式 ====================

  static final AudioMetadataLoader _instance = AudioMetadataLoader._internal();

  factory AudioMetadataLoader() => _instance;

  AudioMetadataLoader._internal();

  // ==================== 本地元数据提取 ====================

  /// 从音频文件提取元数据
  ///
  /// [filePath] 音频文件路径
  /// 返回: {
  ///   'title': String,
  ///   'artist': String,
  ///   'album': String,
  ///   'cover': Uint8List?
  /// }
  Future<Map<String, dynamic>> extractFromFile(String filePath) async {
    try {
      debugPrint('【AudioMetadataLoader】开始提取元数据: $filePath');

      // Android 11+ 需要权限
      if (!kIsWeb && Platform.isAndroid) {
        final hasPermission = await PermissionHelper.requestManageStoragePermission();
        if (!hasPermission) {
          throw Exception('需要存储权限才能读取音频文件');
        }
      }

      // 文件存在性检查
      if (!File(filePath).existsSync()) {
        throw Exception('文件不存在: $filePath');
      }

      // 使用 compute() 在 isolate 中提取元数据（避免阻塞 UI）
      final metadataResult = await compute(_extractMetadataIsolate, filePath);

      debugPrint('【AudioMetadataLoader】元数据提取完成: ${metadataResult['title'] ?? '(未知)'} - ${metadataResult['artist'] ?? '(未知)'}');
      return metadataResult;
    } catch (e) {
      debugPrint('【AudioMetadataLoader】元数据提取失败: $e');
      // 返回默认值
      return _extractMetadataFromPath(filePath);
    }
  }

  /// 在 isolate 中提取元数据（静态函数）
  ///
  /// 使用 Flutter 的 compute() 将阻塞操作移到后台线程
  static Future<Map<String, dynamic>> _extractMetadataIsolate(String filePath) async {
    try {
      final metadata = await MetadataGod.readMetadata(file: filePath);

      Uint8List? cover;
      if (metadata.picture != null) {
        cover = metadata.picture!.data;
      }

      return {
        'title': metadata.title?.trim() ?? '',
        'artist': metadata.artist?.trim() ?? '',
        'album': metadata.album?.trim() ?? '',
        'cover': cover,
      };
    } catch (e) {
      debugPrint('【AudioMetadataLoader】isolate 元数据解析失败: $e');
      return {
        'title': '',
        'artist': '',
        'album': '',
        'cover': null,
      };
    }
  }

  /// 从文件路径提取元数据（后备方案）
  ///
  /// 当无法从文件元数据获取时，从文件名推断
  Map<String, dynamic> _extractMetadataFromPath(String filePath) {
    try {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      var nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      // 移除常见标签
      nameWithoutExt = nameWithoutExt
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'【.*?】'), '')
          .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'（Official.*?）', caseSensitive: false), '')
          .trim();

      String artist = '';
      String title = nameWithoutExt;

      // 格式1: "艺术家 - 标题"
      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }
      // 格式2: "艺术家 标题"（首字母大写）
      else if (RegExp(r'^[A-Z][a-z]+\s+[A-Z][a-z]+').hasMatch(nameWithoutExt)) {
        final words = nameWithoutExt.split(' ');
        if (words.length >= 2 &&
            RegExp(r'^[A-Z][a-z]+$').hasMatch(words[0]) &&
            RegExp(r'^[A-Z][a-z]+$').hasMatch(words[1])) {
          artist = '${words[0]} ${words[1]}';
          title = words.skip(2).join(' ');
          if (title.isEmpty) title = nameWithoutExt;
        }
      }
      // 格式3: 带中文括号的注释
      else if (nameWithoutExt.contains('（') && nameWithoutExt.contains('）')) {
        final match = RegExp(r'^([^(（]+)[（(].*?[）)](.*)$').firstMatch(nameWithoutExt);
        if (match != null) {
          final beforeComment = match.group(1)!.trim();
          final afterComment = match.group(2)!.trim();
          final words = beforeComment.split(' ');
          if (words.length >= 2 &&
              words.every((w) => RegExp(r'^[A-Z][a-z]+$').hasMatch(w))) {
            artist = beforeComment;
            title = afterComment.isNotEmpty ? afterComment : beforeComment;
          } else if (words.isNotEmpty &&
              RegExp(r'^[A-Z][a-z]+$').hasMatch(words[0])) {
            artist = words[0].trim();
            title = afterComment.isNotEmpty ? afterComment : words.skip(1).join(' ');
            if (title.isEmpty) title = beforeComment;
          } else {
            title = nameWithoutExt.replaceAll(RegExp(r'[（(].*?[）)]'), '').trim();
          }
        }
      }

      artist = artist.replaceAll(RegExp(r'\s+'), ' ').trim();
      title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

      return {
        'title': title.isNotEmpty ? title : nameWithoutExt,
        'artist': artist.isNotEmpty ? artist : '未知艺术家',
        'album': '',
        'cover': null,
      };
    } catch (e) {
      debugPrint('【AudioMetadataLoader】路径解析失败: $e');
      return {
        'title': filePath.split(RegExp(r'[\\/]')).last,
        'artist': '未知艺术家',
        'album': '',
        'cover': null,
      };
    }
  }

  // ==================== 在线封面加载 ====================

  /// 从 URL 加载封面图片
  ///
 /// [coverUrl] 封面图片 URL
  /// [useCache] 是否使用缓存（默认 true）
  Future<Uint8List?> loadOnlineCover(
    String coverUrl, {
    bool useCache = true,
  }) async {
    if (coverUrl.isEmpty) return null;

    // 检查缓存
    if (useCache && _coverCache.containsKey(coverUrl)) {
      debugPrint('【AudioMetadataLoader】封面缓存命中: $coverUrl');
      return _coverCache[coverUrl];
    }

    try {
      debugPrint('【AudioMetadataLoader】加载在线封面: $coverUrl');

      final response = await _dio.get(
        coverUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data is List<int>) {
        final imageData = Uint8List.fromList(response.data as List<int>);

        // 添加到缓存
        if (useCache) {
          _addToCache(coverUrl, imageData);
        }

        debugPrint('【AudioMetadataLoader】封面加载成功，大小: ${imageData.length} bytes');
        return imageData;
      }
    } catch (e) {
      debugPrint('【AudioMetadataLoader】加载在线封面失败: $e');
    }

    return null;
  }

  /// 预加载封面（不阻塞当前流程）
  ///
  /// [coverUrl] 封面 URL
  /// [onLoaded] 加载完成回调
  void preloadCover(
    String coverUrl,
    void Function(Uint8List?) onLoaded,
  ) {
    loadOnlineCover(coverUrl).then((coverData) {
      onLoaded(coverData);
    });
  }

  /// 添加到缓存
  void _addToCache(String url, Uint8List data) {
    // 如果缓存已满，移除最旧的项
    if (_coverCache.length >= _maxCacheSize) {
      final firstKey = _coverCache.keys.first;
      _coverCache.remove(firstKey);
      debugPrint('【AudioMetadataLoader】缓存已满，移除: $firstKey');
    }

    _coverCache[url] = data;
    debugPrint('【AudioMetadataLoader】添加到缓存: $url, 当前缓存数: ${_coverCache.length}');
  }

  /// 清除封面缓存
  void clearCache() {
    _coverCache.clear();
    debugPrint('【AudioMetadataLoader】封面缓存已清除');
  }

  /// 清除指定 URL 的缓存
  void clearCacheForUrl(String url) {
    _coverCache.remove(url);
    debugPrint('【AudioMetadataLoader】已清除缓存: $url');
  }

  // ==================== 元数据合并 ====================

  /// 合并多个来源的元数据
  ///
  /// 优先级: 文件元数据 > 数据库 > 文件名提取
  ///
  /// [fileMetadata] 从文件提取的元数据
  /// [dbMetadata] 从数据库获取的元数据（可选）
  /// [fallbackPathMetadata] 从路径提取的元数据（可选）
  Map<String, dynamic> mergeMetadata({
    required Map<String, dynamic> fileMetadata,
    Map<String, dynamic>? dbMetadata,
    Map<String, dynamic>? fallbackPathMetadata,
  }) {
    // 文件元数据
    final fileTitle = (fileMetadata['title'] as String?) ?? '';
    final fileArtist = (fileMetadata['artist'] as String?) ?? '';
    final fileCover = fileMetadata['cover'] as Uint8List?;

    // 数据库元数据
    final dbTitle = (dbMetadata?['title'] as String?) ?? '';
    final dbArtist = (dbMetadata?['artist'] as String?) ?? '';
    final dbCover = dbMetadata?['albumArt'] as Uint8List?;

    // 路径元数据
    final pathTitle = (fallbackPathMetadata?['title'] as String?) ?? '';
    final pathArtist = (fallbackPathMetadata?['artist'] as String?) ?? '未知艺术家';

    // 合并策略: 文件元数据 > 数据库 > 路径提取
    final dbHasValidTitle = dbTitle.isNotEmpty && dbTitle != '未知标题';
    final dbHasValidArtist = dbArtist.isNotEmpty && dbArtist != '未知艺术家';

    final title = fileTitle.isNotEmpty ? fileTitle : (dbHasValidTitle ? dbTitle : pathTitle);
    final artist = fileArtist.isNotEmpty ? fileArtist : (dbHasValidArtist ? dbArtist : pathArtist);
    final cover = fileCover ?? dbCover;

    return {
      'title': title,
      'artist': artist,
      'album': fileMetadata['album'] ?? dbMetadata?['album'] ?? '',
      'cover': cover,
    };
  }

  // ==================== 工具方法 ====================

  /// 从文件名提取扩展名
  String getFileExtension(String filePath) {
    return filePath.split(RegExp(r'\.')).last.toLowerCase();
  }

  /// 判断是否为支持的音频格式
  bool isSupportedAudioFormat(String filePath) {
    const supportedFormats = [
      'mp3', 'm4a', 'flac', 'wav', 'ogg', 'wma',
      'aac', 'opus', 'mp4', 'm4s',
    ];
    final ext = getFileExtension(filePath);
    return supportedFormats.contains(ext);
  }

  /// 格式化时长（秒 -> MM:SS）
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 清理资源
  void dispose() {
    _dio.close();
    _coverCache.clear();
    debugPrint('【AudioMetadataLoader】已释放');
  }
}
