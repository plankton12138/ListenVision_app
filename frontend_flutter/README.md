# 🎵 ListenVision Flutter Client

> ListenVision 的 Flutter 客户端，当前实现以 **Riverpod + MVVM/Repository + 本地优先同步** 为主。

## 项目定位

客户端负责以下能力：

- 邮箱登录、平台账号绑定与游客模式
- Bilibili / 网易云相关内容浏览、搜索与播放
- 本地音频导入、下载管理、播放队列
- SQLite 持久化、文件完整性校验
- 统一日志、统一错误提示、网络状态监听

## 当前目录结构

```
frontend_flutter/
├── lib/
│   ├── core/
│   │   ├── config/           # 环境配置
│   │   ├── constants/        # 常量
│   │   ├── errors/           # 异常与错误处理
│   │   ├── models/           # 核心模型（网络状态等）
│   │   ├── network/          # DioClient、ApiClient、端点常量
│   │   ├── state/            # 通用状态辅助
│   │   ├── storage/          # 本地存储
│   │   └── utils/            # AppLogger、权限、元数据等工具
│   ├── data/
│   │   ├── api/              # 兼容层 API 客户端（逐步迁移中）
│   │   ├── database/         # DAO 与 SQLite 访问
│   │   └── repositories/     # Repository 实现
│   ├── models/               # DTO / Entity / Freezed 模型
│   ├── presentation/
│   │   ├── routes/           # go_router 配置
│   │   ├── theme/            # 主题定义
│   │   ├── utils/            # UI 辅助
│   │   ├── viewmodels/       # Riverpod ViewModel
│   │   ├── views/            # 页面
│   │   └── widgets/          # 复用组件
│   ├── services/             # AudioPlayer、Metadata、DownloadIntegrity 等服务
│   ├── app.dart
│   └── main.dart
├── test/
├── integration_test/
└── pubspec.yaml
```

## 关键约定

- 包名：`listenvision`
- 状态管理：`flutter_riverpod` + `riverpod_annotation`
- `presentation/providers.dart` 仅做导出，不放 Provider 实现
- 网络访问优先通过 `lib/core/network/api_client.dart`
- 写操作遵循”本地先写入，再排队同步”

## 最近变更 (2026-03-22)

- **移除 `bidirectional_sync_worker.dart`**：该文件依赖不存在的模块导致编译错误，双向同步功能待重新设计
- **修复 B站音频播放**：正确传递凭证到音频代理，修复图片加载
- **修复未登录搜索历史**：游客模式下搜索历史正常工作

## 常用命令

```bash
cd frontend_flutter
flutter pub get
flutter run
flutter analyze
flutter test
flutter test --coverage
flutter pub run build_runner build --delete-conflicting-outputs
```

## Web 与原生差异

- Web 端不支持完整的本地文件系统访问，因此下载、目录扫描、持久化等能力受限。
- 原生平台（Android / iOS / Windows / Linux / macOS）可获得更完整的本地优先体验。

## 相关文档

- [主 README](../README.md)
- [项目 PRD](../docs/PRD.md)
- [CLAUDE.md](../CLAUDE.md)
- [AGENTS.md](../AGENTS.md)
