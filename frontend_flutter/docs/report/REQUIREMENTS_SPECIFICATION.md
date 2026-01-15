# ListenVision 完整需求文档

## 📋 文档概述

本文档定义 ListenVision 应用在采用纯 Bilibili 认证系统后的完整业务需求、用户操作流程和系统功能规范。

---

## 🎯 产品概述

### 产品定位

ListenVision 是一个跨平台音乐播放和发现应用，用户可以：
- **离线本地**：使用本地音频文件而无需认证
- **在线发现**：绑定 B站账号后搜索和下载音频内容
- **个性化服务**：基于 B站身份的收藏、推荐等功能

### 核心差异化

```
未登录用户
  ├─ ✅ 播放本地音频（无限制）
  ├─ ✅ 管理本地播放列表
  └─ ❌ 搜索、下载、收藏（需要认证）

已登录用户（绑定B站账号）
  ├─ ✅ 所有未登录功能
  ├─ ✅ 搜索B站音视频
  ├─ ✅ 下载音频到本地
  ├─ ✅ 在线收藏管理
  └─ ✅ 个性化推荐（预留）
```

---

## 🔐 用户认证流程

### 启动应用流程

```
启动应用
  ↓
检查是否已绑定B站账号
  ├─ 是 → 恢复本地缓存
  │   ├─ 验证Cookie有效性
  │   │  ├─ 有效 → 进入主页 (首页)
  │   │  └─ 过期 → 提示重新绑定 (转到步骤②)
  │   └─ 无本地缓存 → 调用API获取用户信息 → 进入主页
  │
  └─ 否 → 显示绑定引导页面 (BilibiliBindingPage)
```

### ① 绑定流程（首次使用或重新绑定）

```
点击"绑定B站账号"
  ↓
BilibiliAuthService.generateQRCode()
  ├─ 调用 B站 API: GET /x/passport-login/web/qrcode/generate
  ├─ 获取 qrcode_url 和 qrcode_key
  └─ 生成二维码展示给用户
  ↓
用户使用B站APP扫码
  ↓
BilibiliAuthService.pollQRCodeStatus(qrcode_key)
  ├─ 轮询状态（每 2 秒）
  ├─ 调用 B站 API: GET /x/passport-login/web/qrcode/poll
  ├─ 处理状态码:
  │  ├─ 86101: 未扫码 → 继续等待
  │  ├─ 86090: 已扫码未确认 → 显示"已扫码，请确认"
  │  ├─ 86038: 二维码过期 → 显示错误，提示重新扫
  │  └─ 0: 登录成功 → 继续
  ├─ 超时机制: 3 分钟无操作 → 超时，需要重新扫
  └─ 获取 Cookie 和用户信息
  ↓
BilibiliAuthService.getUserInfo(cookie)
  ├─ 调用 B站 API: GET /x/web-interface/nav (with Cookie)
  ├─ 获取用户基本信息 (uid, nickname, avatar)
  └─ 验证Cookie有效性
  ↓
调用后端 API: POST /api/bilibili/bind
  ├─ 请求体:
  │  {
  │    bilibili_uid: 272017820,
  │    bilibili_username: "username",
  │    avatar: "https://...",
  │    device_id: "device-uuid",
  │    device_name: "iPhone 15",
  │    platform: "iOS"
  │  }
  └─ 返回: binding_info
  ↓
保存到本地
  ├─ SharedPreferences: bilibili_uid, device_id
  ├─ SecureStorage: Cookie (加密)
  └─ 本地缓存: 用户信息
  ↓
进入主页 (HomePage)
```

### ② 用户已登录的启动流程

```
应用启动
  ↓
检查 SharedPreferences 中的 bilibili_uid
  ├─ 存在 → 进入已登录流程
  └─ 不存在 → 进入未登录流程
  ↓
从 SecureStorage 读取 Cookie
  ├─ 成功 → 继续
  └─ 失败 (丢失/损坏) → 清除数据，重新绑定
  ↓
验证 Cookie 有效性
  ├─ 调用: POST /api/bilibili/validate
  ├─ 有效 → 进入主页
  ├─ 过期 → 显示"B站登录已过期"提示，转到绑定页面
  └─ 错误 → 显示错误提示，允许重试
```

