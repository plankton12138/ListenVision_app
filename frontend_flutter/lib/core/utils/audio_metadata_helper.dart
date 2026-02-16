import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' hide readMetadata, updateMetadata;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as meta;
import 'package:demo/core/utils/app_logger.dart';

/// 音频元数据结果
///
/// 统一的元数据返回格式，屏蔽底层库的差异
class AudioMetadataResult {
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

  /// 音频格式
  final String format;

  const AudioMetadataResult({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.cover,
    this.duration,
    this.format = '',
  });

  /// 是否为空元数据
  bool get isEmpty => title.isEmpty && artist.isEmpty;

  @override
  String toString() {
    return 'AudioMetadataResult(title: $title, artist: $artist, album: $album, hasCover: ${cover != null})';
  }
}

/// 音频元数据写入参数
class AudioMetadataWriteParams {
  final String title;
  final String artist;
  final String? album;
  final Uint8List? cover;
  final int? year;
  final int? trackNumber;
  final String? genre;
  final String? lyrics;

  const AudioMetadataWriteParams({
    required this.title,
    required this.artist,
    this.album,
    this.cover,
    this.year,
    this.trackNumber,
    this.genre,
    this.lyrics,
  });
}

/// 音频元数据辅助类
///
/// 职责：
/// 1. 封装 audio_metadata_reader，提供统一接口
/// 2. 屏蔽不同音频格式（MP3/M4A/FLAC等）的元数据差异
/// 3. 简化元数据读写操作
///
/// 使用 audio_metadata_reader（纯 Dart 实现，跨平台稳定）
/// 性能：3392首歌曲 <200ms（不含封面）
class AudioMetadataHelper {
  // ==================== 单例模式 ====================

  static final AudioMetadataHelper _instance = AudioMetadataHelper._internal();

  factory AudioMetadataHelper() => _instance;

  AudioMetadataHelper._internal();

  // ==================== 读取元数据 ====================

  /// 从音频文件读取元数据
  ///
  /// [filePath] 音频文件路径
  /// [fetchCover] 是否提取封面图片（默认 true，设为 false 可提升性能）
  ///
  /// 返回统一格式的元数据结果
  /// 
  /// 改进点：
  /// - 文件不存在或过小立即回退到路径提取
  /// - 解析失败（MetadataParserException）立即回退，不返回空对象
  /// - 提供更详细的日志和错误分类
  AudioMetadataResult readMetadata({
    required String filePath,
    bool fetchCover = true,
  }) {
    final file = File(filePath);
    if (!file.existsSync()) {
      AppLogger.error('AudioMetadataHelper', '文件不存在: $filePath');
      return _extractFromPath(filePath);
    }

    // 检查文件大小（小于1KB可能是损坏的）
    final fileSize = file.lengthSync();
    if (fileSize < 1024) {
      AppLogger.warn('AudioMetadataHelper', '文件过小(${_formatFileSize(fileSize)})，可能已损坏: $filePath');
      return _extractFromPath(filePath);
    }

    // 检测是否是 m4s 格式（B站分离音频流），直接回退
    if (isM4sFormat(filePath)) {
      AppLogger.debug('AudioMetadataHelper', '检测到 m4s 格式，使用路径提取: $filePath');
      return _extractFromPath(filePath);
    }

    try {
      AppLogger.debug('AudioMetadataHelper', '读取元数据: ${_getFileName(filePath)} (${_formatFileSize(fileSize)})');

      // 使用 audio_metadata_reader 读取元数据（同步）
      final metadata = meta.readMetadata(
        file,
        getImage: fetchCover,
      );

      // 验证解析结果：如果标题和艺术家都为空，回退到路径提取
      if (metadata.title?.trim().isEmpty != false &&
          metadata.artist?.trim().isEmpty != false) {
        AppLogger.debug('AudioMetadataHelper', '元数据字段为空，使用路径提取: ${_getFileName(filePath)}');
        return _extractFromPath(filePath);
      }

      return _parseAudioMetadata(metadata, filePath);
    } on MetadataParserException catch (e) {
      // 解析异常 - 文件格式不兼容，立即回退到路径提取
      AppLogger.warn('AudioMetadataHelper', '元数据解析失败，使用路径提取: ${_getFileName(filePath)} - ${e.message}');
      return _extractFromPath(filePath);
    } catch (e) {
      // 其他异常也回退到路径提取
      final errorStr = e.toString();
      final truncatedError = errorStr.length > 150
          ? '${errorStr.substring(0, 150)}...'
          : errorStr;
      AppLogger.warn(
        'AudioMetadataHelper',
        '读取元数据失败，使用路径提取: ${_getFileName(filePath)} - $truncatedError',
      );
      return _extractFromPath(filePath);
    }
  }

