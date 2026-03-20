# 前端 MVVM 架构优化和后端 RESTful 规范化实施计划（优化版）

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 聚焦核心问题——统一控制器错误流、打通前后端异常体系、修复少量不一致的 ViewModel

**Architecture:**
- 前端：打通 `ApiException` 与 `ServerException/NetworkException`，统一异常源头；修复 DioClient 的 401 处理
- 后端：推广 `catchAsync + AppError` 模式，减少控制器中分散的 `try/catch + errorResponse`

**Tech Stack:**
- 前端：Flutter 3.38.5, Riverpod 3, Dio
- 后端：Node.js, Express, express-validator, express-rate-limit

---

## 现状评估（GPT 评审结论）

| 模块 | 现状 | 计划合理性 |
|------|------|------------|
| **后端限流** | `rateLimiter.js` 已存在，功能完善 | ❌ 计划中的新增是重复建设 |
| **后端验证** | `validator.js` 已存在，使用 express-validator | ❌ 计划中的新增是重复建设 |
| **前端异常** | `exceptions.dart` 已有完整体系 | ❌ 计划再建一套会冲突 |
| **MVVM 模式** | 主体已统一，`PlayerViewModel`是同步 build | ⚠️ 部分任务不合适 |
| **后端响应** | `response.js` 已统一，但控制器使用不一致 | ✅ 需要优化 |
| **端点常量** | `endpoints.dart` 有下载/设置端点但后端未实现 | ⚠️ 需要先实现后端 |

---

## 文件结构总览（优化后）

### 前端修改文件

| 类型 | 文件路径 | 说明 |
|------|----------|------|
| 修改 | `lib/core/errors/exceptions.dart` | 添加 factory 方法从 API 响应创建 |
| 修改 | `lib/core/network/dio_client.dart` | 增强 401 处理，统一异常转换 |
| 修改 | `lib/models/dto/api_dto.dart` | 移除废弃的 ApiException |
| 修改 | `lib/presentation/viewmodels/player/player_viewmodel.dart` | 修复状态更新模式 |

### 后端修改文件

| 类型 | 文件路径 | 说明 |
|------|----------|------|
| 修改 | `controllers/bilibiliController.js` | 改用 catchAsync + AppError |
| 修改 | `controllers/neteaseController.js` | 改用 catchAsync + AppError |
| 修改 | `controllers/audioController.js` | 改用 catchAsync + AppError |
| 修改 | `routes/auth.js` | 集成 rateLimiter 中间件 |
| 修改 | `routes/bilibili.js` | 集成 rateLimiter 中间件 |

---

## Task 1: 打通前端异常体系

**Files:**
- Modify: `frontend_flutter/lib/core/errors/exceptions.dart`
- Modify: `frontend_flutter/lib/core/network/dio_client.dart`
- Modify: `frontend_flutter/lib/models/dto/api_dto.dart`

### 背景

当前前端存在两套异常体系：
1. `core/errors/exceptions.dart` - 新异常体系（`ServerException`, `NetworkException` 等）
2. `models/dto/api_dto.dart` - 旧 `ApiException`

导致问题：
- `dio_client.dart` 中混合使用两种异常
- ViewModel 中需要处理多种异常类型

### 目标

统一为单一异常来源，所有网络异常通过 `exceptions.dart` 中的类表示。

---

- [ ] **Step 1: 在 exceptions.dart 中添加 API 异常工厂方法**

编辑 `frontend_flutter/lib/core/errors/exceptions.dart`，在文件末尾添加：

