# 日志记录规范

本文档定义了项目的日志记录标准和最佳实践。

## 日志级别

### 后端 (Python)

| 级别 | 使用场景 | 示例 |
|------|---------|------|
| `ERROR` | 系统错误、异常、外部服务调用失败 | 数据库连接失败、API 调用超时 |
| `WARNING` | 可能的问题、降级服务使用、重试操作 | Cookie 解密失败、缓存未命中 |
| `INFO` | 用户操作、业务流程开始/完成、关键状态变化 | 用户登录、播放开始、文件下载完成 |
| `DEBUG` | 详细执行流程、中间变量值、性能数据 | API 响应内容、状态转换详情 |

### 前端 (Flutter - AppLogger)

| 级别 | 使用场景 | 示例 |
|------|---------|------|
| `ERROR` | 系统错误、用户操作失败 | 网络请求失败、播放出错 |
| `WARN` | 可能的问题、警告 | 缓存失效、配置缺失 |
| `INFO` | 用户操作、业务流程 | 按钮点击、页面导航、登录成功 |
| `DEBUG` | 详细执行流程、调试信息 | 状态变化、数据加载过程 |

## 日志格式规范

### 后端日志格式 (Python)

```python
from app.utils.logger import logger

# 基本格式
logger.info("操作描述", extra={"key1": value1, "key2": value2})

# 带异常信息
logger.error("操作失败", exc_info=True)

# 敏感信息处理
logger.info("登录成功", extra={"userId": user.id})
# password 字段不记录
```

### 前端日志格式

```dart
// 基本格式
AppLogger.info('模块名', '操作描述', extra: {'key': 'value'});

// 用户操作追踪
AppLogger.logButtonClick('按钮名', '页面/组件名',
  parameters: {'key': 'value'},
  userId: userId,
);

// 导航追踪
AppLogger.logNavigation('来源页面', '目标页面');

// 表单提交
AppLogger.logFormSubmit('表单名', {'field1': 'value1'});
```

## 必须记录的操作

### 用户操作

| 操作 | 后端 | 前端 |
|------|------|------|
| 登录/登出 | ✅ | ✅ |
| 播放/暂停/停止 | ✅ | ✅ (UI层) |
| 切换歌曲 | ✅ | ✅ (UI层) |
| 添加/删除收藏 | ✅ | ✅ (UI层) |
| 创建/删除歌单 | ✅ | ✅ (UI层) |
| 搜索 | ✅ | ✅ (UI层) |
| 页面导航 | - | ✅ (自动) |

### 系统操作

| 操作 | 日志级别 |
|------|---------|
| API 请求/响应 | info/debug |
| 数据库操作 | debug |
| 文件操作 | info |
| 外部服务调用 | info |
| 缓存命中/未命中 | debug |

## 敏感信息处理

以下字段必须脱敏（使用 `[REDACTED]` 或不记录）：

- `password` / `pwd`
- `token` (除 refresh_token 外)
- `cookie` (仅记录是否存在)
- `authCode`
- `secret`
- `apiKey`

```javascript
// 正确做法
logger.info('用户登录', {
  userId: user.id,
  // password 不记录
});

// 错误做法
logger.info('用户登录', {
  userId: user.id,
  password: user.password, // ❌ 不要记录密码
});
```

## 日志分层架构

```
┌─────────────────────────────────────────────┐
│  UI 层日志（用户点击、导航）                  │
│  AppLogger.logButtonClick()                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Provider 层日志（业务触发）                  │
│  Provider 方法调用                           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Controller 层日志（执行结果）                │
│  PlaybackController 状态变化                │
└─────────────────────────────────────────────┘
```

## 日志文件位置

| 类型 | 位置 |
|------|------|
| 前端 | `C:\Users\<用户>\Documents\logs\` |
| 后端 | `listen-vision-api-python/logs/` |

查看最新日志：
```powershell
# 后端
Get-Content "listen-vision-api-python/logs/app.log" -Tail 50

# 前端
Get-Content "$env:USERPROFILE\Documents\logs\app_*.log" -Tail 50
```
