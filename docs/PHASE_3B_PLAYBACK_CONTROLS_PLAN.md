# Phase 3B: 播放控制增强计划

> **创建日期**: 2026-01-23
>
> **目标**: 添加音量调整和倍速播放功能
>
> **依赖**: Phase 2 完成（just_audio 迁移）
>
> **状态**: 📋 计划中

---

## 一、功能概述

### 核心功能

| 功能 | 描述 | 优先级 |
|------|------|--------|
| **音量控制** | 滑块调节播放音量（0.0 - 1.0） | 🔴 高 |
| **倍速播放** | 0.5x - 2.0x 倍速选择 | 🔴 高 |
| **设置持久化** | 保存用户的音量和倍速偏好 | 🟡 中 |

---

## 二、技术方案

### 2.1 just_audio 原生支持

`just_audio` 库原生提供以下 API：

```dart
// 音量控制（0.0 - 1.0）
await player.setVolume(0.5);
double volume = player.volume;

// 倍速播放（0.5x - 2.0x 常用）
await player.setSpeed(1.5);
double speed = player.speed;
```

**支持的倍速范围**：
- 最小：0.5x（半速）
- 最大：2.0x（双倍速）
- 常用档位：0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x

---

## 三、架构设计

### 3.1 数据流

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI 层                                     │
│  ┌──────────────────┐  ┌──────────────────────────────────┐    │
│  │  VolumeSlider    │  │      SpeedButton                 │    │
│  │  (音量滑块)       │  │  (倍速按钮 → 弹出选择菜单)         │    │
│  └────────┬─────────┘  └──────────────┬───────────────────┘    │
│           │                          │                          │
│           └──────────────┬───────────┘                          │
│                          ▼                                      │
├──────────────────────────────────────────────────────────────────┤
│                    AudioProvider (状态管理)                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  状态变量:                                                  │ │
│  │  • double _volume = 1.0                                     │ │
│  │  • double _speed = 1.0                                      │ │
│  │                                                             │ │
│  │  方法:                                                      │ │
│  │  • Future<void> setVolume(double v)                        │ │
│  │  • Future<void> setSpeed(double s)                         │ │
│  │  • Future<void> _saveSettings()                            │ │
│  │  • Future<void> _loadSettings()                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                          │                                      │
├──────────────────────────┼──────────────────────────────────────┤
│                          ▼                                      │
│              just_audio AudioPlayer                             │
│              • player.volume                                    │
│              • player.speed                                     │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 持久化存储

使用 `SharedPreferences` 存储用户偏好：

```dart
// 存储键（定义在 storage_constants.dart）
static const String keyVolume = 'playback_volume';
static const String keySpeed = 'playback_speed';
```

---

## 四、实施步骤

### 步骤 1: 扩展 AudioProvider

**文件**: `lib/presentation/providers/audio/audio_provider.dart`

**新增状态变量**:
```dart
double _volume = 1.0;        // 默认音量 100%
double _speed = 1.0;         // 默认倍速 1.0x

// Getters
double get volume => _volume;
double get speed => _speed;
```

**新增方法**:
```dart
/// 设置音量（0.0 - 1.0）
Future<void> setVolume(double value) async {
  if (_disposed) return;
  _volume = value.clamp(0.0, 1.0);
  await _player.setVolume(_volume);
  await _savePlaybackSettings();
  notifyListeners();
}

/// 设置倍速（0.5x - 2.0x）
Future<void> setSpeed(double value) async {
  if (_disposed) return;
  _speed = value.clamp(0.5, 2.0);
  await _player.setSpeed(_speed);
  await _savePlaybackSettings();
  notifyListeners();
}

/// 保存播放设置
Future<void> _savePlaybackSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(StorageConstants.keyVolume, _volume);
  await prefs.setDouble(StorageConstants.keySpeed, _speed);
}

/// 加载播放设置
Future<void> _loadPlaybackSettings() async {
  final prefs = await SharedPreferences.getInstance();
  _volume = prefs.getDouble(StorageConstants.keyVolume) ?? 1.0;
  _speed = prefs.getDouble(StorageConstants.keySpeed) ?? 1.0;

  // 应用到播放器
  if (!_disposed) {
    await _player.setVolume(_volume);
    await _player.setSpeed(_speed);
  }
}
```

**修改 `_init()` 方法**:
```dart
Future<void> _init() async {
  // 配置音频会话
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  // 加载用户偏好设置
  await _loadPlaybackSettings();

  // 初始化监听器
  _initListeners();

  // 加载播放列表
  _loadPlaylist();
}
```

---

### 步骤 2: 添加存储键

**文件**: `lib/core/constants/storage_constants.dart`

```dart
class StorageConstants {
  // ... 现有键 ...

  // 播放控制设置
  static const String keyVolume = 'playback_volume';
  static const String keySpeed = 'playback_speed';
}
```

---

### 步骤 3: 创建音量滑块组件

**文件**: `lib/presentation/widgets/volume_slider.dart` (新建)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';

