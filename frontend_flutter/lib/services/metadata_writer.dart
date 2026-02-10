import 'dart:io';
import 'package:metadata_god/metadata_god.dart';
import '../core/utils/app_logger.dart';

/// 音频元数据
class AudioMetadata {
  final String title;
  final String artist;
  final String? album;
  final File? coverFile;

  AudioMetadata({
    required this.title,
    required this.artist,
    this.album,
    this.coverFile,
  });
}

/// 元数据写入结果
class MetadataWriteResult {
  final bool success;
  final String? error;

  MetadataWriteResult({
    required this.success,
    this.error,
  });
}

/// 使用 metadata_god 写入音频元数据
///
/// 功能：
/// 1. 写入标题、艺术家、专辑等文本元数据
/// 2. 嵌入封面图片
/// 3. 支持 M4A/MP3 格式
class MetadataWriter {
  static bool _initialized = false;

  /// 初始化 metadata_god
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      MetadataGod.initialize();  // 返回 void，不需要 await
      _initialized = true;
      AppLogger.info('MetadataWriter', 'metadata_god 初始化完成');
    }
  }

  /// 写入元数据到音频文件
  ///
  /// [filePath] 音频文件路径
  /// [metadata] 元数据
  static Future<MetadataWriteResult> writeMetadata({
    required String filePath,
    required AudioMetadata metadata,
  }) async {
    try {
      await ensureInitialized();

      AppLogger.info('MetadataWriter', '开始写入元数据: $filePath');

      // 构建封面对象
      Picture? picture;
      if (metadata.coverFile != null) {
        if (await metadata.coverFile!.exists()) {
          final imageData = await metadata.coverFile!.readAsBytes();
          picture = Picture(
            data: imageData,
            mimeType: 'image/jpeg',
          );
          AppLogger.info('MetadataWriter', '封面图片大小: ${imageData.length} bytes');
        }
      }

      // 写入元数据（使用 metadata_god 1.0+ API）
      await MetadataGod.writeMetadata(
        file: filePath,
        metadata: Metadata(
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album ?? 'Bilibili',
          picture: picture,
        ),
      );

      AppLogger.info('MetadataWriter', '元数据写入成功');

      return MetadataWriteResult(success: true);
    } catch (e) {
      AppLogger.error('MetadataWriter', '元数据写入失败: $e');
      return MetadataWriteResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 读取音频文件元数据
  static Future<Metadata?> readMetadata(String filePath) async {
    try {
      await ensureInitialized();
      return await MetadataGod.readMetadata(file: filePath);
    } catch (e) {
      AppLogger.error('MetadataWriter', '读取元数据失败: $e');
      return null;
    }
  }
}