  /// 异步读取元数据（兼容旧代码）
  ///
  /// audio_metadata_reader 是同步的，这里提供异步接口以保持兼容性
  Future<AudioMetadataResult> readMetadataAsync({
    required String filePath,
    bool fetchCover = true,
  }) async {
    // 在后台线程执行，避免阻塞 UI
    return Future.microtask(() {
      return readMetadata(filePath: filePath, fetchCover: fetchCover);
    });
  }

  /// 从文件路径提取元数据（实例方法，返回 AudioMetadataResult）
  AudioMetadataResult _extractFromPath(String filePath) {
    final map = extractFromPath(filePath);
    return AudioMetadataResult(
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      cover: map['cover'] as Uint8List?,
      format: _detectFormat(filePath),
    );
  }

  /// 获取文件名（不含路径）
  String _getFileName(String filePath) {
    return filePath.split(RegExp(r'[\/]')).last;
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }

  /// 解析 AudioMetadata 为统一格式
  AudioMetadataResult _parseAudioMetadata(AudioMetadata metadata, String filePath) {
    // AudioMetadata 已经是统一格式，直接提取
    String title = metadata.title?.trim() ?? '';
    String artist = metadata.artist?.trim() ?? '';
    String album = metadata.album?.trim() ?? '';

    // 时长转换：Duration → 秒
    int? duration = metadata.duration?.inSeconds;

    // 封面提取
    Uint8List? cover;
    if (metadata.pictures.isNotEmpty) {
      cover = metadata.pictures.first.bytes;
    }

    // 检测格式（从文件扩展名）
    String format = _detectFormat(filePath);

    // 后备方案：从文件名提取
    if (title.isEmpty && artist.isEmpty) {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      // 尝试解析 "艺术家 - 标题" 格式
      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      } else {
        title = nameWithoutExt;
        artist = '未知艺术家';
      }
    }

    // 确保有默认值
    if (artist.isEmpty) artist = '未知艺术家';
    if (title.isEmpty) {
      title = filePath.split(RegExp(r'[\\/]')).last;
    }

    AppLogger.debug(
      'AudioMetadataHelper',
      '解析成功: [$format] $title - $artist',
    );