```dart
// ==================== API 响应异常 ====================

/// API 响应异常
///
/// 从后端返回的错误响应创建的异常
class ApiServerException extends ServerException {
  const ApiServerException(super.message, [super.code, super.statusCode]);

  /// 从 API 响应创建异常
  /// [response] 后端返回的 error 字段
  /// [statusCode] HTTP 状态码
  factory ApiServerException.fromResponse({
    required String error,
    required int statusCode,
    String? code,
  }) {
    return ApiServerException(
      error,
      code ?? 'API_ERROR',
      statusCode,
    );
  }

  /// 从后端错误码映射到异常
  factory ApiServerException.fromErrorCode(String errorCode) {
    switch (errorCode) {
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        return const ApiServerException('登录已过期', 'TOKEN_EXPIRED', 401);
      case 'NOT_LOGGED_IN':
        return const ApiServerException('请先登录', 'NOT_LOGGED_IN', 401);
      case 'FORBIDDEN':
        return const ApiServerException('无权限访问', 'FORBIDDEN', 403);
      case 'NOT_FOUND':
        return const ApiServerException('资源不存在', 'NOT_FOUND', 404);
      case 'VALIDATION_ERROR':
        return const ApiServerException('参数验证失败', 'VALIDATION_ERROR', 400);
      case 'RATE_LIMITED':
        return const ApiServerException('请求过于频繁', 'RATE_LIMITED', 429);
      default:
        return const ApiServerException('服务器错误', 'SERVER_ERROR', 500);
    }
  }
}
```

- [ ] **Step 2: 更新 DioClient 统一异常转换**

编辑 `frontend_flutter/lib/core/network/dio_client.dart`，找到 `_handleDioError` 方法，更新为：

```dart
/// 处理 Dio 异常
Exception _handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException.timeout();
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;

      // 尝试从响应中解析错误信息
      String errorMessage = '请求失败';
      String? errorCode;

      if (data is Map<String, dynamic>) {
        errorMessage = data['error'] as String?
                    ?? data['message'] as String?
                    ?? '请求失败';
        errorCode = data['code'] as String?;
      }

      // 返回 ApiServerException
      return ApiServerException.fromResponse(
        error: errorMessage,
        statusCode: statusCode,
        code: errorCode,
      );
    case DioExceptionType.cancel:
      return const TaskCanceledException();
    case DioExceptionType.connectionError:
      return const NetworkException.noConnection();
    case DioExceptionType.badCertificate:
      return const NetworkException('证书错误', 'BAD_CERTIFICATE');
    case DioExceptionType.unknown:
    default:
      // 检查是否是网络错误
      if (error.error is SocketException) {
        return const NetworkException.noConnection();
      }
      return const NetworkException.requestFailed();
  }
}
```

- [ ] **Step 3: 移除 api_dto.dart 中的废弃 ApiException**

编辑 `frontend_flutter/lib/models/dto/api_dto.dart`，删除或注释掉旧的 `ApiException` 类：

```dart
// 已废弃 - 请使用 core/errors/exceptions.dart 中的异常
// class ApiException implements Exception { ... }
```

然后在文件顶部添加导入说明：

```dart
// 注意：如需处理 API 异常，请使用
// import 'package:listen_vision/core/errors/exceptions.dart';
// 中的 ApiServerException
```

- [ ] **Step 4: 更新 api_client.dart 中的异常处理**

编辑 `frontend_flutter/lib/core/network/api_client.dart`，在 `_handleResponse` 方法中：

```dart
/// 解析响应，检查成功状态并返回数据
dynamic _handleResponse(Map<String, dynamic> response) {
  if (response['success'] == true) {
    return response['data'];
  } else {
    // 使用新的异常类型
    final statusCode = response['statusCode'] as int? ?? 500;
    final error = response['error'] as String? ?? response['message'] as String? ?? '请求失败';
    final code = response['code'] as String?;

    throw ApiServerException.fromResponse(
      error: error,
      statusCode: statusCode,
      code: code,
    );
  }
}
```

- [ ] **Step 5: 运行测试验证**

```bash
cd frontend_flutter
flutter analyze
flutter test test/core/errors/  # 如果有异常相关测试
```

Expected: 无分析错误，测试通过

- [ ] **Step 6: Commit**

