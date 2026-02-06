import 'dart:async';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../services/metadata_service.dart';

part 'metadata_viewmodel.freezed.dart';
part 'metadata_viewmodel.g.dart';

/// 元数据状态
@freezed
class MetadataState with _$MetadataState {
  const factory MetadataState({
    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 已加载的本地音频元数据（文件路径 -> 元数据）
    @Default({}) Map<String, AudioMetadata> localMetadata,

    /// 封面缓存（URL -> Uint8List）
    @Default({}) Map<String, Uint8List> coverCache,

    /// 错误消息
    String? errorMessage,
  }) = _MetadataState;
}

/// 音频元数据（简化的展示用）
@freezed
class AudioMetadata with _$AudioMetadata {
  const factory AudioMetadata({
    required String title,
    required String artist,
    required String album,
    Uint8List? cover,
  }) = _AudioMetadata;

  /// 从 MetadataResult 创建
  factory AudioMetadata.fromResult(MetadataResult result) {
    return AudioMetadata(
      title: result.title,
      artist: result.artist,
      album: result.album,
      cover: result.cover,
    );
  }
}

/// 元数据加载 ViewModel
///
/// 职责：
/// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）
/// 2. 从网络加载在线音频封面
/// 3. 元数据缓存管理
@Riverpod(keepAlive: true)
class MetadataViewModel extends _$MetadataViewModel {
  MetadataService? _service;

  @override
  MetadataState build() {
    _service = ref.watch(metadataServiceProvider);
    return const MetadataState();
  }

  // ==================== 本地元数据提取 ====================

  /// 从音频文件提取元数据
  ///
  /// [filePath] 音频文件路径
  /// [fetchCover] 是否提取封面图片（默认 true）
  Future<MetadataResult> extractFromFile(String filePath, {bool fetchCover = true}) async {
    try {
      AppLogger.debug('MetadataViewModel', '提取元数据: $filePath');

      final result = await _service!.extractFromFile(filePath, fetchCover: fetchCover);

      // 缓存元数据
      if (!result.isEmpty) {
        final audioMetadata = AudioMetadata.fromResult(result);
        state = state.copyWith(
          localMetadata: {...state.localMetadata, filePath: audioMetadata},
        );
      }

      return result;
    } catch (e) {
      AppLogger.error('MetadataViewModel', '提取元数据失败: $e');
      return _service!.extractMetadataFromPath(filePath);
    }
  }

  /// 从文件路径快速提取元数据（公开方法）
  MetadataResult extractFromPath(String filePath) {
    return _service!.extractMetadataFromPath(filePath);
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
    // 检查缓存
    if (useCache && state.coverCache.containsKey(coverUrl)) {
      return state.coverCache[coverUrl];
    }

    try {
      AppLogger.debug('MetadataViewModel', '加载在线封面: $coverUrl');
      final coverData = await _service!.loadOnlineCover(coverUrl, useCache: false);

      if (coverData != null) {
        // 添加到缓存
        state = state.copyWith(
          coverCache: {...state.coverCache, coverUrl: coverData},
        );
      }

      return coverData;
    } catch (e) {
      AppLogger.error('MetadataViewModel', '加载在线封面失败: $e');
      return null;
    }
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

  /// 清除指定 URL 的缓存
  void clearCacheForUrl(String url) {
    final newCache = Map<String, Uint8List>.from(state.coverCache);
    newCache.remove(url);
    state = state.copyWith(coverCache: newCache);
    AppLogger.debug('MetadataViewModel', '清除缓存: $url');
  }

  /// 清除所有封面缓存
  void clearCache() {
    state = state.copyWith(coverCache: {});
    _service!.clearCache();
    AppLogger.debug('MetadataViewModel', '封面缓存已清除');
  }

  // ==================== 批量操作 ====================

  /// 批量提取本地音频元数据
  Future<Map<String, AudioMetadata>> batchExtractMetadata(List<String> filePaths) async {
    final results = <String, AudioMetadata>{};

    for (final filePath in filePaths) {
      try {
        final result = await extractFromFile(filePath);
        if (!result.isEmpty) {
          results[filePath] = AudioMetadata.fromResult(result);
        }
      } catch (e) {
        AppLogger.warn('MetadataViewModel', '批量提取失败: $filePath, $e');
      }
    }

    AppLogger.info('MetadataViewModel', '批量提取完成: ${results.length}/${filePaths.length}');
    return results;
  }

  /// 批量加载在线封面
  Future<void> batchLoadCovers(List<String> coverUrls) async {
    final newCache = Map<String, Uint8List>.from(state.coverCache);

    for (final url in coverUrls) {
      if (!newCache.containsKey(url)) {
        try {
          final coverData = await _service!.loadOnlineCover(url, useCache: false);
          if (coverData != null) {
            newCache[url] = coverData;
          }
        } catch (e) {
          AppLogger.warn('MetadataViewModel', '加载封面失败: $url');
        }
      }
    }

    state = state.copyWith(coverCache: newCache);
    AppLogger.info('MetadataViewModel', '批量加载封面完成: ${newCache.length}/${coverUrls.length}');
  }

  // ==================== 工具方法 ====================

  /// 从文件名提取扩展名
  String getFileExtension(String filePath) {
    return _service!.getFileExtension(filePath);
  }

  /// 判断是否为支持的音频格式
  bool isSupportedAudioFormat(String filePath) {
    return _service!.isSupportedAudioFormat(filePath);
  }

  /// 格式化时长（秒 -> MM:SS）
  String formatDuration(int seconds) {
    return _service!.formatDuration(seconds);
  }
}

// ==================== Providers ====================

/// MetadataService Provider
@riverpod
MetadataService metadataService(Ref ref) {
  return MetadataService();
}