---

## 📱 应用功能模块

### 模块 1: 本地音频播放（无需认证）

#### 首页 (HomePage)

**功能**:
- 显示当前播放的音频信息
- 音频播放控制（播放/暂停/上一曲/下一曲）
- 进度条拖拽
- 音量控制（预留）

**用户操作**:
1. 点击"上传音频"按钮 → 打开文件选择器
2. 选择本地音频文件 → 加载元数据
3. 点击播放 → 播放音频
4. 使用控制按钮 → 控制播放

**交互细节**:
```
┌─────────────────────────────────┐
│    ListenVision              🏠  │  (Home icon)
├─────────────────────────────────┤
│                                 │
│       [Album Art]               │
│                                 │
│  当前播放: Song Title            │
│  艺术家: Artist Name             │
│                                 │
│  ▶️  ⏸️  ⏭️  ⏮️                   │  (Controls)
│  ═══════════●═══════ 2:30/5:00  │  (Progress)
│                                 │
├─────────────────────────────────┤
│  📋 播放列表  📁 浏览  🔍 搜索   │  (Bottom navigation)
└─────────────────────────────────┘
```

#### 播放列表 (PlaylistPage)

**功能**:
- 显示已加载的所有本地音频
- 显示当前播放位置
- 支持删除音频
- 支持重新排序（预留）

**本地数据存储**:
```sql
-- 本地SQLite: downloads.db
CREATE TABLE downloads (
  id INTEGER PRIMARY KEY,
  url TEXT,
  savePath TEXT,
  downloadedBytes INTEGER,
  totalBytes INTEGER,
  isPaused INTEGER,
  title TEXT,
  artist TEXT
);

CREATE TABLE playlist (
  id INTEGER PRIMARY KEY,
  filePath TEXT,
  title TEXT,
  artist TEXT,
  duration INTEGER,
  addedTime TIMESTAMP
);
```

### 模块 2: 搜索和下载（需要认证）

#### 搜索页面 (SearchPage)

**功能**:
- 搜索 B站音视频
- 分页浏览结果
- 查看搜索结果详情
- 下载音频

**认证检查**:
```dart
Future<void> _searchBilibili(String keyword) async {
  // 1. 检查是否已登录
  if (!isUserLoggedIn) {
    showDialog(
      title: '需要登录',
      message: '搜索功能需要绑定B站账号，是否现在绑定？',
      confirmAction: () => navigateToBilibiliBind()
    );
    return;
  }

  // 2. 检查 Cookie 有效性
  final cookie = await secureStorage.getCookie(userId);
  if (cookie == null || !await validateCookie(cookie)) {
    showDialog(
      title: 'B站登录过期',
      message: '登录信息已过期，请重新绑定',
      confirmAction: () => navigateToBilibiliBind()
    );
    return;
  }

  // 3. 执行搜索
  _performSearch(keyword, cookie);
}
```

**搜索流程**:
```
输入关键词
  ↓
点击"搜索"
  ↓
检查认证状态 (如上所示)
  ↓
AppCookies.incrementSearchCount()
  ↓ (Cookie 轮换计数)
  ↓
调用 B站 API: GET /x/web-interface/wbi/search/type
  ├─ 参数:
  │  ├─ keyword: 搜索词
  │  ├─ page: 当前页码
  │  ├─ page_size: 20
  │  ├─ search_type: video
  │  └─ Cookie: 用户真实Cookie
  └─ 获取搜索结果 (视频列表)
  ↓
显示搜索结果
  ├─ 视频标题
  ├─ 点击数
  ├─ 时长
  └─ 下载按钮
  ↓
用户可以:
  ├─ 翻页浏览更多结果
  ├─ 点击下载按钮开始下载
  └─ 点击查看详情
```

#### 下载功能 (DownloadManager)

**下载流程**:
```
点击"下载"按钮
  ↓
检查认证状态
  ├─ 未登录 → 提示绑定
  └─ 已登录 → 继续
  ↓
检查本地存储空间
  ├─ 空间不足 → 提示用户
  └─ 空间足够 → 继续
  ↓
选择保存位置 (文件选择器)
  ↓
初始化下载
  ├─ 生成唯一 ID
  ├─ 创建下载记录
  └─ 启动下载任务
  ↓
下载进行中
  ├─ 显示进度条
  ├─ 显示下载速度
  ├─ 支持暂停
  └─ 支持取消
  ↓
下载完成
  ├─ 保存文件
  ├─ 更新元数据
  ├─ 添加到播放列表
  └─ 显示成功提示
```

