# ListenVision Bilibili 认证流程详细设计

## 📋 文档概述

本文档详细描述 Bilibili 认证系统与应用各个模块的集成方式，包括完整的流程图、状态转换、错误处理和测试用例。

---

## 🏗️ 架构集成图

```
┌──────────────────────────────────────────────────────────────┐
│                     App Initialization                       │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  Check Shared Preferences  │
        │  (bilibili_uid exists?)    │
        └────┬──────────────────┬────┘
             │ No              │ Yes
             ▼                 ▼
    ┌─────────────────┐  ┌──────────────────────┐
    │ Show Binding    │  │ Load User from Cache │
    │ Page            │  │ Validate Cookie      │
    └─────────────────┘  └──────┬───────────────┘
                                │
                    ┌───────────┴───────────┐
                    │ Valid              Invalid/Expired
                    ▼                        ▼
           ┌───────────────────┐  ┌──────────────────────┐
           │ Show Home Page    │  │ Show Re-bind Prompt  │
           │ (Authenticated)   │  │ Go to Binding Page   │
           └───────────────────┘  └──────────────────────┘
```

---

## 🔐 认证状态机

```
┌─────────────────┐
│   UNLOGGED_IN   │  (未登录)
└────────┬────────┘
         │ 用户点击"绑定"
         ▼
┌──────────────────────┐
│ QR_CODE_GENERATING   │  (生成二维码中)
│ - 显示加载动画         │
│ - 获取 qrcode_url    │
│ - 生成二维码显示      │
└────────┬─────────────┘
         │ 生成成功
         ▼
┌──────────────────────┐
│ WAITING_FOR_SCAN     │  (等待扫码)
│ - 显示二维码          │
│ - 轮询状态 (2s间隔)  │
│ - 3分钟超时          │
└────────┬──────┬─────────┬────────┘
         │ 扫码 │ 超时    │ 取消
         ▼     ▼         ▼
    ┌─────┐ ┌─────┐ ┌─────────────┐
    │ ... │ │ ... │ │ UNLOGGED_IN │
    └─────┘ └─────┘ └─────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────────────────────┐ ┌──────────────────────┐
│ SCANNED_NOT_CONFIRMED │ │ QR_CODE_EXPIRED      │
│ - 显示"请在手机上确认"  │ │ - 显示"二维码已过期"   │
│ - 继续轮询            │ │ - 提示重新扫码        │
└──────┬────────────────┘ └──────┬───────────────┘
       │ 确认              │ 重试
       │                  └─────────┐
       │                            │
       ▼                            │
┌──────────────────────────────────┘
│ GETTING_USER_INFO
│ - 获取用户信息
│ - 解析 Cookie
└─────────┬────────────
          │
    ┌─────┴─────┐
    ▼           ▼
┌────────┐ ┌──────────┐
│ 成功   │ │  失败    │
└───┬────┘ └────┬─────┘
    │           │
    ▼           ▼
┌─────────────────────────┐ ┌──────────────────┐
│ BINDING_WITH_BACKEND    │ │ UNLOGGED_IN      │
│ - 调用后端API保存绑定   │ │ - 显示错误消息    │
│ - 保存Cookie到加密存储  │ │ - 返回绑定页面   │
│ - 保存用户信息          │ └──────────────────┘
└────────┬────────────────┘
         │
    ┌────┴─────┐
    ▼          ▼
┌──────┐ ┌─────────┐
│ 成功 │ │  失败   │
└──┬───┘ └────┬────┘
   │          │
   ▼          ▼
LOGGED_IN   UNLOGGED_IN
(已登录)      (返回重试)
```

---

## 📊 完整绑定流程 - 时序图

```
User              App              B站API           后端服务器
 │                 │                │                 │
 │─ 点击"绑定" ──→ │                │                 │
 │                 │─ generateQRCode →│                 │
 │                 │                │─ 返回qrcode_url │
 │                 │← qrcode_url──→ │                 │
 │  显示二维码      │                │                 │
 │◄─显示二维码────│                │                 │
 │                 │ 轮询状态        │                 │
 │─ 使用B站APP ──→ │─ poll ─────────→│                 │
 │   扫码           │                │─ 86101 (未扫码)  │
 │                 │← 继续轮询       │                 │
 │                 │                │                 │
 │─ 手机上确认 ──→ │─ poll ─────────→│                 │
 │                 │                │─ 86090 (已扫码) │
 │  显示确认提示    │← 状态更新       │                 │
 │                 │                │                 │
 │                 │─ poll ─────────→│                 │
 │                 │                │─ 0 (成功)       │
 │  显示成功动画    │← Cookie + URL  │                 │
 │                 │                │                 │
 │                 │─ getUserInfo ──→│                 │
 │                 │  (with Cookie)  │                 │
 │                 │← 用户信息       │                 │
 │                 │                │                 │
 │                 │─ POST /bind ───────────────────→│
 │                 │  (uid, username, avatar, etc)   │
 │                 │                │                 │
 │                 │ (保存数据库)    │
 │                 │←────────────────── binding_info │
 │                 │                │                 │
 │  进入主页        │← 保存本地       │                 │
 │◄─────────────── │  (uid, Cookie)  │                 │
 │                 │                │                 │
```

