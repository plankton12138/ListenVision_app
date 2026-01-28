开始执行迁移工作：

1. 修改 pubspec.yaml - 移除 just_audio 和 just_audio_windows，添加 audioplayers
2. 重构 playback_controller.dart - 适配 audioplayers API
3. 修改 audio_provider.dart - 更新状态映射
4. 修改 controls_panel.dart - 适配新的状态枚举
5. 运行测试验证

预计总时间：3-4小时