```bash
git add frontend_flutter/lib/core/errors/exceptions.dart
git add frontend_flutter/lib/core/network/dio_client.dart
git add frontend_flutter/lib/models/dto/api_dto.dart
git add frontend_flutter/lib/core/network/api_client.dart
git commit -m "refactor(frontend): 统一异常处理体系

- 新增 ApiServerException 从 API 响应创建异常
- 更新 DioClient 统一返回新异常类型
- 移除 api_dto.dart 中废弃的 ApiException
- ViewModel 现在只需处理单一异常来源"
```

---

## Task 2: 统一后端控制器错误流

**Files:**
- Modify: `listen-vision_api/controllers/bilibiliController.js`
- Modify: `listen-vision_api/controllers/neteaseController.js`
- Modify: `listen-vision_api/controllers/audioController.js`

### 背景

当前后端控制器存在两种错误处理模式：
1. `authController.js` - 使用 `catchAsync + AppError`（推荐）
2. `bilibiliController.js` - 分散的 `try/catch + errorResponse`（需统一）

### 目标

所有控制器统一使用 `catchAsync + AppError` 模式，减少代码重复。

---

- [ ] **Step 1: 检查 errorHandler.js 中的 catchAsync 和 AppError**

确认 `listen-vision_api/middleware/errorHandler.js` 导出：
- `AppError` 类
- `catchAsync` 函数

- [ ] **Step 2: 重构 bilibiliController.js**

编辑 `listen-vision_api/controllers/bilibiliController.js`，示例改造：

**改造前（旧模式）：**
```javascript
const getQRCode = async (req, res) => {
  try {
    const result = await bilibiliService.getQRCode();
    return successResponse(res, result, 'QR 码获取成功');
  } catch (error) {
    logger.error('获取 QR 码失败：%s', error.message);
    return errorResponse(res, error.message, 500);
  }
};
```

**改造后（新模式）：**
```javascript
const { AppError, catchAsync } = require('../middleware/errorHandler');

const getQRCode = catchAsync(async (req, res) => {
  const result = await bilibiliService.getQRCode();
  return successResponse(res, result, 'QR 码获取成功');
});
```

对整个文件执行相同改造：
1. 顶部导入 `catchAsync` 和 `AppError`
2. 移除所有外层的 `try/catch`
3. 用 `catchAsync` 包装异步函数

- [ ] **Step 3: 在 Service 层抛出 AppError**

编辑 `listen-vision_api/services/bilibiliService.js`，在关键错误点抛出 `AppError`：

```javascript
const { AppError } = require('../middleware/errorHandler');

// 改造前
if (data.code !== 0) {
  throw new Error(data.message || '获取 QR 码失败');
}

// 改造后
if (data.code !== 0) {
  throw new AppError(data.message || '获取 QR 码失败', 400, 'BILIBILI_API_ERROR');
}
```

- [ ] **Step 4: 重构 neteaseController.js 和 audioController.js**

执行与 Step 2 相同的改造。

- [ ] **Step 5: 运行测试验证**

```bash
cd listen-vision_api
pnpm test
```

Expected: 所有测试通过

- [ ] **Step 6: Commit**

```bash
git add listen-vision_api/controllers/bilibiliController.js
git add listen-vision_api/controllers/neteaseController.js
git add listen-vision_api/controllers/audioController.js
git add listen-vision_api/services/bilibiliService.js
git commit -m "refactor(backend): 统一控制器错误流

- 所有控制器改用 catchAsync + AppError 模式
- Service 层抛出 AppError 替代 Error
- 减少重复的 try/catch 代码
- 错误由全局 errorHandler 统一处理"
```

---

## Task 3: 修复 PlayerViewModel 状态更新模式

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart`

### 背景

`PlayerViewModel` 使用同步 `build()` 返回初始状态，但计划中建议改为 `Future`，这不合适。播放器需要在初始化时建立流监听，同步返回更合理。

### 目标

保持同步 `build()`，但修复状态更新的一致性问题。

---

- [ ] **Step 1: 检查当前 PlayerViewModel 模式**

读取 `player_viewmodel.dart` 确认：
- `build()` 是否同步返回
- 状态更新是否使用 `state = AsyncData(...)` 或 `state = state.value.copyWith(...)`

- [ ] **Step 2: 修复状态更新模式**

确保所有状态更新遵循：
```dart
// 正确：使用 copyWith 更新状态
state = AsyncData(state.value!.copyWith(isPlaying: true));

