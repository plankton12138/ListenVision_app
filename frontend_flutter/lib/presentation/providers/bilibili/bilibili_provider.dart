import 'dart:async';
import 'package:demo/domain/entities/platform_account.dart';
import 'package:demo/data/datasources/remote/bilibili_api_datasource.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';

/// B站相关状态管理Provider
///
/// 职责：
/// 1. B站账号绑定管理
/// 2. QR码登录流程
/// 3. 搜索结果和搜索历史
/// 4. 视频信息缓存
class BilibiliProvider with ChangeNotifier {
  BilibiliApiService? _apiService;
  String? _token;

  // ==================== 状态变量 ====================

  /// B站账号绑定状态
  bool _isBound = false;
  BilibiliUserInfo? _boundUserInfo;

  /// QR码登录状态
  String _qrLoginStatus = 'none'; // none|pending|scanned|success|expired
  String? _qrcodeKey;
  String? _qrcodeUrl;
  DateTime? _qrExpiresAt;
  Timer? _qrPollTimer;

  /// 搜索状态
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  String? _searchError;

  /// 视频信息缓存 (bvid -> info)
  final Map<String, Map<String, dynamic>> _videoInfoCache = {};

  /// 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================

  bool get isBound => _isBound;
  BilibiliUserInfo? get boundUserInfo => _boundUserInfo;
  String get qrLoginStatus => _qrLoginStatus;
  String? get qrcodeKey => _qrcodeKey;
  String? get qrcodeUrl => _qrcodeUrl;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// QR码是否有效（未过期）
  bool get isQrValid => _qrExpiresAt != null && DateTime.now().isBefore(_qrExpiresAt!);

  // ==================== 初始化 ====================

  /// 更新认证Token（由AuthProvider调用）
  void updateToken(String? token) {
    _token = token;
    _apiService = BilibiliApiService();
    AppLogger.debug('BilibiliProvider', 'Token updated: ${token != null ? "set" : "cleared"}');
  }

