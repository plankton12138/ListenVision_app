import 'package:demo/data/datasources/remote/bilibili_api_datasource.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';

/// B站视频信息缓存管理Provider
///
/// 职责：
/// - 视频信息缓存管理
/// - 批量元数据获取
/// - 缓存统计和清理
class BilibiliCacheProvider extends ChangeNotifier {
  BilibiliApiService? _apiService;
  String? _token;

  // ==================== 状态变量 ====================

  /// 视频信息缓存 (bvid -> info)
  final Map<String, Map<String, dynamic>> _videoInfoCache = {};

  /// 缓存配置
  static const Duration _cacheTTL = Duration(hours: 24);
  static const int _maxCacheSize = 50;

  /// 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get cacheSize => _videoInfoCache.length;

  // ==================== 初始化 ====================

  /// 更新认证Token
  void updateToken(String? token) {
    _token = token;
    _apiService = BilibiliApiService();
    AppLogger.debug('BilibiliCacheProvider', 'Token updated: ${token != null ? "set" : "cleared"}');
  }

  // ==================== 视频信息缓存 ====================

  /// 获取视频信息（带缓存）
  Future<Map<String, dynamic>?> getVideoInfo(String bvid) async {
    // 检查缓存
    if (_videoInfoCache.containsKey(bvid)) {
      final cached = _videoInfoCache[bvid]!;
      final cachedTime = DateTime.parse(cached['cachedAt'] ?? '');
      if (DateTime.now().difference(cachedTime) < _cacheTTL) {
        AppLogger.debug('BilibiliCacheProvider', 'Video info from cache: $bvid');
        return cached;
      }
      // 缓存过期，删除
      _videoInfoCache.remove(bvid);
    }

    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      return null;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final info = await _apiService!.getVideoInfo(bvid);
      info['cachedAt'] = DateTime.now().toIso8601String();
      _videoInfoCache[bvid] = info;

      // 限制缓存大小
      _trimCache();

      AppLogger.info('BilibiliCacheProvider', 'Video info loaded: $bvid');
      return info;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliCacheProvider', 'Get video info error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 批量获取视频元数据
  Future<Map<String, Map<String, dynamic>>> getBatchMetadata(List<String> bvids) async {
    if (_apiService == null) {
      AppLogger.debug('BilibiliCacheProvider', 'ApiService not initialized');
      return {};
    }

    try {
      return await _apiService!.getBatchMetadata(bvids);
    } catch (e) {
      AppLogger.error('BilibiliCacheProvider', 'Batch metadata error: $e');
      return {};
    }
  }

  /// 获取音频流URL
  Future<Map<String, dynamic>?> getAudioStream(String bvid) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      return null;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final stream = await _apiService!.getAudioStream(bvid);
      return stream;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliCacheProvider', 'Get audio stream error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取缓存的音频元数据
  Future<Map<String, dynamic>?> getAudioMetadata(String bvid) async {
    if (_apiService == null) {
      AppLogger.debug('BilibiliCacheProvider', 'ApiService not initialized');
      return null;
    }

    try {
      return await _apiService!.getAudioMetadata(bvid);
    } catch (e) {
      AppLogger.error('BilibiliCacheProvider', 'Get audio metadata error: $e');
      return null;
    }
  }

  /// 刷新音频元数据缓存
  Future<bool> refreshAudioMetadata(String bvid) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _apiService!.refreshAudioMetadata(bvid);

      // 清除本地缓存
      _videoInfoCache.remove(bvid);

      AppLogger.debug('BilibiliCacheProvider', 'Audio metadata refreshed: $bvid');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliCacheProvider', 'Refresh metadata error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_apiService == null) {
      return {
        'count': _videoInfoCache.length,
        'totalSize': 0,
      };
    }

    try {
      final stats = await _apiService!.getCacheStats();
      return stats;
    } catch (e) {
      AppLogger.error('BilibiliCacheProvider', 'Get cache stats error: $e');
      return {
        'count': _videoInfoCache.length,
        'totalSize': 0,
      };
    }
  }

  /// 清理过期的本地缓存
  void cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _videoInfoCache.forEach((bvid, info) {
      final cachedTime = DateTime.parse(info['cachedAt'] ?? '');
      if (now.difference(cachedTime) >= _cacheTTL) {
        expiredKeys.add(bvid);
      }
    });

    for (final key in expiredKeys) {
      _videoInfoCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug('BilibiliCacheProvider', 'Cleaned ${expiredKeys.length} expired cache entries');
      notifyListeners();
    }
  }

  /// 清空本地缓存
  void clearCache() {
    _videoInfoCache.clear();
    AppLogger.debug('BilibiliCacheProvider', 'Cache cleared');
    notifyListeners();
  }

  /// 修剪缓存大小
  void _trimCache() {
    if (_videoInfoCache.length <= _maxCacheSize) return;

    // 按缓存时间排序，删除最旧的
    final entries = _videoInfoCache.entries.toList()
      ..sort((a, b) {
        final aTime = DateTime.parse(a.value['cachedAt'] ?? '');
        final bTime = DateTime.parse(b.value['cachedAt'] ?? '');
        return aTime.compareTo(bTime);
      });

    final toRemove = entries.length - _maxCacheSize;
    for (int i = 0; i < toRemove; i++) {
      _videoInfoCache.remove(entries[i].key);
    }

    AppLogger.debug('BilibiliCacheProvider', 'Trimmed cache: removed $toRemove entries');
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    _videoInfoCache.clear();
    super.dispose();
  }
}
