import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:demo/data/datasources/remote/bilibili_api_datasource.dart';

/// 元数据写入器
///
/// 职责：
/// - 下载封面图片
/// - 写入音频元数据（标题、艺术家、封面等）
class MetadataWriter {
  BilibiliApiService? _bilibiliService;

  /// 是否使用后端代理获取封面
  final bool useProxy;

  MetadataWriter({
    BilibiliApiService? bilibiliService,
    this.useProxy = true,
  }) : _bilibiliService = bilibiliService;

  /// 设置 BilibiliApiService
  void setBilibiliApiService(BilibiliApiService service) {
    _bilibiliService = service;
  }

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
    debugPrint('【MetadataWriter】开始写入元数据: $filePath');

    try {
      // 1. 下载封面图片
      Uint8List? imageBytes;
      if (coverUrl != null && coverUrl.isNotEmpty) {
        imageBytes = await _downloadCover(coverUrl);
      }

      // 2. 构建元数据对象
      final metadata = Metadata(
        title: title,
        artist: artist,
        album: album,
        picture: imageBytes != null
            ? Picture(data: imageBytes, mimeType: 'image/jpeg')
            : null,
      );

      // 3. 写入元数据
      await MetadataGod.writeMetadata(
        file: filePath,
        metadata: metadata,
      );

      debugPrint('【MetadataWriter】元数据写入成功');
      return true;
    } catch (e) {
      debugPrint('【MetadataWriter】元数据写入失败: $e');
      return false;
    }
  }

  /// 下载封面图片
  Future<Uint8List?> _downloadCover(String url) async {
    try {
      String finalUrl = url;

      // 如果使用代理且后端服务可用
      if (useProxy && _bilibiliService != null) {
        finalUrl = _bilibiliService!.getProxyImageUrl(url);
      }

      debugPrint('【MetadataWriter】下载封面: $finalUrl');

      final dio = Dio();
      final response = await dio.get(
        finalUrl,
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
      debugPrint('【MetadataWriter】封面下载失败: $e');
      return null;
    }
  }

  /// 从 BVID 获取信息并写入元数据
  ///
  /// 当下载时没有完整信息时，可以通过 BVID 重新获取
  Future<bool> writeMetadataByBvid({
    required String filePath,
    required String bvid,
  }) async {
    if (_bilibiliService == null) {
      debugPrint('【MetadataWriter】BilibiliApiService 未设置，无法获取信息');
      return false;
    }

    try {
      debugPrint('【MetadataWriter】通过 BVID 获取信息: $bvid');

      // 获取视频信息
      final videoInfo = await _bilibiliService!.getVideoInfo(bvid);

      final title = videoInfo['title'] ?? '未知标题';
      final artist = videoInfo['owner']?['name'] ?? '未知艺术家';
      final coverUrl = videoInfo['pic'];
      final bvidUrl = 'https://www.bilibili.com/video/$bvid';

      return await writeMetadata(
        filePath: filePath,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        album: bvidUrl,
      );
    } catch (e) {
      debugPrint('【MetadataWriter】通过 BVID 写入元数据失败: $e');
      return false;
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

    debugPrint('【MetadataWriter】批量写入完成: $successCount/${items.length}');
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
Future<Map<String, dynamic>?> readMetadata(String filePath) async {
  try {
    final metadata = await MetadataGod.readMetadata(file: filePath);

    return {
      'title': metadata.title,
      'artist': metadata.artist,
      'album': metadata.album,
      'hasPicture': metadata.picture != null,
    };
  } catch (e) {
    debugPrint('【MetadataWriter】读取元数据失败: $e');
    return null;
  }
}