**下载数据库表**:
```sql
CREATE TABLE downloads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  url TEXT,                    -- B站视频 URL
  savePath TEXT,              -- 本地保存路径
  downloadedBytes INTEGER,    -- 已下载字节
  totalBytes INTEGER,         -- 总字节数
  isPaused INTEGER,           -- 是否暂停 (0/1)
  originalUrl TEXT,           -- 原始视频 URL
  title TEXT,                 -- 视频标题
  bilibiliUid INTEGER,        -- 绑定的 B站用户 ID
  downloadStartTime TIMESTAMP,
  downloadFinishTime TIMESTAMP,
  status VARCHAR(20)          -- pending/downloading/completed/failed
);
```

**下载限制与策略**:
```
单用户限制:
  ├─ 同时下载任务: 最多 3 个
  ├─ 单个文件大小: 500 MB (可配置)
  └─ 单日下载限制: 10 个视频 (防止滥用)

断点续传:
  ├─ 支持暂停/恢复
  ├─ 保存下载进度
  └─ 支持重新选择保存位置

质量选择:
  ├─ 清晰度: 480p/720p/1080p
  ├─ 格式: MP3/M4A (取决于B站提供)
  └─ 自动选择最优质量
```

### 模块 3: 收藏管理（需要认证）

#### 收藏功能

**存储结构**:
```sql
-- 服务器端: favorites 表
CREATE TABLE favorites (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bilibili_uid BIGINT NOT NULL,  -- 绑定的 B站用户 ID
  url TEXT NOT NULL,             -- 视频 URL
  title VARCHAR(255) NOT NULL,   -- 视频标题
  bilibiliVideoId VARCHAR(50),   -- B站视频 ID
  thumbnail TEXT,                -- 缩略图
  duration INT,                  -- 时长（秒）
  addedTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (bilibili_uid) REFERENCES bilibili_bindings(bilibili_uid)
);
```

**收藏流程**:
```
在搜索结果中
  ↓
点击"收藏"按钮
  ↓
验证认证状态
  ├─ 未登录 → 提示绑定
  └─ 已登录 → 继续
  ↓
发送请求: POST /api/favorites
  ├─ bilibili_uid: 用户 ID
  ├─ url: 视频 URL
  ├─ title: 视频标题
  └─ ...其他信息
  ↓
收藏成功
  ├─ 显示"已收藏"状态
  ├─ 按钮变为"取消收藏"
  └─ 同步到本地缓存
```

---

## 🔄 认证状态管理

### AuthProvider 改造

```dart
class AuthProvider with ChangeNotifier {
  // 原有字段 (保留用于向后兼容)
  User? _user;  // 本地账号用户 (现已废弃)

  // 新增字段 - Bilibili 认证
  BilibiliUser? _bilibiliUser;      // B站用户信息
  String? _bilibiliUid;             // B站用户 ID
  String? _deviceId;                // 设备唯一 ID
  bool _isAuthenticationLoading = false;

  // Getters
  BilibiliUser? get bilibiliUser => _bilibiliUser;
  bool get isBilibiliLoggedIn => _bilibiliUser != null;
  bool get isLoading => _isAuthenticationLoading;

  // 登录/登出逻辑
  Future<void> bindBilibiliAccount(String uid, String username, String avatar) async {
    try {
      _isAuthenticationLoading = true;
      notifyListeners();

      // 调用后端 API 保存绑定
      final response = await apiService.bindBilibili({
        'bilibili_uid': uid,
        'bilibili_username': username,
        'avatar': avatar,
        'device_id': _deviceId,
        'device_name': deviceName,
        'platform': platform,
      });

      if (response['success']) {
        _bilibiliUser = BilibiliUser.fromJson(response['binding_info']);
        await _saveToLocalStorage();
        notifyListeners();
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      debugPrint('绑定失败: $e');
      rethrow;
    } finally {
      _isAuthenticationLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _bilibiliUser = null;
    _bilibiliUid = null;
    await secureStorage.deleteAllUserData();
    await sharedPreferences.remove('bilibili_uid');
    notifyListeners();
  }

  Future<void> _loadFromLocalStorage() async {
    final uid = await sharedPreferences.getString('bilibili_uid');
    if (uid != null) {
      // 从缓存恢复用户信息
      // 验证 Cookie 有效性
    }
  }
}
```