class VolumeSlider extends StatelessWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            const Icon(Icons.volume_down, size: 20),
            Expanded(
              child: Slider(
                value: provider.volume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(provider.volume * 100).toInt()}%',
                onChanged: (value) {
                  provider.setVolume(value);
                },
              ),
            ),
            const Icon(Icons.volume_up, size: 20),
            Text('${(provider.volume * 100).toInt()}%'),
          ],
        );
      },
    );
  }
}
```

---

### 步骤 4: 创建倍速选择组件

**文件**: `lib/presentation/widgets/speed_button.dart` (新建)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';

/// 倍速档位
const List<double> kSpeedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

/// 倍速显示文本
const Map<double, String> kSpeedLabels = {
  0.5: '0.5x',
  0.75: '0.75x',
  1.0: '1.0x',
  1.25: '1.25x',
  1.5: '1.5x',
  2.0: '2.0x',
};

class SpeedButton extends StatelessWidget {
  const SpeedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, child) {
        return IconButton(
          icon: Text(
            kSpeedLabels[provider.speed] ?? '1.0x',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: provider.speed != 1.0
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          onPressed: () => _showSpeedMenu(context, provider),
          tooltip: '播放倍速',
        );
      },
    );
  }

  void _showSpeedMenu(BuildContext context, AudioProvider provider) {
    showMenu<double>(
      context: context,
      position: const RelativeRect.fromLTRB(15, 15, 0, 0),
      items: kSpeedOptions.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            children: [
              Text(kSpeedLabels[speed] ?? '$speed'),
              const Spacer(),
              if (provider.speed == speed)
                Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        );
      }).toList(),
    ).then((selectedSpeed) {
      if (selectedSpeed != null) {
        provider.setSpeed(selectedSpeed);
      }
    });
  }
}
```

---

### 步骤 5: 集成到播放器 UI

**文件**: `lib/presentation/pages/home_page.dart` (或相关播放器页面)

**在播放器控制面板添加**:
```dart
// 播放器控制区域
Row(
  children: [
    // ... 现有控制按钮 ...

    // 倍速按钮
    const SpeedButton(),

    const SizedBox(width: 16),

    // 音量滑块（可展开/收起）
    const VolumeSlider(),
  ],
)
```

---

## 五、关键文件清单

| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `presentation/providers/audio/audio_provider.dart` | 添加音量/倍速状态和方法 | 🔴 高 | ⏸️ 待开始 |
| `core/constants/storage_constants.dart` | 添加存储键 | 🟡 中 | ⏸️ 待开始 |
| `presentation/widgets/volume_slider.dart` | 新建 - 音量滑块组件 | 🟡 中 | ⏸️ 待开始 |
| `presentation/widgets/speed_button.dart` | 新建 - 倍速按钮组件 | 🟡 中 | ⏸️ 待开始 |
| `presentation/pages/home_page.dart` | 修改 - 集成 UI 组件 | 🟡 中 | ⏸️ 待开始 |

---

## 六、验收标准

### 功能验收
- [ ] 音量滑块可正常调节（0% - 100%）
- [ ] 音量变化实时生效
- [ ] 倍速按钮显示当前倍速
- [ ] 点击倍速按钮弹出选择菜单
- [ ] 选择倍速后立即生效
- [ ] 应用重启后恢复用户偏好设置

### UI 验收
- [ ] 音量滑块样式美观
- [ ] 倍速按钮当前档位有高亮显示
- [ ] 非默认倍速时按钮有明显标识

### 性能验收
- [ ] 调节音量无卡顿
- [ ] 切换倍速无卡顿
- [ ] 设置持久化不阻塞 UI

---

## 七、知识点说明

1. **just_audio 音量控制**
   - `player.setVolume()` 设置播放音量
   - 范围 0.0（静音）到 1.0（最大音量）
   - 不影响系统音量，仅影响应用内播放

2. **just_audio 倍速播放**
   - `player.setSpeed()` 设置播放速度
   - 常用范围 0.5x - 2.0x
   - 变速不变调（pitch 不会改变）

3. **SharedPreferences**
   - Flutter 本地 KV 存储方案
   - 适合存储用户偏好设置
   - 异步读写，需注意性能

4. **Provider 状态管理**
   - 使用 `Consumer` 监听状态变化
   - `notifyListeners()` 触发 UI 更新
   - 状态与方法封装在 Provider 中

---

## 八、UI 设计参考

### 音量滑块
```
┌────────────────────────────────────────┐
│ 🔊 ━━━━━━━━━━━━━━━━━━━━━ 🔇  80%      │
└────────────────────────────────────────┘
```

### 倍速选择菜单
```
点击倍速按钮后弹出:
┌──────────────┐
│ 0.5x         │
│ 0.75x        │
│ ✓ 1.0x    ← 当前选中
│ 1.25x        │
│ 1.5x         │
│ 2.0x         │
└──────────────┘
```

### 播放器控制面板布局
```
┌──────────────────────────────────────────────────────────────┐
│  ⏮      ⏯      ⏭      🔊 ━━ 🔇      [1.0x]  ⋮            │
│  上一首  播放/暂停  下一首    音量滑块      倍速  更多         │
└──────────────────────────────────────────────────────────────┘
```

---

## 九、进度跟踪

| 步骤 | 任务 | 状态 | 完成日期 |
|------|------|------|----------|
| 1 | 扩展 AudioProvider | ⏸️ 待开始 | - |
| 2 | 添加存储键 | ⏸️ 待开始 | - |
| 3 | 创建音量滑块组件 | ⏸️ 待开始 | - |
| 4 | 创建倍速按钮组件 | ⏸️ 待开始 | - |
| 5 | 集成到播放器 UI | ⏸️ 待开始 | - |
| 6 | 测试与优化 | ⏸️ 待开始 | - |

---

## 十、注意事项

1. **倍速范围限制**
   - just_audio 理论上支持更大倍速范围
   - 但过快的倍速可能导致音频播放不流畅
   - 建议限制在 0.5x - 2.0x

2. **音量与系统音量**
   - 应用音量是系统音量的子集
   - 最终音量 = 系统音量 × 应用音量
   - 系统静音时应用音量也无效

3. **性能考虑**
   - 频繁调节音量/倍速可能导致 UI 卡顿
   - 使用 `debounce` 技术减少不必要的更新

4. **兼容性**
   - Windows 平台使用 `just_audio_media_kit`
   - 确认 MPV 播放器支持倍速播放

---

*本文档由 Claude Code 生成 | 创建: 2026-01-23*
