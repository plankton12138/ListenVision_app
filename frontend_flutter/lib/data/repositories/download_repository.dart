import 'dart:io';

import '../../core/utils/app_logger.dart';
import '../api/bilibili_api_client.dart';

/// 下载仓库
///
/// 负责音频下载相关的数据操作
class DownloadRepository {
  final BilibiliApiClient _bilibiliApi;

  DownloadRepository({BilibiliApiClient? bilibiliApi})
      : _bilibiliApi = bilibiliApi ?? BilibiliApiClient();

  // ==================== 下载操作 ====================

  /// 获取下载URL
  String getDownloadUrl(String bvid, {String format = 'mp3'}) {
    return _bilibiliApi.getDownloadUrl(bvid, format: format);
  }

  /// 下载音频文件
  Future<File> downloadAudio({
    required String bvid,
    required String savePath,
    String format = 'mp3',
    void Function(int percent, String stage, String message)? onProgress,
  }) async {
    try {
      AppLogger.info('DownloadRepository', '开始下载: $bvid -> $savePath');

      await _bilibiliApi.downloadAudio(
        bvid: bvid,
        savePath: savePath,
        format: format,
        onProgress: onProgress,
      );

      final file = File(savePath);
      if (await file.exists()) {
        AppLogger.info('DownloadRepository', '下载完成: $savePath');
        return file;
      } else {
        throw Exception('下载文件不存在');
      }
    } catch (e) {
      AppLogger.error('DownloadRepository', '下载失败: $e');
      rethrow;
    }
  }

  /// 获取音频代理URL（用于流式播放）
  String getProxyAudioUrl(String originalUrl) {
    return _bilibiliApi.getProxyAudioUrl(originalUrl);
  }

  /// 获取图片代理URL
  String getProxyImageUrl(String originalUrl) {
    return _bilibiliApi.getProxyImageUrl(originalUrl);
  }
}
