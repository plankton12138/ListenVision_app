# ListenVision 现有代码优化指南

## 📋 文档概述

本文档分析现有代码结构，提出优化建议，并提供具体的改进方案。优化目标是提高代码质量、可维护性和性能。

---

## 🔍 现有代码分析

### 代码结构评估

```
lib/
├── models/          ✅ 结构清晰，但有些模型待优化
├── services/        ⚠️ 部分服务缺少优化
├── providers/       ⚠️ 状态管理需要改进
├── ui/              ⚠️ 页面代码可以优化
├── routes/          ✅ 路由配置清晰
├── theme/           ✅ 主题管理良好
├── constants/       ⚠️ 常量可以更好组织
├── utils/           ✅ 工具类清晰
└── exceptions/      ✅ 异常处理清晰
```

---

## 🚀 优化建议清单

### 优先级 P0 (关键优化)

#### 1. SecureStorageService 集成

**现状问题**:
```dart
// ❌ 当前搜索页面直接使用硬编码 Cookie
final cookie = AppCookies.getCurrentCookie();
```

**优化方案**:
```dart
// ✅ 改为通过认证检查获取 Cookie
Future<String?> _getAuthenticatedCookie(BuildContext context) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  // 检查是否已登录
  if (!authProvider.isBilibiliLoggedIn) {
    // 显示登录提示
    _showLoginRequiredDialog(context);
    return null;
  }

  // 获取加密存储的 Cookie
  final cookie = await secureStorage.getBilibiliCookie(
    authProvider.bilibiliUser!.uid
  );

  if (cookie == null) {
    // Cookie 丢失，需要重新绑定
    _showCookieExpiredDialog(context);
    return null;
  }

  // 验证 Cookie 有效性
  final isValid = await validateCookie(cookie);
  if (!isValid) {
    // Cookie 过期
    _showCookieExpiredDialog(context);
    return null;
  }

  return cookie;
}
```

#### 2. 修复 AuthProvider 认证逻辑

**现状问题**:
```dart
// ❌ 现有代码仅保存本地账号信息
class AuthProvider with ChangeNotifier {
  User? _user;

  Future<void> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'token': user.token,
    }));
    notifyListeners();
  }
}
```

**优化方案**:
```dart
// ✅ 完整的 Bilibili 认证管理
class BilibiliAuthProvider with ChangeNotifier {
  static const _bilibiliUidKey = 'bilibili_uid';
  static const _deviceIdKey = 'device_id';

  BilibiliUser? _bilibiliUser;
  String? _deviceId;
  bool _isLoading = false;

  BilibiliUser? get bilibiliUser => _bilibiliUser;
  bool get isLoggedIn => _bilibiliUser != null;
  bool get isLoading => _isLoading;

  BilibiliAuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_bilibiliUidKey);

    if (uid != null) {
      // 恢复本地缓存的用户信息
      await _loadUserFromCache(uid);
      // 后台验证 Cookie 有效性
      _validateCookieInBackground(uid);
    }
  }

  Future<void> _loadUserFromCache(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('bilibili_user_$uid');

    if (userJson != null) {
      _bilibiliUser = BilibiliUser.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<void> _validateCookieInBackground(String uid) async {
    try {
      final isValid = await apiService.validateBinding(uid);
      if (!isValid) {
        // Cookie 已过期，需要重新绑定
        await logout(reason: 'cookie_expired');
      }
    } catch (e) {
      debugPrint('后台验证失败: $e');
      // 继续允许使用，但下次主动验证时会提示
    }
  }

  Future<void> bindBilibiliAccount({
    required String uid,
    required String username,
    required String avatar,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 生成设备 ID
      _deviceId = const Uuid().v4();

      // 调用后端 API
      final response = await apiService.bindBilibili(
        uid: uid,
        username: username,
        avatar: avatar,
        deviceId: _deviceId!,
        deviceName: await _getDeviceName(),
        platform: _getPlatform(),
      );

      // 保存用户信息
      _bilibiliUser = BilibiliUser(
        uid: int.parse(uid),
        username: username,
        avatar: avatar,
        bindTime: DateTime.now(),
      );

      // 保存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bilibiliUidKey, uid);
      await prefs.setString(_deviceIdKey, _deviceId!);
      await prefs.setString(
        'bilibili_user_$uid',
        jsonEncode(_bilibiliUser!.toJson())
      );

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({String reason = 'user_request'}) async {
    try {
      if (_bilibiliUser != null) {
        // 调用后端 API 记录解绑
        await apiService.unbind(
          uid: _bilibiliUser!.uid.toString(),
          reason: reason,
        );
      }

      // 清除本地数据
      _bilibiliUser = null;
      _deviceId = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bilibiliUidKey);
      await prefs.remove(_deviceIdKey);

      // 清除加密存储中的 Cookie
      if (_bilibiliUser != null) {
        await secureStorage.deleteCookie(
          _bilibiliUser!.uid.toString(),
          'bilibili'
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('登出失败: $e');
      rethrow;
    }
  }
}
```