---

## 🔄 启动流程 - 详细步骤

### 步骤 1: 检查本地状态

```dart
Future<AuthStatus> checkAuthStatus() async {
  // 1.1 读取 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final bilibili_uid = prefs.getString('bilibili_uid');

  if (bilibili_uid == null) {
    return AuthStatus.unlogged;  // 未登录，显示绑定页面
  }

  // 1.2 从 SecureStorage 读取 Cookie
  final cookie = await secureStorage.getBilibiliCookie(
    bilibili_uid,
    'bilibili'
  );

  if (cookie == null) {
    // Cookie 丢失，清除状态
    await prefs.remove('bilibili_uid');
    return AuthStatus.unlogged;
  }

  return AuthStatus.validating;  // 需要进一步验证
}
```

### 步骤 2: 验证 Cookie 有效性

```dart
Future<AuthStatus> validateCookie(String uid, String cookie) async {
  try {
    // 2.1 主动验证：调用后端 API
    final response = await apiService.validateBinding(uid);

    if (response['is_valid']) {
      // 2.2 Cookie 有效，记录最后验证时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_validation', DateTime.now().toString());
      return AuthStatus.logged;
    } else {
      // 2.3 Cookie 已过期
      await logout(reason: 'cookie_expired');
      return AuthStatus.expired;
    }
  } catch (e) {
    // 2.4 网络错误时允许继续使用（但下次会验证）
    debugPrint('验证失败（网络）: $e');
    return AuthStatus.logged;
  }
}
```

### 步骤 3: 恢复用户界面状态

```dart
Future<void> restoreUserSession(String uid) async {
  final prefs = await SharedPreferences.getInstance();

  // 3.1 读取缓存的用户信息
  final userJson = prefs.getString('bilibili_user_$uid');

  if (userJson != null) {
    _bilibiliUser = BilibiliUser.fromJson(jsonDecode(userJson));
    notifyListeners();
  }

  // 3.2 后台刷新用户信息
  _refreshUserInfoInBackground(uid);
}

void _refreshUserInfoInBackground(String uid) async {
  try {
    // 调用 B站 API 获取最新用户信息
    final response = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/nav'),
      headers: {
        'Cookie': await secureStorage.getBilibiliCookie(uid, 'bilibili'),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 更新本地缓存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bilibili_user_$uid', jsonEncode(data['data']));
      notifyListeners();
    }
  } catch (e) {
    debugPrint('后台刷新用户信息失败: $e');
    // 非关键操作，失败不影响
  }
}
```

---

## ⚠️ 错误处理和恢复

### 场景 1: 二维码过期

```
情形: 用户扫码超过 3 分钟未确认
处理流程:
  ├─ 轮询返回错误码 86038 (二维码已失效)
  ├─ 停止轮询
  ├─ 显示错误提示: "二维码已过期，请重新扫码"
  ├─ 显示"重新扫码"按钮
  └─ 点击后重新生成二维码
```

**代码**:
```dart
if (pollResult['code'] == 86038) {  // 二维码已失效
  setState(() {
    _status = QRCodeStatus.expired;
  });
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('二维码已过期'),
      content: const Text('请点击"重新扫码"生成新的二维码'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _generateQRCode();  // 重新生成
          },
          child: const Text('重新扫码'),
        ),
      ],
    ),
  );
}
```

### 场景 2: Cookie 过期（运行时）

```
情形: 用户正在使用应用，Cookie 突然失效
处理流程:
  ├─ 网络请求返回 401 或 -412
  ├─ 显示错误对话框: "B站登录已过期，请重新绑定"
  ├─ 清除本地 Cookie
  ├─ 用户确认 → 跳转到绑定页面
  └─ 重新扫码绑定
```

**代码**:
```dart
if (response.statusCode == 401 || errorCode == -412) {
  // Cookie 已失效
  await _authProvider.logout(reason: 'cookie_expired');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('登录已过期'),
      content: const Text('B站登录信息已过期，请重新绑定账号'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.go('/bilibili_binding');
          },
          child: const Text('重新绑定'),
        ),
      ],
    ),
  );
}
```

### 场景 3: 网络错误

