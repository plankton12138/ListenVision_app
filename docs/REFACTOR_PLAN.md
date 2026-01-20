# Flutter 代码重构计划

> **创建日期**: 2026-01-20
>
> **状态**: 📋 规划中（不计入Phase）
>
> **目标**: 解决代码质量问题，提升可维护性和应用性能

---

## 一、项目评估

### 整体架构评分: **6.5/10**

| 评分项 | 得分 | 说明 |
|--------|------|------|
| 代码组织 | 7/10 | 分层清晰，但职责划分不够明确 |
| 代码复用 | 5/10 | 存在较多重复代码 |
| 状态管理 | 6/10 | Provider使用规范，但嵌套过深 |
| 性能优化 | 5/10 | 存在不必要的rebuild和列表性能问题 |
| 错误处理 | 4/10 | 异常处理过于简单，缺少降级方案 |
| 内存管理 | 5/10 | 存在Timer内存泄漏风险 |

---

## 二、严重问题清单（P0 - 立即修复）

### 1. Timer 内存泄漏 🔴

**位置**: `lib/providers/bilibili_provider.dart:128-141`

```dart
void _startQRPolling() {
  _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    // 轮询逻辑
  });
}
```

**问题**: Timer在Provider dispose时可能未完全清理

**修复方案**:
```dart
@override
void dispose() {
  _stopQRPolling();
  _qrPollTimer?.cancel();  // 确保取消
  _qrPollTimer = null;
  super.dispose();
}
```

---

### 2. ListView 性能问题 🔴

**位置**: `lib/ui/pages/explore_page.dart:276-284`

```dart
ListView(
  children: [
    ..._musicZoneData.map((item) => _buildMusicZoneCard(item)),
  ],
)
```

**问题**: 对长列表使用`children`而非`builder`，所有子widget一次性构建

**修复方案**:
```dart
ListView.builder(
  itemCount: _musicZoneData.length,
  itemBuilder: (context, index) {
    return _buildMusicZoneCard(_musicZoneData[index]);
  },
)
```

---

### 3. 图片加载无缓存 🔴

**问题**: 大量使用`Image.network`，无缓存机制

**修复方案**: 引入`cached_network_image`包

```yaml
dependencies:
  cached_network_image: ^3.3.0
```

---

## 三、中等问题清单（P1 - 短期重构）

### 1. Provider 职责过重 🟡

**位置**: `lib/providers/bilibili_provider.dart` (662行)

**问题**: 单个Provider承担太多职责：
- QR码登录管理
- 搜索功能
- 推荐内容获取
- 视频信息缓存
- 资源URL代理

**重构方案**: 拆分为多个Provider

| 新Provider | 职责 |
|------------|------|
| `QRLoginProvider` | QR码登录状态管理 |
| `SearchProvider` | 搜索功能（已有） |
| `RecommendationProvider` | 推荐内容获取 |
| `BilibiliCacheProvider` | 视频信息缓存 |

---

### 2. 重复的UI组件 🟡

| 组件 | 重复位置 | 建议 |
|------|----------|------|
| `_buildPlaylistCard` | `explore_page.dart:489-537`<br>`playlist_library_page.dart:428-486` | 提取到 `components/playlist_card.dart` |
| 错误提示逻辑 | 多个Provider | 创建 `utils/error_handler.dart` |
| 加载状态处理 | 每个页面都有 `_isLoading` | 创建 `widgets/loading_overlay.dart` |

---

### 3. 过度使用 context.watch 🟡

**问题**: 许多地方使用`context.watch<Provider>()`，导致整个widget重建

**优化方案**: 使用`Selector`或`Consumer`限制rebuild范围

```dart
// Before - 整个widget重建
Widget build(BuildContext context) {
  final provider = context.watch<AudioProvider>();
  return Text(provider.title);
}

// After - 仅重建必要部分
Widget build(BuildContext context) {
  return Selector<AudioProvider, String>(
    selector: (context, provider) => provider.title,
    builder: (context, title, child) {
      return Text(title);
    },
  );
}
```