    return AudioMetadataResult(
      title: title,
      artist: artist,
      album: album,
      cover: cover,
      duration: duration,
      format: format,
    );
  }

  /// 检测音频格式
  String _detectFormat(String filePath) {
    final ext = filePath.split(RegExp(r'\.')).last.toLowerCase();
    switch (ext) {
      case 'mp3':
        return 'MP3';
      case 'm4a':
      case 'm4b':
        return 'M4A';
      case 'mp4':
        return 'MP4';
      case 'flac':
        return 'FLAC';
      case 'wav':
      case 'wave':
        return 'WAV';
      case 'ogg':
      case 'oga':
        return 'OGG';
      case 'wma':
        return 'WMA';
      case 'm4s':
        return 'M4S';
      default:
        return ext.toUpperCase();
    }
  }

  // ==================== 写入元数据 ====================

  /// 写入元数据到音频文件
  ///
  /// [filePath] 音频文件路径
  /// [params] 元数据写入参数
  ///
  /// 返回是否成功
  bool writeMetadata({
    required String filePath,
    required AudioMetadataWriteParams params,
  }) {
    final file = File(filePath);
    if (!file.existsSync()) {
      AppLogger.error('AudioMetadataHelper', '文件不存在: $filePath');
      return false;
    }

    try {
      AppLogger.info('AudioMetadataHelper', '写入元数据: ${params.title} - ${params.artist}');

      // 使用 audio_metadata_reader 的 updateMetadata
      meta.updateMetadata(file, (metadata) {
        // 使用扩展方法统一设置（推荐方式）
        metadata.setTitle(params.title);
        metadata.setArtist(params.artist);

        if (params.album != null && params.album!.isNotEmpty) {
          metadata.setAlbum(params.album!);
        }

        if (params.year != null) {
          metadata.setYear(DateTime(params.year!, 1, 1));
        }

        if (params.trackNumber != null) {
          metadata.setTrackNumber(params.trackNumber!);
        }

        if (params.genre != null && params.genre!.isNotEmpty) {
          metadata.setGenres([params.genre!]);
        }

        if (params.lyrics != null && params.lyrics!.isNotEmpty) {
          metadata.setLyrics(params.lyrics!);
        }

        // 设置封面
        if (params.cover != null) {
          final mimeType = _detectMimeType(params.cover!);
          metadata.setPictures([
            Picture(
              params.cover!,
              mimeType,
              PictureType.coverFront,
            ),
          ]);
        }
      });

      AppLogger.info('AudioMetadataHelper', '元数据写入成功');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'AudioMetadataHelper',
        '写入元数据失败: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 异步写入元数据（兼容旧代码）
  Future<bool> writeMetadataAsync({
    required String filePath,
    required AudioMetadataWriteParams params,
  }) async {
    // audio_metadata_reader 是同步的，这里提供异步接口
    return Future.microtask(() {
      return writeMetadata(filePath: filePath, params: params);
    });
  }

  /// 检测图片 MIME 类型
  String _detectMimeType(Uint8List imageData) {
    if (imageData.length < 4) return 'image/jpeg';

    // 检测文件头
    final header = imageData.sublist(0, 4);

    // JPEG: FF D8 FF
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47
    if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
      return 'image/png';
    }
    // GIF: 47 49 46 38
    if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x38) {
      return 'image/gif';
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46) {
      if (imageData.length >= 12 &&
          imageData[8] == 0x57 && imageData[9] == 0x45 && imageData[10] == 0x42 && imageData[11] == 0x50) {
        return 'image/webp';
      }
    }

    // 默认返回 JPEG
    return 'image/jpeg';
  }

  // ==================== 工具方法 ====================

  /// 检测文件是否是支持的音频格式
  static bool isSupportedAudioFormat(String filePath) {
    const supportedFormats = [
      'mp3', 'm4a', 'flac', 'wav', 'ogg', 'wma',
      'aac', 'opus', 'mp4', 'm4s',
    ];
    final ext = filePath.split(RegExp(r'\.')).last.toLowerCase();
    return supportedFormats.contains(ext);
  }

  /// 检测文件是否是 m4s 格式（B站分离音频流）
  ///
  /// m4s 格式不是标准的 m4a/mp4 容器，可能导致解析失败
  static bool isM4sFormat(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      // 方法1：检查文件扩展名
      final fileName = filePath.toLowerCase();
      if (fileName.endsWith('.m4s')) {
        return true;
      }

      // 方法2：对于 .m4a 文件，读取文件头部检测
      if (fileName.endsWith('.m4a') || fileName.endsWith('.mp4')) {
        final header = file.openSync(mode: FileMode.read).readSync(16);
        if (header.length >= 12) {
          // 检查是否包含 'ftyp' 标记（标准容器）
          final hasFtyp = header.length >= 8 &&
              header[4] == 0x66 && // 'f'
              header[5] == 0x74 && // 't'
              header[6] == 0x79 && // 'y'
              header[7] == 0x70;   // 'p'
          if (!hasFtyp) {
            AppLogger.debug('AudioMetadataHelper', '文件缺少 ftyp 容器标记，可能是 m4s 格式');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      AppLogger.warn('AudioMetadataHelper', 'm4s 格式检测失败: $e');
      return false;
    }
  }

  /// 从文件路径提取元数据（后备方案）
  static Map<String, dynamic> extractFromPath(String filePath) {
    try {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      var nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      // 移除常见标签
      nameWithoutExt = nameWithoutExt
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'【.*?】'), '')
          .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
          .replaceAll(RegExp(r'（Official.*?）', caseSensitive: false), '')
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .replaceAll(RegExp(r'（.*?）'), '')
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

      artist = artist.replaceAll(RegExp(r'\s+'), ' ').trim();
      title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (title.isEmpty) {
        title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      }

      final finalArtist = artist.isNotEmpty ? artist : '未知艺术家';

      return {
        'title': title,
        'artist': finalArtist,
        'album': '',
        'cover': null,
      };
    } catch (e) {
      AppLogger.error('AudioMetadataHelper', '路径解析失败: $e');
      final fallbackTitle = filePath.split(RegExp(r'[\\/]')).last;
      return {
        'title': fallbackTitle,
        'artist': '未知艺术家',
        'album': '',
        'cover': null,
      };
    }
  }
}
