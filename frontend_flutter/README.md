# 🎵 ListenVision Flutter 前端

> 基于 Clean Architecture 的跨平台音频应用前端

---

## 📖 项目简介

ListenVision Flutter 前端采用 **Clean Architecture** 架构设计,实现了完整的音频播放、搜索、下载和管理功能。

### 核心特性

- 🎵 **音频播放** - 支持本地和在线音频,M4A/MP3/FLAC 元数据
- 🔍 **搜索功能** - 搜索 B站 视频和音频内容
- 📥 **下载管理** - 多线程下载、断点续传、后台下载
- 📋 **播放列表** - 创建、管理歌单,收藏音步
- 🎨 **Material Design** - 深色模式支持
- 🔐 **账号体系** - 邮箱登录 + B站账号绑定

---

## 🏗️ 架构设计

### Clean Architecture 分层

```
lib/
├── main.dart             # 应用入口
├── core/                 # 核心层 (基础设施)
│   ├── base/             # 基类
│   ├── constants/        # 常量
│   ├── di/               # 依赖注入
│   ├── errors/           # 错误定义
│   ├── network/          # 网络层
│   └── utils/            # 工具函数
├── domain/               # 领域层 (业务逻辑)
│   ├── entities/         # 领域实体
│   └── repositories/     # 仓储接口
├── data/                 # 数据层 (数据操作)
│   ├── datasources/      # 数据源
│   │   ├── local/        # 本地数据源
│   │   └── remote/       # 远程数据源
│   ├── managers/         # 管理器
│   └── repositories/     # 仓储实现
└── presentation/         # 表现层 (UI)
    ├── pages/            # 页面
    ├── providers/        # 状态管理
    ├── routes/           # 路由
    └── widgets/          # 组件
```

### 各层职责

| 层级 | 职责 | 示例 |
|------|------|------|
| **Core** | 基础设施、工具 | DioProvider, ServiceFactory, Logger |
| **Domain** | 业务规则、抽象接口 | Audio Entity, DownloadRepository |
| **Data** | 数据操作、实现 | BilibiliRemoteDataSource, SQLite |
| **Presentation** | UI、状态 | Pages, Providers, Widgets |

### 数据流示例

```
用户点击下载
        │
        ▼
    Page (UI)
        │
        ▼
    Provider (状态管理)
        │
        ▼
    Repository Interface (抽象)
        │
        ▼
    Repository Impl (实现)
        │
        ├──→ DataSource (数据获取)
        └──→ Manager (任务处理)
```

---

## 📂 目录结构

```
lib/
├── main.dart                         # 应用入口点
├── core/
│   ├── base/
│   │   ├── base_entity.dart          # 实体基类
│   │   └── base_provider.dart        # Provider 基类
│   ├── constants/
│   │   ├── api_constants.dart        # API 常量
│   │   └── app_constants.dart        # 应用常量
│   ├── di/
│   │   └── service_factory.dart      # 依赖注入工厂
│   ├── errors/
│   │   ├── exceptions.dart           # 异常定义
│   │   └── failures.dart             # 失败类型
│   ├── network/
│   │   └── dio_provider.dart         # Dio 全局配置
│   └── utils/
│       ├── dialog_helper.dart        # 对话框工具
│       ├── file_picker_helper.dart   # 文件选择器
│       ├── metadata_writer.dart      # 元数据写入
│       └── permission_helper.dart    # 权限管理
│
├── domain/
│   ├── entities/
│   │   ├── audio.dart                # 在线音频实体 (Freezed)
│   │   ├── local_audio.dart          # 本地音频实体
│   │   ├── download_task.dart        # 下载任务实体
│   │   ├── user.dart                 # 用户实体
│   │   ├── playlist.dart             # 歌单实体
│   │   ├── play_history.dart         # 播放历史实体
│   │   ├── recommendation.dart       # 推荐实体
│   │   ├── platform_account.dart     # 平台账号实体
│   │   ├── platform_types.dart       # 平台类型枚举
│   │   ├── domain_types.dart         # 领域类型
│   │   └── models_export.dart        # 统一导出
│   └── repositories/
│       ├── auth_repository.dart      # 认证仓储接口
│       ├── bilibili_repository.dart  # B站仓储接口
│       ├── download_repository.dart  # 下载仓储接口
│       ├── play_history_repository.dart
│       ├── playlist_repository.dart
│       └── search_repository.dart
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── download_local_datasource.dart
│   │   │   └── auth_local_datasource.dart
│   │   └── remote/
│   │       ├── bilibili_remote_datasource.dart
│   │       ├── bilibili_api_datasource.dart
│   │       ├── auth_remote_datasource.dart
│   │       ├── playlist_remote_datasource.dart
│   │       ├── play_history_remote_datasource.dart
│   │       └── search_remote_datasource.dart
│   ├── managers/
│   │   ├── playlist_manager.dart     # 播放列表管理
│   │   └── download_executor.dart    # 下载执行器
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── bilibili_repository_impl.dart
│       ├── download_repository_impl.dart
│       ├── play_history_repository_impl.dart
│       ├── playlist_repository_impl.dart
│       └── search_repository_impl.dart
│
└── presentation/
    ├── pages/
    │   ├── home_page.dart            # 首页
    │   ├── login_page.dart           # 登录页
    │   ├── register_page.dart        # 注册页
    │   ├── reset_password_page.dart  # 重置密码页
    │   ├── search_page.dart          # 搜索页
    │   ├── play_list_page.dart       # 播放列表页
    │   ├── backend_download_page.dart # 下载管理页
    │   ├── download_list_page.dart   # 下载列表页
    │   ├── settings_page.dart        # 设置页
    │   └── ...
    ├── providers/
    │   ├── auth/                     # 认证状态
    │   │   ├── auth_provider.dart
    │   │   └── ...
    │   ├── audio/                    # 音频播放
    │   │   ├── audio_provider.dart
    │   │   └── audio_player_provider.dart
    │   ├── bilibili/                # B站功能
    │   │   ├── bilibili_provider.dart
    │   │   ├── cache_provider.dart
    │   │   └── qr_login_provider.dart
    │   ├── playlist/                # 歌单管理
    │   │   └── playlist_provider.dart
    │   ├── search/                  # 搜索功能
    │   │   └── search_provider.dart
    │   ├── download/                # 下载管理
    │   │   └── download_manager.dart
    │   ├── play_history/            # 播放历史
    │   │   └── play_history_provider.dart
    │   └── theme/                   # 主题
    │       └── theme_provider.dart
    ├── routes/
    │   └── router.dart              # 路由配置
    └── widgets/
        ├── my_drawer.dart           # 抽屉导航
        └── ...
```