```
情形: 用户网络断开或请求超时
处理流程:
  ├─ 捕获 SocketException 或 TimeoutException
  ├─ 显示错误提示: "网络连接失败，请重试"
  ├─ 提供重试按钮
  └─ 用户点击重试 → 重新发送请求
```

**代码**:
```dart
try {
  final response = await http.get(uri).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('Request timeout'),
  );
} on SocketException catch (e) {
  showMySnackBar(context, '网络连接失败', Colors.red, 1000);
  debugPrint('网络错误: $e');
} on TimeoutException catch (e) {
  showMySnackBar(context, '请求超时，请检查网络', Colors.red, 1000);
  debugPrint('超时错误: $e');
}
```

---

## 🧪 测试场景

### 单元测试

**测试 1: 绑定流程**
```dart
test('should successfully bind bilibili account', () async {
  final uid = '272017820';
  final username = 'testuser';

  await authProvider.bindBilibiliAccount(
    uid: uid,
    username: username,
    avatar: 'https://example.com/avatar.jpg',
  );

  expect(authProvider.isBilibiliLoggedIn, true);
  expect(authProvider.bilibiliUser!.uid.toString(), uid);
  expect(authProvider.bilibiliUser!.username, username);
});
```

**测试 2: Cookie 验证**
```dart
test('should validate cookie correctly', () async {
  // 测试有效的 Cookie
  final isValid = await authService.validateCookie(validCookie);
  expect(isValid, true);

  // 测试无效的 Cookie
  final isInvalid = await authService.validateCookie(invalidCookie);
  expect(isInvalid, false);
});
```

**测试 3: 登出**
```dart
test('should logout and clear all data', () async {
  // 先登录
  await authProvider.bindBilibiliAccount(...);
  expect(authProvider.isLoggedIn, true);

  // 再登出
  await authProvider.logout();
  expect(authProvider.isLoggedIn, false);
  expect(await secureStorage.getBilibiliCookie(...), null);
});
```

### 集成测试

**测试 1: 完整绑定流程**
```dart
testWidgets('Complete binding flow', (WidgetTester tester) async {
  // 1. 启动应用
  await tester.pumpWidget(const MyApp());
  expect(find.byType(BilibiliBindingPage), findsOneWidget);

  // 2. 点击"生成二维码"
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // 3. 验证二维码显示
  expect(find.byType(QrImage), findsOneWidget);

  // 4. 模拟扫码确认
  await _mockBilibiliScan();
  await tester.pumpAndSettle();

  // 5. 验证进入主页
  expect(find.byType(HomePage), findsOneWidget);
});
```

**测试 2: 搜索功能权限**
```dart
testWidgets('Search requires authentication', (WidgetTester tester) async {
  // 1. 未登录状态下点击搜索
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // 2. 应该跳转回主页或显示登录提示
  expect(find.byType(BilibiliBindingPage), findsOneWidget);
});
```

### E2E 测试

**场景 1: 新用户首次使用**
```
1. 启动应用
2. 显示绑定页面
3. 用户点击"扫码绑定"
4. 生成二维码
5. 用户用 B站APP 扫码
6. 确认登录
7. 成功进入主页
8. 显示用户名和头像
9. 可以进行搜索和下载
```

**场景 2: 用户重启应用**
```
1. 启动应用
2. 检查本地是否有 bilibili_uid
3. 验证 Cookie 有效性
4. 显示主页（无需重新登录）
5. 显示用户状态（已登录）
```

**场景 3: Cookie 过期场景**
```
1. 用户已登录，正在搜索
2. Cookie 过期，搜索请求返回 401
3. 显示"登录已过期"对话框
4. 用户点击"重新绑定"
5. 跳转到绑定页面
6. 重新扫码绑定
7. 进入主页，恢复搜索
```

---

## 📋 集成检查清单

### 前端集成

- [ ] BilibiliAuthProvider 实现完整
- [ ] SecureStorageService 正确集成
- [ ] BilibiliBindingPage UI 完成
- [ ] SearchPage 添加认证检查
- [ ] DownloadManager 添加认证检查
- [ ] 路由保护配置
- [ ] 错误处理完整
- [ ] 加载状态显示

### 后端集成

- [ ] 数据库表创建完成
- [ ] /api/bilibili/bind 端点实现
- [ ] /api/bilibili/user/:uid 端点实现
- [ ] /api/bilibili/validate 端点实现
- [ ] /api/bilibili/unbind 端点实现
- [ ] 请求验证和错误处理
- [ ] 数据库事务正确性

### 测试覆盖

- [ ] 单元测试 > 80%
- [ ] 集成测试完成
- [ ] E2E 测试完成
- [ ] 性能测试完成
- [ ] 安全测试完成

---

**版本**: 1.0
**日期**: 2026-01-03
**状态**: 待实施