#### 3. 重构 SearchPage 认证检查

**现状问题**:
```dart
// ❌ 缺少认证检查，直接使用硬编码 Cookie
Future<void> _searchBilibili(BuildContext context, String keyword, {int page = 1}) async {
  AppCookies.incrementSearchCount();
  final cookie = AppCookies.getCurrentCookie();
  // ... 直接使用 Cookie 搜索
}
```

**优化方案**:
```dart
// ✅ 完整的认证检查和错误处理
Future<void> _searchBilibili(BuildContext context, String keyword, {int page = 1}) async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // 检查页码限制
  if (page > 50) {
    showMySnackBar(context, '最多查看 50 页', Colors.red, 1000);
    return;
  }

  // 检查认证
  final cookie = await _getAuthenticatedCookie(context);
  if (cookie == null) {
    return;  // 已显示提示信息
  }

  setState(() {
    _currentPage = page;
    _isLoading = true;
  });

  try {
    AppCookies.incrementSearchCount();

    final response = await http.get(
      Uri.parse(
        'https://api.bilibili.com/x/web-interface/wbi/search/type'
        '?search_type=video&keyword=$keyword&page=$page&page_size=20'
      ),
      headers: {
        'User-Agent': 'Mozilla/5.0 ...',
        'Referer': 'https://www.bilibili.com/',
        'Cookie': cookie,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 检查返回状态
      if (data['code'] != 0) {
        final errorMsg = data['message'] ?? '搜索失败';
        showMySnackBar(context, '搜索错误: $errorMsg', Colors.red, 1000);
        return;
      }

      final results = data['data']['result'] ?? [];
      results.removeWhere((element) => element['type'] != 'video');

      setState(() {
        _results = results;
      });

      if (_results.isEmpty) {
        showMySnackBar(context, '未找到相关结果', Colors.orange, 800);
      }
    } else if (response.statusCode == 412) {
      showMySnackBar(
        context,
        '搜索被拦截，请稍后重试',
        Colors.red,
        1000
      );
    } else {
      throw Exception('搜索失败: ${response.statusCode}');
    }
  } catch (e) {
    showMySnackBar(context, '错误: $e', Colors.red, 1000);
    debugPrint('搜索异常: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

Future<String?> _getAuthenticatedCookie(BuildContext context) async {
  final authProvider = Provider.of<BilibiliAuthProvider>(context, listen: false);

  if (!authProvider.isLoggedIn) {
    _showLoginRequiredDialog(context);
    return null;
  }

  final cookie = await secureStorage.getBilibiliCookie(
    authProvider.bilibiliUser!.uid.toString(),
    'bilibili'
  );

  if (cookie == null) {
    _showCookieExpiredDialog(context);
    return null;
  }

  return cookie;
}

void _showLoginRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('需要登录'),
      content: const Text('搜索功能需要绑定B站账号，是否现在绑定？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.go('/bilibili_binding');
          },
          child: const Text('绑定'),
        ),
      ],
    ),
  );
}
```

---

### 优先级 P1 (重要优化)

#### 4. DownloadManager 优化

