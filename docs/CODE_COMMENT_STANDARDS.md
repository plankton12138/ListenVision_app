# 代码注释规范

本文档定义了项目的代码注释标准和最佳实践。

## 注释原则

1. **解释"为什么"而非"是什么"** - 代码说明做什么，注释说明为什么
2. **保持同步** - 代码修改时同步更新注释
3. **避免无意义注释** - 如 `i++; // i加1`
4. **使用专业术语** - 避免口语化表达

## 注释类型

### JSDoc (后端 Node.js)

```javascript
/**
 * 函数简述
 *
 * 详细说明（可选），可以解释算法思路、业务规则等。
 *
 * @param {Type} name - 参数说明
 * @returns {Type} 返回值说明
 * @throws {Error} 异常说明
 *
 * @example
 * const result = functionName(param1, param2);
 */
const functionName = (param1, param2) => {
  // 实现
};
```

### DartDoc (前端 Flutter)

```dart
/// 类/函数简述
///
/// 详细说明（可选），可以解释：
/// - 功能用途
/// - 使用场景
/// - 注意事项
///
/// - 参数说明
/// - 返回值说明
///
/// 示例：
/// ```dart
/// final result = functionName();
/// ```
```

## 禁止的注释模式

| 模式 | 说明 | 正确做法 |
|------|------|---------|
| `// TODO: 实现xxx` | 应转为 GitHub Issue | 创建 Issue 或添加实现计划 |
| `// HACK: xxx` | 应重构或解释 | 解释为什么需要这种做法 |
| `// FIXME: xxx` | 应立即修复或转为 Issue | 转为 Issue 或立即修复 |
| `// ✅ 优化：xxx` | 临时标记，应删除 | 转为正式注释 |
| `console.log('debug')` | 应使用 logger | 使用 `logger.debug()` |
| `/* 空 */` | 空注释块 | 删除 |

## 必须注释的场景

### 1. 复杂算法

```javascript
/**
 * 协同过滤推荐算法
 *
 * 算法流程：
 * 1. 获取用户的播放历史
 * 2. 找出相似用户（至少有 3 首共同歌曲）
 * 3. 基于相似用户的喜好推荐新内容
 *
 * 相似度计算：Jaccard 系数
 *   J(A,B) = |A ∩ B| / |A ∪ B|
 *
 * 时间复杂度：O(n*m)，n为用户数，m为歌曲数
 */
```

### 2. 业务规则

```javascript
/**
 * 判断是否需要刷新 Cookie
 *
 * 规则：
 * - Cookie 有效期少于 1 小时时触发刷新
 * - 刷新失败时保持原 Cookie（不主动失效）
 * - 用户手动登出时才清除 Cookie
 */
```

### 3. 外部调用

```javascript
/**
 * 调用 B站视频信息 API
 *
 * API 文档：bilibili-API-collect/docs/video/video_info.md
 * 速率限制：未登录用户 100次/分钟，登录用户 300次/分钟
 * 需要 WBI 签名
 */
```

### 4. 性能考虑

```javascript
/**
 * 使用缓存减少重复计算
 *
 * 缓存策略：LRU，最多 1000 项
 * 缓存时间：5 分钟
 * 为什么需要缓存：B站 API 调用较慢（~200ms）
 */
```

### 5. 安全考虑

```javascript
/**
 * Cookie 加密存储
 *
 * 加密算法：AES-256-CBC
 * 密钥来源：环境变量 ENCRYPTION_KEY
 * 为什么加密：Cookie 包含敏感的用户认证信息
 */
```

## 注释风格示例

### 好的注释

```javascript
// 使用自适应保护窗口，避免切歌时的状态冲突
// 参考：Phase 5 音频播放优化文档
if (_isStartingPlayback && state != PlayerState.playing) {
  return;
}
```

### 不好的注释

```javascript
// 检查状态
if (state == 'playing') {
  // 设置为 true
  isPlaying = true;
}
```

### 改进后

```javascript
// 播放状态变化时同步更新播放状态标志
if (state == PlayerState.playing) {
  isPlaying = true;
}
```

## 文件头注释

对于重要的服务文件，建议添加文件头注释：

```javascript
/**
 * B站API集成服务
 *
 * 功能：
 * 1. QR码登录
 * 2. Cookie管理（加密存储）
 * 3. 视频信息获取
 * 4. 音频流URL获取
 *
 * API参考: https://socialsisteryi.github.io/bilibili-API-collect/
 *
 * @module bilibiliService
 */
```

## 注释审查清单

提交代码前，检查：

- [ ] 所有公共函数都有文档注释
- [ ] 复杂逻辑都有说明注释
- [ ] 没有 TODO/FIXME 临时标记
- [ ] 没有 console.log 调试代码
- [ ] 敏感信息处理正确（不记录密码等）
- [ ] 注释与代码保持同步
