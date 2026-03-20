import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:listenvision/core/utils/audio_metadata_helper.dart';
import 'package:listenvision/core/utils/app_logger.dart';

/// 元数据写入器
///
/// 职责：
/// - 下载封面图片
/// - 写入音频元数据（标题、艺术家、封面等）
///
/// 使用 AudioMetadataHelper 封装层（基于 audio_metadata_reader）
class MetadataWriter {
  /// 是否使用后端代理获取封面
  final bool useProxy;

  MetadataWriter({
    this.useProxy = true,
  });

  /// 写入元数据到音频文件
  ///
  /// [filePath] 音频文件路径
  /// [title] 标题
  /// [artist] 艺术家
  /// [coverUrl] 封面图片URL
  /// [album] 专辑名称（可选）
  Future<bool> writeMetadata({
    required String filePath,
    required String title,
    required String artist,
    String? coverUrl,
    String? album,
  }) async {
    AppLogger.info('MetadataWriter', '开始写入元数据: $filePath');

    try {
      // 1. 下载封面图片
      Uint8List? imageBytes;
      if (coverUrl != null && coverUrl.isNotEmpty) {
        imageBytes = await _downloadCover(coverUrl);
      }

      // 2. 使用 AudioMetadataHelper 写入元数据
      final helper = AudioMetadataHelper();
      final success = helper.writeMetadata(
        filePath: filePath,
        params: AudioMetadataWriteParams(
          title: title,
          artist: artist,
          album: album,
          cover: imageBytes,
        ),
      );

      if (success) {
        AppLogger.info('MetadataWriter', '元数据写入成功');
      } else {
        AppLogger.error('MetadataWriter', '元数据写入失败');
      }

      return success;
    } catch (e) {
      AppLogger.error('MetadataWriter', '元数据写入失败: $e');
      return false;
    }
  }

  /// 下载封面图片
  Future<Uint8List?> _downloadCover(String url) async {
    try {
      AppLogger.debug('MetadataWriter', '下载封面: $url');

      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com/',
          },
        ),
      );

      if (response.data is List<int>) {
        return Uint8List.fromList(response.data as List<int>);
      }

      return response.data as Uint8List?;
    } catch (e) {
      AppLogger.error('MetadataWriter', '封面下载失败: $e');
      return null;
    }
  }

  /// 批量写入元数据
  ///
  /// [items] 要处理的文件列表
  /// 返回成功数量
  Future<int> writeBatch(List<MetadataItem> items) async {
    int successCount = 0;

    for (var item in items) {
      final result = await writeMetadata(
        filePath: item.filePath,
        title: item.title,
        artist: item.artist,
        coverUrl: item.coverUrl,
        album: item.album,
      );
      if (result) successCount++;
    }

    AppLogger.info('MetadataWriter', '批量写入完成: $successCount/${items.length}');
    return successCount;
  }
}

/// 元数据项
class MetadataItem {
  final String filePath;
  final String title;
  final String artist;
  final String? coverUrl;
  final String? album;

  MetadataItem({
    required this.filePath,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.album,
  });
}

/// 读取音频文件元数据
///
/// 使用 AudioMetadataHelper 封装层读取
Future<Map<String, dynamic>?> readMetadata(String filePath) async {
  try {
    final helper = AudioMetadataHelper();
    final result = await helper.readMetadataAsync(filePath: filePath, fetchCover: false);

    return {
      'title': result.title,
      'artist': result.artist,
      'album': result.album,
      'hasPicture': result.cover != null,
    };
  } catch (e) {
    AppLogger.error('MetadataWriter', '读取元数据失败: $e');
    return null;
  }
}
