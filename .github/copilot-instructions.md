# ListenVision development instructions

- 用中文回复。项目为纯 Flutter 前端，直连 B站 API，数据存储在 SQLite，没有 Python 后端、账号注册或 JWT 同步流程。
- Flutter 3.41.9 / Dart 3.11；MVVM + Riverpod 3 + Freezed，播放器为 media_kit，数据库版本以 AppDatabase.schemaVersion 为准。
- Windows 使用 PowerShell；优先扩展已有目录。presentation/providers.dart 只导出 Provider。

## 开发检查

在 frontend_flutter 中运行：

```text
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

应用需提交 pubspec.lock。改动生成代码对应的源文件后重新运行生成器，提交生成结果；不要手工修改生成文件。CI 对生成结果的一致性做检查。

## 主要边界

- View → ViewModel → Service / Repository → DAO；数据库事务、批量排序在数据层完成。
- B站请求通过 BilibiliApiService 注入统一 Dio；取消不是用户错误，不应自动重试。下载独立采用长接收超时。
- PlaybackViewModel 串行处理设源与播放命令；旧请求不得恢复播放、覆盖 UI 或写入历史。进度单独监听，封面和控制组件监听所需字段。
- Android 系统媒体服务与 Activity 共用唯一 Flutter 引擎，通过 BackgroundAudioService 转发系统操作；media_kit 始终是唯一播放引擎。
- 下载直连 CDN，使用任务私有片段和验证信息；只有校验过的 206 才追加，200 响应必须截断旧文件。
- 转换使用可取消的 FFmpeg 进程、临时输出和成功后重命名；移动端当前只提供 M4A。
- 日志使用 AppLogger；权限按实际操作请求；令牌与签名 URL 不记录完整值。

## 验证重点

使用临时数据库和假服务测试迁移、竞态、下载取消及文件完整性。后台播放的锁屏、耳机和音频焦点行为需要 Android 真机验收；单元测试和构建不能代替真机验证。