  /// 初始化：检查绑定状态
  Future<void> initialize() async {
    if (_token == null) {
      AppLogger.debug('BilibiliProvider', 'No token, skip initialization');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final status = await _apiService!.getBindStatus();
      _isBound = status['isBound'] ?? false;
      if (_isBound && status['userInfo'] != null) {
        _boundUserInfo = BilibiliUserInfo.fromJson(status['userInfo']);
      }

      // 加载搜索历史
      _searchHistory = await _apiService!.getRecentSearches(limit: 10);

      AppLogger.debug('BilibiliProvider', 'Initialized: bound=$_isBound');
    } catch (e) {
      AppLogger.error('BilibiliProvider', 'Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 确保初始化完成（如果尚未初始化则自动初始化）
  ///
  /// 用于页面加载时确保绑定状态已获取
  Future<void> ensureInitialized() async {
    // 如果已经有 token 但尚未检查绑定状态，则执行初始化
    if (_token != null && !_isLoading && _searchHistory.isEmpty) {
      AppLogger.debug('BilibiliProvider', 'Ensuring initialization...');
      await initialize();
    }
  }

  // ==================== QR码登录 ====================

  /// 开始QR码登录流程
  Future<bool> startQRLogin() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getQRCode();
      _qrcodeKey = result['qrcodeKey'];
      _qrcodeUrl = result['qrcodeUrl'];
      _qrExpiresAt = result['expiresAt'];
      _qrLoginStatus = 'pending';

      // 开始轮询
      _startQRPolling();

      AppLogger.info('BilibiliProvider', 'QR login started');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'QR login start error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 开始轮询QR码状态
  void _startQRPolling() {
    _stopQRPolling();
    _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // 确保当前 timer 是最新创建的，防止旧 timer 继续执行
      if (_qrPollTimer == null || timer != _qrPollTimer) {
        timer.cancel();
        return;
      }

      if (!isQrValid) {
        _qrLoginStatus = 'expired';
        _stopQRPolling();
        notifyListeners();
        return;
      }

      try {
        await _checkQRStatus();
      } catch (e) {
        AppLogger.error('BilibiliProvider', 'QR polling error: $e');
      }
    });
  }

  /// 停止轮询
  void _stopQRPolling() {
    _qrPollTimer?.cancel();
    _qrPollTimer = null;
  }

  /// 检查QR码状态
  Future<void> _checkQRStatus() async {
    if (_qrcodeKey == null) return;

    try {
      final result = await _apiService!.checkQRLoginStatus(_qrcodeKey!);
      _qrLoginStatus = result['status'] ?? 'pending';

      if (_qrLoginStatus == 'success') {
        _stopQRPolling();
        _isBound = true;
        if (result['userInfo'] != null) {
          _boundUserInfo = BilibiliUserInfo.fromJson(result['userInfo']);
        }
        // 重新初始化以获取最新状态
        await initialize();
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('BilibiliProvider', 'QR check error: $e');
    }
  }

  /// 取消QR码登录
  void cancelQRLogin() {
    _stopQRPolling();
    _qrLoginStatus = 'none';
    _qrcodeKey = null;
    _qrcodeUrl = null;
    _qrExpiresAt = null;
    notifyListeners();
  }

  // ==================== 账号绑定 ====================

  /// 解绑B站账号
  Future<bool> unbindAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService!.unbindAccount();
      _isBound = false;
      _boundUserInfo = null;

      AppLogger.debug('BilibiliProvider', 'Account unbound');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Unbind error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 搜索 ====================

  /// 搜索B站视频
  Future<bool> searchBilibili(String keyword, {int page = 1}) async {
    if (keyword.trim().isEmpty) return false;

    if (_apiService == null) {
      _searchError = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isSearching = true;
      _searchError = null;
      notifyListeners();

      final result = await _apiService!.searchBilibili(
        keyword,
        page: page,
        pageSize: 20,
      );

      // 始终替换结果（分页模式）
      _searchResults = List<Map<String, dynamic>>.from(
        result['videos'] ?? [],
      );

      // 只在第一页时添加到搜索历史
      if (page == 1 && !_searchHistory.contains(keyword)) {
        _searchHistory.insert(0, keyword);
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.sublist(0, 10);
        }
      }

      // 更新搜索历史（从服务器获取）
      _searchHistory = await _apiService!.getRecentSearches(limit: 10);

      AppLogger.debug('BilibiliProvider', 'Search found ${_searchResults.length} results');
      return true;
    } catch (e) {
      _searchError = e.toString();
      AppLogger.error('BilibiliProvider', 'Search error: $e');
      return false;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 清空搜索结果
  void clearSearchResults() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  /// 从搜索历史中删除关键词
  void removeFromSearchHistory(String keyword) {
    _searchHistory.remove(keyword);
    notifyListeners();
  }

  /// 清空搜索历史
  void clearSearchHistory() {
    _searchHistory = [];
    notifyListeners();
  }

  // ==================== 视频信息 ====================

  /// 获取视频信息（带缓存）
  Future<Map<String, dynamic>?> getVideoInfo(String bvid) async {
    // 检查缓存
    if (_videoInfoCache.containsKey(bvid)) {
      final cached = _videoInfoCache[bvid]!;
      final cachedTime = DateTime.parse(cached['cachedAt'] ?? '');
      if (DateTime.now().difference(cachedTime).inHours < 24) {
        AppLogger.debug('BilibiliProvider', 'Video info from cache: $bvid');
        return cached;
      }
    }

    try {
      _isLoading = true;
      notifyListeners();

      final info = await _apiService!.getVideoInfo(bvid);
      info['cachedAt'] = DateTime.now().toIso8601String();
      _videoInfoCache[bvid] = info;

      // 限制缓存大小
      if (_videoInfoCache.length > 50) {
        final oldestKey = _videoInfoCache.keys.first;
        _videoInfoCache.remove(oldestKey);
      }

      AppLogger.info('BilibiliProvider', 'Video info loaded: $bvid');
      return info;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Get video info error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取音频流URL
  Future<Map<String, dynamic>?> getAudioStream(String bvid) async {
    try {
      _isLoading = true;
      notifyListeners();

      final stream = await _apiService!.getAudioStream(bvid);
      return stream;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Get audio stream error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取缓存的音频元数据
  Future<Map<String, dynamic>?> getAudioMetadata(String bvid) async {
    try {
      return await _apiService!.getAudioMetadata(bvid);
    } catch (e) {
      AppLogger.error('BilibiliProvider', 'Get audio metadata error: $e');
      return null;
    }
  }

  /// 刷新音频元数据缓存
  Future<bool> refreshAudioMetadata(String bvid) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService!.refreshAudioMetadata(bvid);
      AppLogger.debug('BilibiliProvider', 'Audio metadata refreshed: $bvid');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Refresh metadata error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 批量获取视频元数据
  Future<Map<String, Map<String, dynamic>>> getBatchMetadata(List<String> bvids) async {
    try {
      return await _apiService!.getBatchMetadata(bvids);
    } catch (e) {
      AppLogger.error('BilibiliProvider', 'Batch metadata error: $e');
      return {};
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _apiService!.getCacheStats();
    } catch (e) {
      AppLogger.error('BilibiliProvider', 'Get cache stats error: $e');
      return {'count': 0, 'totalSize': 0};
    }
  }

  // ==================== 推荐内容 ====================

  /// 推荐状态
  List<Map<String, dynamic>> _hotPlaylists = [];
  List<Map<String, dynamic>> _hotRank = [];
  List<Map<String, dynamic>> _personalizedRecommendations = [];
  Map<String, dynamic> _personalizedResponse = {}; // 完整的推荐响应数据
  Map<String, dynamic> _musicCategories = {};
  List<Map<String, dynamic>> _categoryRecommendations = [];

  // Phase 2B: 音乐区爬虫推荐
  List<Map<String, dynamic>> _musicZoneRecommendations = [];
  bool _musicZoneFallback = false;

  List<Map<String, dynamic>> get hotPlaylists => _hotPlaylists;
  List<Map<String, dynamic>> get hotRank => _hotRank;
  List<Map<String, dynamic>> get personalizedRecommendations => _personalizedRecommendations;
  Map<String, dynamic> get personalizedResponseData => _personalizedResponse;
  Map<String, dynamic> get musicCategories => _musicCategories;
  List<Map<String, dynamic>> get categoryRecommendations => _categoryRecommendations;
  // Phase 2B: 音乐区爬虫推荐Getters
  List<Map<String, dynamic>> get musicZoneRecommendations => _musicZoneRecommendations;
  bool get musicZoneFallback => _musicZoneFallback;

  /// 获取热门歌单
  Future<bool> loadHotPlaylists({int page = 1, int pageSize = 10}) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getHotPlaylists(page: page, pageSize: pageSize);
      // 过滤掉 null 元素，防止类型转换错误
      final playlists = result['playlists'] as List?;
      _hotPlaylists = playlists
          ?.whereType<Map<String, dynamic>>()
          .toList() ?? [];

      AppLogger.info('BilibiliProvider', 'Hot playlists loaded: ${_hotPlaylists.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Load hot playlists error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取热歌榜单
  Future<bool> loadHotRank({int page = 1, int pageSize = 10}) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getHotRank(page: page, pageSize: pageSize);
      // 过滤掉 null 元素，防止类型转换错误
      final playlists = result['playlists'] as List?;
      _hotRank = playlists
          ?.whereType<Map<String, dynamic>>()
          .toList() ?? [];

      AppLogger.info('BilibiliProvider', 'Hot rank loaded: ${_hotRank.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Load hot rank error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取个性化推荐
  Future<bool> loadPersonalizedRecommendations({int limit = 20}) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getPersonalizedRecommendations(limit: limit);

      // 保存完整的响应数据
      _personalizedResponse = Map<String, dynamic>.from(result);

      // 兼容旧逻辑：保存推荐的items到personalizedRecommendations
      _personalizedRecommendations = List<Map<String, dynamic>>.from(
        result['videos'] ?? result['playlists'] ?? [],
      );

      AppLogger.debug('BilibiliProvider', 'Personalized response: source=${result['source']}, videos=${result['videos']?.length ?? 0}, playlists=${result['playlists']?.length ?? 0}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Load personalized recommendations error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取音乐分区列表
  Future<bool> loadMusicCategories() async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _musicCategories = await _apiService!.getCategoryTids();

      AppLogger.info('BilibiliProvider', 'Music categories loaded: ${_musicCategories.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Load music categories error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取音乐区推荐
  Future<bool> loadMusicRecommendation({int limit = 20}) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getMusicRecommendation(limit: limit);
      _categoryRecommendations = result;

      AppLogger.info('BilibiliProvider', 'Music recommendation loaded: ${_categoryRecommendations.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Load music recommendation error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取分区推荐
  Future<bool> loadByCategory(
    int tid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getByCategory(
        tid,
        page: page,
        pageSize: pageSize,
      );
      _categoryRecommendations = List<Map<String, dynamic>>.from(result['videos'] ?? []);

      AppLogger.info('BilibiliProvider', 'Category $tid loaded: ${_categoryRecommendations.length}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliProvider', 'Load category $tid error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Phase 2B: 音乐区爬虫推荐 ====================

  /// 获取音乐区个性化推荐（爬虫方式）
  ///
  /// 爬取 bilibili.com/c/music 页面获取用户绑定的B站账户的个性化推荐内容
  /// 需要用户已登录并绑定B站账号
  Future<bool> loadMusicZoneRecommendations({int page = 1, int pageSize = 20}) async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      _musicZoneFallback = false;
      notifyListeners();

      final result = await _apiService!.getMusicZoneRecommendations(
        page: page,
        pageSize: pageSize,
      );

      // 检查是否降级
      _musicZoneFallback = result['fallback'] ?? false;

      // 获取数据列表
      _musicZoneRecommendations = List<Map<String, dynamic>>.from(
        result['data'] ?? [],
      );

      AppLogger.info('BilibiliProvider', 'Music zone loaded: ${_musicZoneRecommendations.length}, fallback: $_musicZoneFallback');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _musicZoneFallback = true;
      AppLogger.error('BilibiliProvider', 'Load music zone error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 资源URL ====================

  /// 获取图片代理URL
  String getProxyImageUrl(String originalUrl) {
    return _apiService?.getProxyImageUrl(originalUrl) ?? originalUrl;
  }

  /// 获取音频代理URL
  String getProxyAudioUrl(String originalUrl) {
    return _apiService?.getProxyAudioUrl(originalUrl) ?? originalUrl;
  }

  // ==================== 错误处理 ====================

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    _stopQRPolling();
    super.dispose();
  }
}