**现状问题**:
```dart
// ❌ 缺少认证检查和错误处理
Future<void> addDownload(BuildContext context, String url) async {
  if (!url.startsWith('https://www.bilibili.com/video/') &&
      !url.startsWith('http://www.bilibili.com/video/')) {
    showMySnackBar(context, 'download failed, not a bilibili video', Colors.red, 500);
    return;
  }
  // ... 直接下载，无认证检查
}
```

**优化方案**:
```dart
// ✅ 完整的下载流程，包含认证检查
Future<void> addDownload(BuildContext context, String url) async {
  // 1. 输入验证
  if (!_isValidBilibiliUrl(url)) {
    showMySnackBar(context, '无效的B站URL', Colors.red, 500);
    return;
  }

  // 2. 认证检查
  final authProvider = Provider.of<BilibiliAuthProvider>(
    context,
    listen: false
  );

  if (!authProvider.isLoggedIn) {
    _showLoginRequiredDialog(context);
    return;
  }

  // 3. 获取 Cookie
  final cookie = await secureStorage.getBilibiliCookie(
    authProvider.bilibiliUser!.uid.toString(),
    'bilibili'
  );

  if (cookie == null || !await _validateCookie(cookie)) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('登录已过期'),
        content: const Text('请重新绑定B站账号'),
        actions: [
          TextButton(
            onPressed: () => context.go('/bilibili_binding'),
            child: const Text('重新绑定'),
          ),
        ],
      ),
    );
    return;
  }

  // 4. 检查下载配额
  final downloadCount = await _getDownloadCountToday(
    authProvider.bilibiliUser!.uid.toString()
  );
  if (downloadCount >= 10) {
    showMySnackBar(context, '今日下载次数已达上限', Colors.red, 1000);
    return;
  }

  // 5. 选择保存位置
  final savePath = await _pickDirectory();
  if (savePath == null) {
    showMySnackBar(context, '未选择保存位置', Colors.orange, 500);
    return;
  }

  // 6. 检查空间
  final availableSpace = await _getAvailableSpace(savePath);
  if (availableSpace < 100 * 1024 * 1024) {  // 100 MB
    showMySnackBar(context, '存储空间不足', Colors.red, 1000);
    return;
  }

  // 7. 启动下载
  await _startDownload(url, savePath, cookie);
  showMySnackBar(context, '下载已开始', Colors.green, 800);
}

bool _isValidBilibiliUrl(String url) {
  return url.startsWith('https://www.bilibili.com/video/') ||
      url.startsWith('http://www.bilibili.com/video/') ||
      url.startsWith('https://www.bilibili.com/s/');
}

Future<int> _getDownloadCountToday(String uid) async {
  final db = await _database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM downloads '
    'WHERE bilibili_uid = ? AND DATE(downloadStartTime) = DATE(\'now\')',
    [uid],
  );
  return result[0]['count'] as int;
}

Future<int> _getAvailableSpace(String path) async {
  // 使用 disk_space 或类似库获取可用空间
  // 这里简化为返回固定值
  return 1024 * 1024 * 1024;  // 1 GB
}
```

#### 5. AudioProvider 优化

**现状问题**:
```dart
// ❌ 内存泄漏风险：StreamSubscription 未正确管理
class AudioProvider extends ChangeNotifier {
  late StreamSubscription _positonSub;
  late StreamSubscription _durationSub;
  late StreamSubscription _stateSub;

  // 缺少 dispose 方法
}
```