// 正确：直接设置新状态
state = AsyncData(PlayerState.playing());

// 避免：直接修改 state.value
state.value!.isPlaying = true; // 错误：不会触发重建
```

- [ ] **Step 3: Commit**

```bash
git add frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart
git commit -m "fix(frontend): 修复 PlayerViewModel 状态更新

- 保持同步 build() 以支持流监听初始化
- 修复状态更新使用 copyWith 模式
- 添加注释说明状态管理规范"
```

---

## Task 4: 在路由中集成限流中间件

**Files:**
- Modify: `listen-vision_api/routes/auth.js`
- Modify: `listen-vision_api/routes/bilibili.js`

### 背景

`rateLimiter.js` 已存在但未在所有需要的路由中使用。

### 目标

在认证和 B 站相关路由中集成限流中间件。

---

- [ ] **Step 1: 在 auth.js 中集成限流**

编辑 `listen-vision_api/routes/auth.js`：

```javascript
const { loginLimiter, registerLimiter, sendCodeLimiter } = require('../middleware/rateLimiter');

// 登录限流
router.post('/login', loginLimiter, authController.login);

// 注册限流
router.post('/register', registerLimiter, authController.register);

// 发送验证码限流
router.post('/send-code', sendCodeLimiter, authController.sendResetCode);
```

- [ ] **Step 2: 在 bilibili.js 中集成限流**

编辑 `listen-vision_api/routes/bilibili.js`：

```javascript
const { strictLimiter } = require('../middleware/rateLimiter');

// B 站相关操作限流
router.use(strictLimiter);
```

- [ ] **Step 3: Commit**

```bash
git add listen-vision_api/routes/auth.js
git add listen-vision_api/routes/bilibili.js
git commit -m "feat(backend): 在路由中集成限流中间件

- auth 路由集成登录/注册/发送验证码限流
- bilibili 路由集成严格限流
- 防止 API 滥用和暴力破解"
```

---

## 验收标准

| Task | 验收项 | 状态 |
|------|--------|------|
| Task 1 | 前端异常统一为 `ApiServerException` | ☐ |
| Task 1 | `dio_client.dart` 不再返回旧 `ApiException` | ☐ |
| Task 2 | 所有控制器使用 `catchAsync + AppError` | ☐ |
| Task 2 | 后端测试全部通过 | ☐ |
| Task 3 | `PlayerViewModel` 状态更新规范 | ☐ |
| Task 4 | 认证路由有限流保护 | ☐ |
| Task 4 | B 站路由有限流保护 | ☐ |

---

## 被移除的原计划任务（说明原因）

| 原任务 | 移除原因 |
|--------|----------|
| Task 1 (原): 创建统一异常类 | `exceptions.dart` 已存在完整体系 |
| Task 2 (原): 创建 API 中间件层 | 与现有架构不符，DioClient 已承担此职责 |
| Task 5 (原): 统一响应格式 | `response.js` 已统一，只需推广使用 |
| Task 6 (原): 增强错误处理中间件 | `errorHandler.js` 功能完整 |
| Task 7 (原): 实现限流中间件 | `rateLimiter.js` 已存在且功能完善 |

---

## 执行建议

1. **先执行 Task 1**（前端异常统一）- 影响面最大，需要先打通
2. **再执行 Task 2**（后端错误流统一）- 与前端改造配合
3. **然后执行 Task 3**（ViewModel 修复）- 小范围修正
4. **最后执行 Task 4**（限流集成）- 简单配置

---

## 预期成果

1. **前端异常统一** - 只需处理 `ApiServerException` 和 `NetworkException`
2. **后端错误流统一** - 控制器代码更简洁，错误处理集中
3. **限流保护** - 敏感操作有频率限制

**不做的改进**（已有完整实现）：
- 限流中间件
- 验证中间件
- 响应格式工具
- 错误处理中间件
