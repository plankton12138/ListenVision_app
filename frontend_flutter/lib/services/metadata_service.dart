import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show mustCallSuper, visibleForTesting;

import '../core/utils/app_logger.dart';
import '../core/utils/audio_metadata_helper.dart';
import '../core/constants/playback_config.dart';

/// 音频元数据结果
///
/// 统一的元数据返回格式
class MetadataResult {
  /// 标题
  final String title;

  /// 艺术家
  final String artist;

  /// 专辑
  final String album;

  /// 封面图片数据
  final Uint8List? cover;

  /// 时长（秒）
  final int? duration;

  const MetadataResult({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.cover,
    this.duration,
  });

  /// 是否为空元数据
  bool get isEmpty => title.isEmpty && artist.isEmpty;

  /// 转换为 Map（向后兼容）
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'cover': cover,
      'duration': duration,
    };
  }

  @override
  String toString() {
    return 'MetadataResult(title: $title, artist: $artist, album: $album, hasCover: ${cover != null})';
  }
}

/// 音频元数据服务
///
/// 封装 audio_metadata_reader 包和在线封面加载。
///
/// 职责：
/// - 从本地音频文件提取元数据（标题、艺术家、专辑、封面）
/// - 从网络加载在线音频封面
/// - 从文件路径提取元数据（后备方案）
/// - 封面缓存管理
///
/// 注意：此服务仅封装元数据读取，不涉及业务逻辑。
class MetadataService {
  // ==================== 私有字段 ====================

  /// Dio 实例（用于加载在线封面）
  final Dio _dio;

  /// 封面缓存（URL -> Uint8List）
  final Map<String, Uint8List> _coverCache = {};

  /// 是否已销毁
  bool _disposed = false;

  /// 封面缓存最大数量
  final int maxCacheSize;

  // ==================== 构造函数 ====================

  MetadataService({
    Dio? dio,
    this.maxCacheSize = PlaybackConfig.maxCoverCacheSize,
  }) : _dio = dio ?? Dio() {
    AppLogger.debug('MetadataService', '服务已创建');
  }

  // ==================== 本地元数据提取 ====================

  /// 从音频文件提取元数据
  ///
  /// [filePath] 音频文件路径
  /// [fetchCover] 是否提取封面图片（默认 true）
  ///
  /// 返回 MetadataResult 对象
  Future<MetadataResult> extractFromFile(
    String filePath, {
    bool fetchCover = true,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    AppLogger.debug('MetadataService', '========== 开始提取元数据: $fileName ==========');

    // Android 11+ 需要权限（调用方负责）
    // 文件存在性检查
    if (!File(filePath).existsSync()) {
      AppLogger.error('MetadataService', '文件不存在: $filePath');
      return _extractFromPath(filePath);
    }

    try {
      // 检测是否是 m4s 格式（B站分离音频流）
      if (AudioMetadataHelper.isM4sFormat(filePath)) {
        AppLogger.info('MetadataService', '检测到 m4s 格式文件，使用路径提取');
        return _extractFromPath(filePath);
      }

      // 使用 AudioMetadataHelper 读取元数据
      final helper = AudioMetadataHelper();
      final result = helper.readMetadata(filePath: filePath, fetchCover: fetchCover);

      AppLogger.debug('MetadataService', '元数据提取完成: ${result.title} - ${result.artist}, hasCover=${result.cover != null}');

      // 如果元数据为空，使用路径提取
      if (result.title.isEmpty && result.artist.isEmpty) {
        AppLogger.debug('MetadataService', '元数据为空，使用路径提取');
        return _extractFromPath(filePath);
      }

      return MetadataResult(
        title: result.title,
        artist: result.artist,
        album: result.album,
        cover: result.cover,
        duration: result.duration,
      );
    } catch (e) {
      final errorStr = e.toString().length > 150
          ? '${e.toString().substring(0, 150)}...'
          : e.toString();
      AppLogger.warn('MetadataService', '元数据提取失败，使用路径提取: $errorStr');
      return _extractFromPath(filePath);
    }
  }

  /// 从文件路径提取元数据（后备方案）
  ///
  /// 当无法从文件元数据获取时，从文件名推断
  MetadataResult _extractFromPath(String filePath) {
    final map = AudioMetadataHelper.extractFromPath(filePath);
    return MetadataResult(
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      cover: map['cover'] as Uint8List?,
    );
  }

  /// 从文件路径快速提取元数据（公开方法）
  ///
  /// 用于不阻塞的默认元数据显示
  MetadataResult extractMetadataFromPath(String filePath) {
    return _extractFromPath(filePath);
  }

  // ==================== 在线封面加载 ====================

  /// 从 URL 加载封面图片
  ///
  /// [coverUrl] 封面图片 URL
  /// [useCache] 是否使用缓存（默认 true）
  ///
  /// 返回封面图片数据（Uint8List），失败返回 null
  Future<Uint8List?> loadOnlineCover(
    String coverUrl, {
    bool useCache = true,
  }) async {
    if (_disposed) return null;
    if (coverUrl.isEmpty) return null;

    // 检查缓存
    if (useCache && _coverCache.containsKey(coverUrl)) {
      AppLogger.debug('MetadataService', '使用缓存封面: $coverUrl');
      return _coverCache[coverUrl];
    }

    try {
      AppLogger.debug('MetadataService', '加载在线封面: $coverUrl');

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

        AppLogger.debug('MetadataService', '封面加载成功，大小: ${imageData.length} bytes');
        return imageData;
      }
    } catch (e) {
      AppLogger.error('MetadataService', '加载在线封面失败: $e');
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
    if (_disposed) {
      onLoaded(null);
      return;
    }
    loadOnlineCover(coverUrl).then((coverData) {
      if (!_disposed) {
        onLoaded(coverData);
      }
    });
  }

  // ==================== 缓存管理 ====================

  /// 添加到缓存
  void _addToCache(String url, Uint8List data) {
    // 如果缓存已满，移除最旧的项
    if (_coverCache.length >= maxCacheSize) {
      final firstKey = _coverCache.keys.first;
      _coverCache.remove(firstKey);
      AppLogger.debug('MetadataService', '缓存已满，移除: $firstKey');
    }

    _coverCache[url] = data;
    AppLogger.debug('MetadataService', '添加到缓存: $url, 当前缓存数: ${_coverCache.length}');
  }

  /// 清除封面缓存
  void clearCache() {
    _coverCache.clear();
    AppLogger.debug('MetadataService', '封面缓存已清除');
  }

  /// 清除指定 URL 的缓存
  void clearCacheForUrl(String url) {
    _coverCache.remove(url);
    AppLogger.debug('MetadataService', '已清除缓存: $url');
  }

  // ==================== 工具方法 ====================

  /// 从文件名提取扩展名
  String getFileExtension(String filePath) {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex <= 0 || lastDotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }

  /// 判断是否为支持的音频格式
  bool isSupportedAudioFormat(String filePath) {
    return AudioMetadataHelper.isSupportedAudioFormat(filePath);
  }

  /// 格式化时长（秒 -> MM:SS）
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 检测文件是否是 m4s 格式（B站分离音频流）
  bool isM4sFormat(String filePath) {
    return AudioMetadataHelper.isM4sFormat(filePath);
  }

  /// 获取缓存大小
  int get cacheSize => _coverCache.length;

  // ==================== 测试支持 ====================

  @visibleForTesting
  void setHttpClientAdapter(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  // ==================== 资源释放 ====================

  /// 释放资源
  ///
  /// 调用后对象不可再使用。
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _dio.close();
    _coverCache.clear();

    AppLogger.debug('MetadataService', '服务已释放');
  }
}