**优化方案**:
```dart
// ✅ 正确的资源管理
class AudioProvider extends ChangeNotifier {
  final _player = AudioPlayer();

  List<Audio> _playlist = [];
  int _currentIndex = -1;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  String _title = "Unknown";
  String _artist = "Unknown";
  Uint8List? _albumArt;

  final List<StreamSubscription> _subscriptions = [];

  AudioProvider() {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await _loadPlaylist();
    _initListeners();
  }

  void _initListeners() {
    _subscriptions.clear();

    _subscriptions.add(
      _player.onPositionChanged.listen(_updatePosition)
    );

    _subscriptions.add(
      _player.onDurationChanged.listen(_updateDuration)
    );

    _subscriptions.add(
      _player.onPlayerStateChanged.listen(_updatePlayState)
    );

    _subscriptions.add(
      _player.onPlayerComplete.listen((_) => playNext())
    );
  }

  void _updatePosition(Duration p) {
    if (_position != p) {
      _position = p;
      notifyListeners();
    }
  }

  void _updateDuration(Duration d) {
    if (_duration != d) {
      _duration = d;
      notifyListeners();
    }
  }

  void _updatePlayState(PlayerState state) {
    final isPlaying = state == PlayerState.playing;
    if (_isPlaying != isPlaying) {
      _isPlaying = isPlaying;
      notifyListeners();
    }
  }

  Future<void> loadAudio(String filePath) async {
    try {
      // 解析元数据
      final metadata = await AudioTags.read(filePath);

      _title = metadata?.title ?? "Unknown";
      _artist = metadata?.trackArtist ?? "Unknown";

      final pictures = metadata?.pictures ?? [];
      _albumArt = pictures.isNotEmpty
          ? Uint8List.fromList(pictures.first.bytes)
          : null;

      _position = Duration.zero;

      // 设置音频源并立即播放
      await _player.setSource(DeviceFileSource(filePath));
      notifyListeners();
    } catch (e) {
      debugPrint('加载音频失败: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // 清理所有订阅
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // 关闭播放器
    _player.dispose();

    super.dispose();
  }
}
```

#### 6. 路由保护

**现状问题**:
```dart
// ❌ 路由无保护，用户可以直接访问需要认证的页面
GoRoute(
  path: '/search',
  builder: (context, state) => const SearchPage(),
),
```

**优化方案**:
```dart
// ✅ 添加路由保护
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/bilibili_binding',
      builder: (context, state) => const BilibiliBindingPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
      redirect: _requiresAuth,  // 添加认证检查
    ),
    GoRoute(
      path: '/download',
      builder: (context, state) => const DownloadListPage(),
      redirect: _requiresAuth,  // 添加认证检查
    ),
  ],
);

Future<String?> _requiresAuth(
  BuildContext context,
  GoRouterState state
) async {
  final authProvider = context.read<BilibiliAuthProvider>();

  if (!authProvider.isLoggedIn) {
    // 重定向到绑定页面
    return '/bilibili_binding';
  }

  return null;  // 允许访问
}
```

---

### 优先级 P2 (性能优化)

#### 7. API 请求缓存

**现状问题**:
```dart
// ❌ 重复请求相同数据
Future<void> _searchBilibili(...) async {
  final response = await http.get(uri, headers: headers);
  // 每次搜索都重新请求，无缓存
}
```

**优化方案**:
```dart
// ✅ 添加简单缓存
class SearchCache {
  static const duration = Duration(minutes: 5);
  static final _cache = <String, CacheEntry>{};

  static class CacheEntry {
    final dynamic data;
    final DateTime timestamp;

    CacheEntry(this.data, this.timestamp);

    bool get isExpired => DateTime.now().difference(timestamp) > duration;
  }

  static dynamic get(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data;
    }
    _cache.remove(key);
    return null;
  }

  static void set(String key, dynamic data) {
    _cache[key] = CacheEntry(data, DateTime.now());
  }

  static void clear() {
    _cache.clear();
  }
}

// 使用
Future<void> _searchBilibili(String keyword, {int page = 1}) async {
  final cacheKey = '$keyword:$page';

  // 检查缓存
  final cachedResults = SearchCache.get(cacheKey);
  if (cachedResults != null) {
    setState(() => _results = cachedResults);
    return;
  }

  // 网络请求
  final response = await http.get(...);
  final results = json.decode(response.body);

  // 存入缓存
  SearchCache.set(cacheKey, results);

  setState(() => _results = results);
}
```

#### 8. 图片加载优化

**现状问题**:
```dart
// ❌ 未优化的图片加载
Image.network(albumArt)  // 无缓存配置
```