---

## 四、架构改进建议（P2 - 长期优化）

### 当前结构问题

```
lib/
├── providers/      ← 状态管理混杂业务逻辑
├── services/       ← 服务层职责不清
├── ui/
│   ├── pages/     ← 页面组件包含太多逻辑
│   └── components/
├── models/        ← 数据模型设计不一致
└── utils/
```

### 推荐: Clean Architecture

```
lib/
├── core/           # 核心功能
│   ├── constants/
│   ├── exceptions/
│   ├── base/       # BaseProvider, BaseEntity等
│   └── utils/
├── data/           # 数据层
│   ├── models/     # 数据模型
│   ├── repositories/  # 数据仓储实现
│   └── datasources/   # API/本地数据源
├── domain/         # 领域层
│   ├── entities/   # 领域实体
│   └── repositories/  # 仓储接口
└── presentation/   # 表现层
    ├── providers/  # 状态管理
    ├── pages/      # 页面
    ├── widgets/    # 可复用组件
    └── routes/     # 路由配置
```

---

## 五、与业界标准对比

参考: [netease-cloud-music](https://github.com/boyan01/netease-cloud-music)

| 维度 | 本项目 | 业界标准 | 差距 |
|------|--------|----------|------|
| 状态管理 | Provider（混用） | Provider + Repository | ⚠️ 需改进 |
| 网络层 | Dio简单封装 | Dio + 拦截器 + 缓存 | ⚠️ 需改进 |
| 图片加载 | Image.network | cached_network_image | ❌ 需改进 |
| 列表性能 | ListView(children) | ListView.builder | ❌ 需改进 |
| 代码生成 | 手写fromJson/toJson | freezed/json_serializable | ⚠️ 建议引入 |

---

## 六、实施计划

### P0 - 立即修复（影响稳定性）

| 任务 | 预计工作量 | 优先级 |
|------|------------|--------|
| 修复Timer内存泄漏 | 1小时 | 🔴 |
| 优化ListView性能 | 2小时 | 🔴 |
| 引入图片缓存 | 3小时 | 🔴 |

### P1 - 短期重构（影响可维护性）

| 任务 | 预计工作量 | 优先级 |
|------|------------|--------|
| 拆分BilibiliProvider | 1天 | 🟡 |
| 提取重复UI组件 | 1天 | 🟡 |
| 创建BaseProvider基类 | 0.5天 | 🟡 |
| 优化context.watch使用 | 1天 | 🟡 |

### P2 - 长期优化（提升代码质量）

| 任务 | 预计工作量 | 优先级 |
|------|------------|--------|
| 重构为Clean Architecture | 3-5天 | 🟢 |
| 引入freezed代码生成 | 2天 | 🟢 |
| 完善单元测试 | 5天+ | 🟢 |

---

## 七、冗余代码清单

### 可删除的文件

| 文件 | 原因 | 确认状态 |
|------|------|----------|
| `ui/components/video_card.dart` | 未被发现使用 | ⚠️ 需确认 |

### 可合并的文件

| 文件 | 建议 |
|------|------|
| `services/bilibiliApiService.dart` | 与 `BilibiliProvider` 合并或分离职责 |

---

## 八、知识点说明

1. **内存泄漏**: Timer/Timer.periodic 必须在 dispose 时 cancel
2. **ListView性能**: builder模式按需构建，children模式一次性构建全部
3. **Selector优化**: 只监听特定字段变化，减少rebuild范围
4. **Clean Architecture**: 分层架构，确保业务逻辑与UI解耦

---

## 九、进度跟踪

| 阶段 | 状态 | 完成日期 |
|------|------|----------|
| P0: 立即修复 | ⏸️ 待开始 | |
| P1: 短期重构 | ⏸️ 待开始 | |
| P2: 长期优化 | ⏸️ 待开始 | |

---

*本文档由 Claude Code 生成 | 创建: 2026-01-20 | 状态: 规划中*