---

## 🚀 快速开始

### 安装依赖

```bash
cd frontend_flutter
flutter pub get
```

### 运行应用

```bash
# 开发模式
flutter run

# 构建发布
flutter build apk          # Android
flutter build ios          # iOS
flutter build windows      # Windows
flutter build linux        # Linux
flutter build macos        # macOS
flutter build web          # Web
```

### 代码检查

```bash
# 分析代码
flutter analyze

# 运行测试
flutter test
```

---

## 🛠️ 开发指南

### 添加新功能

1. **创建实体** (`domain/entities/`)
```dart
class MyEntity {
  final String id;
  final String name;
  
  const MyEntity({required this.id, required this.name});
}
```

2. **创建仓储接口** (`domain/repositories/`)
```dart
abstract class MyRepository {
  Future<MyEntity> getById(String id);
  Future<List<MyEntity>> getAll();
}
```

3. **创建数据源** (`data/datasources/`)
```dart
class MyLocalDataSource {
  Future<Map<String, dynamic>> get(String id) async {
    // 数据库操作
  }
}
```

4. **创建仓储实现** (`data/repositories/`)
```dart
class MyRepositoryImpl implements MyRepository {
  final MyLocalDataSource localDS;
  
  @override
  Future<MyEntity> getById(String id) async {
    final map = await localDS.get(id);
    return MyEntity.fromMap(map);
  }
}
```

5. **注册到依赖注入** (`core/di/service_factory.dart`)
```dart
static late MyRepository myRepository;

static Future<void> init() async {
  myRepository = MyRepositoryImpl(
    localDS: MyLocalDataSource(),
  );
}
```

6. **创建 Provider** (`presentation/providers/`)
```dart
class MyProvider extends ChangeNotifier {
  final MyRepository _repository;
  
  MyProvider({required MyRepository repository}) : _repository = repository;
  
  Future<void> loadData() async {
    final data = await _repository.getAll();
    notifyListeners();
  }
}
```

7. **创建页面** (`presentation/pages/`)
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyProvider(
        repository: ServiceFactory.myRepository,
      ),
      child: Consumer<MyProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: Center(child: Text('My Page')),
          );
        },
      ),
    );
  }
}
```

### 代码规范

- **命名**: 遵循 Dart 官方命名规范
- **注释**: 代码注释使用英文
- **导入**: 按标准顺序组织导入
- **错误处理**: 使用 `Either<Failure, T>` 类型

### 导入顺序规范

```dart
// 1. Dart SDK 导入
import 'dart:async';
import 'dart:io';

// 2. Flutter 框架导入
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 3. 第三方包导入
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';

// 4. 项目内部导入 (按层级)
import 'package:demo/core/...';
import 'package:demo/domain/...';
import 'package:demo/data/...';
import 'package:demo/presentation/...';
```

---

## 📦 依赖配置

### 核心依赖

```yaml
# 状态管理
provider: ^6.1.4

# 路由
go_router: ^14.8.1

# 数据库
sqflite: ^2.4.2
sqflite_common_ffi: ^2.3.5  # 桌面端

# 网络
dio: ^5.8.0+1

# 音频
audioplayers: ^6.4.0
metadata_god: ^0.5.2+1

# 错误处理
dartz: ^0.10.1

# JSON 序列化
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0

# 加密存储
flutter_secure_storage: ^9.0.0

# 工具
path: ^1.9.0
path_provider: ^2.1.5
shared_preferences: ^2.3.3
```

---

## 🧪 测试

### 单元测试

```bash
# 运行所有测试
flutter test

# 运行单个文件
flutter test test/domain/entities/audio_test.dart

# 生成覆盖率报告
flutter test --coverage
```

### 示例测试

```dart
void main() {
  test('Audio entity should parse correctly', () {
    final json = {'title': 'Test', 'artist': 'Artist'};
    final audio = Audio.fromJson(json);
    
    expect(audio.title, 'Test');
    expect(audio.artist, 'Artist');
  });
}
```

---

## 📚 相关文档

- **[主 README](../README.md)** - 项目主文档
- **[CLAUDE.md](../CLAUDE.md)** - Claude Code 开发指导
- **[AGENTS.md](../AGENTS.md)** - Agent 开发指南
- **[PRD.md](../PRD.md)** - 产品需求文档

---

## 📄 开源协议

MIT License - 详见项目根目录 LICENSE 文件。

---

<div align="center">

**如果觉得这个项目有帮助,请给个 ⭐️ Star 支持一下!**

Made with ❤️ by ListenVision Team

</div>