**优化方案**:
```dart
// ✅ 配置图片缓存
CachedNetworkImage(
  imageUrl: albumArt,
  placeholder: (context, url) => const Icon(Icons.music_note),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  cacheManager: CacheManager(
    Config(
      'imageCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  ),
);
```

---

### 优先级 P3 (代码风格优化)

#### 9. 错误处理统一

**现状问题**:
```dart
// ❌ 错误处理不一致
try {
  // ...
} catch (e) {
  showMySnackBar(context, 'error: $e', Colors.red, 1000);
}
```

**优化方案**:
```dart
// ✅ 创建统一的错误处理
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

// 使用
try {
  // ...
} catch (e) {
  final appError = _parseError(e);
  showMySnackBar(context, appError.message, Colors.red, 1000);
  debugPrint('错误 [${appError.code}]: $e');
}

AppException _parseError(dynamic error) {
  if (error is AppException) {
    return error;
  } else if (error is SocketException) {
    return AppException(
      message: '网络连接失败',
      code: 'NETWORK_ERROR',
      originalException: error,
    );
  } else if (error is TimeoutException) {
    return AppException(
      message: '请求超时',
      code: 'TIMEOUT',
      originalException: error,
    );
  } else {
    return AppException(
      message: '未知错误',
      code: 'UNKNOWN',
      originalException: error,
    );
  }
}
```

#### 10. 代码组织优化

**现状问题**:
```dart
// ❌ SearchPage 中混杂 UI 和业务逻辑
class _SearchPageState extends State<SearchPage> {
  // 500+ 行代码混合在一个文件中
  Future<void> _searchBilibili(...) { }
  Widget _buildSearchBar(...) { }
  Widget _buildSearchResults(...) { }
  // ...
}
```

**优化方案**:
```dart
// ✅ 分离关注点
// search_page.dart
class SearchPage extends StatefulWidget {
  const SearchPage();

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SearchViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() => /* ... */;
  Widget _buildBody() => /* ... */;
}

// search_view_model.dart
class SearchViewModel with ChangeNotifier {
  List<dynamic> results = [];
  bool isLoading = false;
  int currentPage = 1;

  final SearchService _searchService = SearchService();

  Future<void> search(String keyword, {int page = 1}) async {
    try {
      isLoading = true;
      notifyListeners();

      results = await _searchService.search(keyword, page: page);
      currentPage = page;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

// search_service.dart
class SearchService {
  Future<List<dynamic>> search(String keyword, {int page = 1}) async {
    // 实现搜索逻辑
  }
}
```

---

## 📊 优化优先级总结

| 优先级 | 优化项 | 影响 | 工作量 |
|-------|-------|------|-------|
| **P0** | SecureStorage 集成 | 🔴 高 | 中 |
| **P0** | AuthProvider 改造 | 🔴 高 | 中 |
| **P0** | SearchPage 认证检查 | 🔴 高 | 中 |
| **P1** | DownloadManager 优化 | 🟠 中 | 中 |
| **P1** | AudioProvider 内存管理 | 🟠 中 | 小 |
| **P1** | 路由保护 | 🟠 中 | 小 |
| **P2** | API 缓存 | 🟡 低 | 小 |
| **P2** | 图片加载优化 | 🟡 低 | 小 |
| **P3** | 错误处理统一 | 🟡 低 | 小 |
| **P3** | 代码组织优化 | 🟡 低 | 中 |

---

## 🎯 优化实施建议

### 第一阶段（P0 - 关键）
- ✅ 完成 SecureStorage 集成
- ✅ 改造 AuthProvider
- ✅ 添加 SearchPage 认证检查
- **预计时间**: 2-3 天

### 第二阶段（P1 - 重要）
- ✅ 优化 DownloadManager
- ✅ 修复 AudioProvider 内存泄漏
- ✅ 添加路由保护
- **预计时间**: 1-2 天

### 第三阶段（P2/P3 - 可选）
- ✅ API 缓存
- ✅ 图片加载优化
- ✅ 错误处理统一
- ✅ 代码重组织
- **预计时间**: 1-2 天

---

**版本**: 1.0
**日期**: 2026-01-03
**建议**: 按优先级逐步实施，确保代码质量
