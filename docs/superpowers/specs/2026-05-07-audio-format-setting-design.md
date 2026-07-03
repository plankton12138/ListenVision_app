# 下载音频格式切换 — 设计文档

**日期**: 2026-05-07
**状态**: 已确认

---

## 概述

在设置页面新增下载音频格式选择功能，用户可选择 **默认（m4a）** 或 **MP3**，全局生效。

---

## 背景

- 当前 `BilibiliDownloader` 始终输出 `.m4a`（m4s 重命名，零转换），用户无法选择格式
- `AudioFormat` 枚举已在 `api_constants.dart` 中定义但未接入下载流程
- 后端 SSE 端点 `/bilibili/download/{bvid}?format=mp3` 已支持 MP3 转换
- 设置页目前仅有主题切换和账号绑定，无下载偏好设置

---

## 设计

### 1. 存储层

**`storage_constants.dart`** — 新增键：

```dart
static const String downloadFormat = 'download_format'; // 'm4a' | 'mp3'
```

**`shared_storage_service.dart`** — 新增存取方法，默认 `'m4a'`：

```dart
String getDownloadFormat() => getString(StorageConstants.downloadFormat) ?? 'm4a';
Future<void> setDownloadFormat(String format) => setString(StorageConstants.downloadFormat, format);
```

### 2. 设置 UI

在 `SettingsPage` 深色模式卡片下方新增"下载音质"卡片：

- 两个选项：**默认格式 (m4a)** / **MP3**
- 使用 `SharedStorageService` 直接读写，无需额外 ViewModel
- 不创建新的 ViewModel 文件（全局单一设置，逻辑足够简单）

### 3. 下载流程

`DownloadRepository` 在 `addDownload()` 创建任务时读取格式设置，在下载时路由到不同路径：

| 格式 | 下载路径 | 转换方式 |
|------|----------|----------|
| m4a（默认） | `BilibiliDownloader` | 零转换，m4s→m4a 重命名 |
| mp3 | `DownloadService` | 后端 SSE `/bilibili/download/{bvid}?format=mp3` |

- 两条路径共享进度回调、断点续传、卡死检测等基础设施
- `DownloadTask` 模型不变（不新增 format 字段）

---

## 影响范围

| 文件 | 改动 |
|------|------|
| `lib/core/constants/storage_constants.dart` | 新增 `downloadFormat` 键 |
| `lib/core/storage/shared_storage_service.dart` | 新增 getter/setter |
| `lib/presentation/views/system/settings_page.dart` | 新增格式选择卡片 |
| `lib/data/repositories/download_repository.dart` | 根据格式分流下载路径 |

---

## 不做的

- 不在 `DownloadTask` 模型中存储 format 字段（无需追溯，全局设置已决定）
- 不新建 ViewModel 或 Service（逻辑足够简单）
- 不支持单任务格式覆盖（用户确认只需全局设置）
- 不引入客户端 ffmpeg 转换（复用后端已有能力）

---

## 测试计划

- 设置页 UI：切换格式后重启 App，验证设置持久化
- 下载 m4a：设置"默认"后触发下载，验证输出 `.m4a` 文件
- 下载 mp3：设置"MP3"后触发下载，验证输出 `.mp3` 文件可播放
- 切换格式：下载过程中切换格式，验证不影响进行中的任务