---

## 🔒 安全与隐私

### Cookie 安全

**存储**:
```dart
// ✅ 安全做法
final cookie = await getFromB站();
await secureStorage.saveCookie(userId, 'bilibili', cookie);
// Cookie 自动加密存储在系统级密钥库

// ❌ 不安全做法
SharedPreferences.setString('cookie', cookie);  // ❌ 明文
debugPrint('Cookie: $cookie');                   // ❌ 打印敏感信息
```

**Cookie 生命周期**:
```
获取时间: T0
  ↓
有效期: 30 天
  ↓
T0 + 30 天: 需要重新绑定
  ↓
验证失败 → 清除 Cookie → 显示重新绑定提示
```

### 数据隐私

**本地数据**:
- 播放历史：仅存储本地，不上传
- 下载列表：本地数据库
- 用户信息：仅缓存 uid, username, avatar

**服务器数据**:
- 绑定关系：只记录 B站 uid，不存 Cookie
- 收藏：关联到 B站 uid
- 操作日志：记录操作类型、时间、设备

**用户可以**:
- 在设置页面查看已绑定的设备
- 远程解绑特定设备
- 完全解绑账号（清除所有数据）

---

## 📊 数据流总结

### 已登录用户的数据流

```
用户输入搜索词
  ↓
前端检查认证状态
  ├─ 调用 AuthProvider.isBilibiliLoggedIn
  ├─ 读取 SecureStorage 中的 Cookie
  └─ 验证 Cookie 有效性
  ↓
构建请求
  ├─ Bilibili API URL
  ├─ 用户真实 Cookie
  └─ 搜索参数
  ↓
发送请求 → 获得搜索结果
  ↓
显示结果到 UI
```

### 未登录用户的数据流

```
用户点击"搜索"/"下载"
  ↓
前端检查认证状态
  ├─ 调用 AuthProvider.isBilibiliLoggedIn
  └─ 返回 false
  ↓
显示登录提示对话框
  ├─ "需要 B站账号才能使用此功能"
  ├─ 确认 → 跳转到绑定页面
  └─ 取消 → 返回前一页面
```

---

## 🎯 核心验收标准

### 认证系统
- ✅ 用户可以通过二维码扫码绑定 B站账号
- ✅ 绑定信息正确保存到后端数据库
- ✅ Cookie 安全加密存储在本地
- ✅ 应用启动时自动验证登录状态
- ✅ Cookie 过期时自动提示重新绑定

### 搜索功能
- ✅ 未登录用户无法搜索
- ✅ 已登录用户可以成功搜索
- ✅ 搜索结果正确显示
- ✅ 支持分页浏览

### 下载功能
- ✅ 未登录用户无法下载
- ✅ 已登录用户可以下载音频
- ✅ 显示下载进度
- ✅ 支持暂停/恢复/取消
- ✅ 下载完成自动添加到播放列表

### 本地功能
- ✅ 用户可以随时加载本地音频（无需登录）
- ✅ 可以播放、暂停、拖拽进度
- ✅ 播放列表保存到本地数据库
- ✅ 应用重启时保持播放状态

### 用户体验
- ✅ UI 清晰直观
- ✅ 转换状态有视觉反馈
- ✅ 错误提示清楚
- ✅ 加载状态有进度提示
- ✅ 响应时间 < 2 秒

---

## 📚 相关文档

- [BILIBILI_ONLY_ARCHITECTURE.md](./BILIBILI_ONLY_ARCHITECTURE.md) - 架构设计
- [API_SPECIFICATION.md](./API_SPECIFICATION.md) - API 规范
- [bilibili-API-collect](../../bilibili-API-collect/) - B站官方 API 文档

---

**版本**: 1.0
**日期**: 2026-01-03
**状态**: 待批准
