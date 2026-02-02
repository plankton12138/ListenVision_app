import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:demo/core/constants/api_constants.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:demo/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放历史记录 Provider
///
/// 职责：
/// 1. 记录播放开始
/// 2. 更新播放进度
/// 3. 与后端同步历史记录
class PlayHistoryProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.fullBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));

  String? _token;

  PlayHistoryProvider() {
    _loadToken();
  }

  /// 从本地存储加载认证 token
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(StorageKeys.keyToken);
    } catch (e) {
      AppLogger.error('PlayHistoryProvider', '加载 token 失败: $e');
    }
  }

  /// 记录播放开始
  ///
  /// 参数：
  /// - [bvid]: 在线音频的 BVID
  /// - [localPath]: 本地音频的文件路径
  /// - [title]: 音频标题
  /// - [artist]: 艺术家名称（可选）
  /// - [duration]: 音频时长（可选）
  /// - [coverUrl]: 封面 URL（可选）
  Future<void> recordStart({
    String? bvid,
    String? localPath,
    required String title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    if (_token == null || _token!.isEmpty) return;
    if (bvid == null && localPath == null) return;

    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _dio.post(
        '/history',
        data: {
          if (bvid != null) 'bvid': bvid,
          if (localPath != null) 'localPath': localPath,
          'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          if (coverUrl != null) 'coverUrl': coverUrl,
          'progress': 0,
        },
      );
      AppLogger.debug('PlayHistoryProvider', '记录播放开始: $title');
    } catch (e) {
      // 静默失败，不影响播放
      AppLogger.debug('PlayHistoryProvider', '记录播放失败: $e');
    }
  }

  /// 更新播放进度
  ///
  /// 参数：
  /// - [bvid]: 在线音频的 BVID
  /// - [localPath]: 本地音频的文件路径
  /// - [title]: 音频标题
  /// - [artist]: 艺术家名称（可选）
  /// - [duration]: 音频时长（可选）
  /// - [progress]: 播放进度（秒）
  Future<void> updateProgress({
    String? bvid,
    String? localPath,
    required String title,
    String? artist,
    int? duration,
    int progress = 0,
  }) async {
    if (_token == null || _token!.isEmpty) return;

    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _dio.put(
        '/history/progress',
        data: {
          if (bvid != null) 'bvid': bvid,
          if (localPath != null) 'localPath': localPath,
          'title': title,
          if (artist != null) 'artist': artist,
          if (duration != null) 'duration': duration,
          'progress': progress,
        },
      );
      AppLogger.debug('PlayHistoryProvider', '更新播放进度: $title ($progress 秒)');
    } catch (e) {
      AppLogger.debug('PlayHistoryProvider', '更新进度失败: $e');
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}
