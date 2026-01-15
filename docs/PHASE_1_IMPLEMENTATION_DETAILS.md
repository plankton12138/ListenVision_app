# Phase 1 实施细节补充文档

> **文档目的**: 补充《渐进式架构迁移计划》中 Phase 1 的技术实现细节
>
> **创建日期**: 2026-01-13
>
> **关联文档**: [INCREMENTAL_MIGRATION_PLAN.md](./INCREMENTAL_MIGRATION_PLAN.md)

---

## 目录

- [1. 安全实现细节](#1-安全实现细节)
- [2. 缓存策略详解](#2-缓存策略详解)
- [3. 同步冲突解决方案](#3-同步冲突解决方案)
- [4. 异常场景测试](#4-异常场景测试)
- [5. 客户端降级逻辑](#5-客户端降级逻辑)
- [6. 数据一致性保障](#6-数据一致性保障)
- [7. 灰度发布与回滚](#7-灰度发布与回滚)
- [8. B站API风险应对](#8-b站api风险应对)
- [9. 服务端扩展性](#9-服务端扩展性)

---

## 1. 安全实现细节

### 1.1 Cookie 加密存储

**加密方案**: AES-256-GCM (Galois/Counter Mode)

**为什么选择 GCM 而非 CBC**:
- GCM 模式提供认证加密（AEAD），同时保证机密性和完整性
- 防止密文被篡改（如 IV 重放攻击）
- 性能优于 CBC + HMAC 组合

#### 后端实现

```javascript
// utils/crypto.js
const crypto = require('crypto');

/**
 * 从环境变量获取密钥
 * 生产环境应使用 KMS 或密钥管理服务
 * 开发环境可通过 openssl rand -32 生成
 */
const getEncryptionKey = () => {
  const key = process.env.BILI_COOKIE_KEY;
  if (!key || key.length !== 64) {
    throw new Error('BILI_COOKIE_KEY must be 32 bytes (64 hex chars)');
  }
  return Buffer.from(key, 'hex');
};

/**
 * 加密 Cookie 数据
 * @param {string} plaintext - 明文 Cookie 字符串
 * @returns {object} - { iv, encrypted, authTag }
 */
const encryptCookie = (plaintext) => {
  const key = getEncryptionKey();
  const iv = crypto.randomBytes(12); // GCM 推荐 12 字节 IV
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');

  return {
    iv: iv.toString('hex'),
    encrypted: encrypted,
    authTag: authTag
  };
};

/**
 * 解密 Cookie 数据
 * @param {object} encryptedData - { iv, encrypted, authTag }
 * @returns {string} - 明文 Cookie
 */
const decryptCookie = (encryptedData) => {
  const key = getEncryptionKey();
  const iv = Buffer.from(encryptedData.iv, 'hex');
  const authTag = Buffer.from(encryptedData.authTag, 'hex');

  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
};

/**
 * 数据库存储格式: JSON 字符串
 * {"iv":"...","encrypted":"...","authTag":"..."}
 */
const encryptCookieForStorage = (cookie) => {
  return JSON.stringify(encryptCookie(cookie));
};

const decryptCookieFromStorage = (stored) => {
  return decryptCookie(JSON.parse(stored));
};

module.exports = {
  encryptCookieForStorage,
  decryptCookieFromStorage,
  encryptCookie,
  decryptCookie
};
```

#### 密钥管理

```bash
# 生成新密钥 (32 bytes)
openssl rand -hex 32

# 添加到 .env (不要提交到 Git)
BILI_COOKIE_KEY=<生成的64位hex字符串>

# 生产环境建议: 使用 AWS KMS / Azure Key Vault / HashiCorp Vault
```

#### 安全检查清单

- [ ] 密钥长度 32 字节（256位）
- [ ] IV 每次加密随机生成
- [ ] 存储时包含认证标签
- [ ] 解密失败抛出异常（不返回部分数据）
- [ ] 日志中脱敏 Cookie（只记录前10字符）

---

## 2. 缓存策略详解

### 2.1 多层缓存架构

```
┌─────────────────────────────────────────────────────┐
│                   缓存层次结构                        │
├─────────────────────────────────────────────────────┤
│  L1: 内存缓存 (Node.js Map/LRU)                      │
│      容量: 1000 条, TTL: 5分钟                        │
│      用途: 热点数据, 0 延迟                            │
├─────────────────────────────────────────────────────┤
│  L2: Redis 缓存 (可选, Phase 3)                      │
│      容量: 无限制, TTL: 1小时                         │
│      用途: 跨实例共享, 减轻DB压力                      │
├─────────────────────────────────────────────────────┤
│  L3: MySQL 数据库                                     │
│      容量: 无限制, TTL: 永久                          │
│      用途: 持久化存储, 缓存未命中时回源                │
└─────────────────────────────────────────────────────┘
```

### 2.2 LRU 内存缓存实现

```javascript
// utils/lruCache.js
class LRUCache {
  constructor(maxSize = 1000, ttl = 300000) { // 默认 1000 条, 5 分钟
    this.maxSize = maxSize;
    this.ttl = ttl;
    this.cache = new Map();
  }

  get(key) {
    const item = this.cache.get(key);
    if (!item) return null;

    // 检查过期
    if (Date.now() > item.expires) {
      this.cache.delete(key);
      return null;
    }

    // LRU: 更新访问顺序
    this.cache.delete(key);
    this.cache.set(key, item);
    return item.value;
  }

  set(key, value) {
    // 删除过期项
    this._cleanExpired();

    // 检查容量
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }

    this.cache.set(key, {
      value,
      expires: Date.now() + this.ttl
    });
  }

  has(key) {
    return this.get(key) !== null;
  }

  _cleanExpired() {
    const now = Date.now();
    for (const [key, item] of this.cache.entries()) {
      if (now > item.expires) {
        this.cache.delete(key);
      }
    }
  }
}

module.exports = LRUCache;
```

### 2.3 缓存击穿防护

**场景**: 热点音频元数据过期时，大量请求同时穿透到数据库

**解决方案**: 单飞模式 (Single Flight)

```javascript
// utils/singleFlight.js
class SingleFlight {
  constructor() {
    this.pending = new Map(); // key -> Promise
  }

  async do(key, fn) {
    // 如果已有请求在进行中，等待其完成
    if (this.pending.has(key)) {
      return this.pending.get(key);
    }

    // 创建新请求
    const promise = fn()
      .finally(() => {
        this.pending.delete(key);
      });

    this.pending.set(key, promise);
    return promise;
  }
}

module.exports = SingleFlight;
```

### 2.4 缓存使用示例

```javascript
// services/audioService.js
const LRUCache = require('../utils/lruCache');
const SingleFlight = require('../utils/singleFlight');

const cache = new LRUCache(1000, 300000); // 1000条, 5分钟
const singleFlight = new SingleFlight();

class AudioService {
  async getAudioMetadata(bvid) {
    // L1: 内存缓存
    const cached = cache.get(`audio:${bvid}`);
    if (cached) {
      logger.debug(`Cache hit: ${bvid}`);
      return cached;
    }

    // 使用单飞模式防止击穿
    return singleFlight.do(`audio:${bvid}`, async () => {
      // L3: 数据库查询
      const [rows] = await pool.execute(
        'SELECT * FROM audio_metadata_cache WHERE bvid = ?',
        [bvid]
      );

      if (rows.length > 0) {
        const metadata = rows[0];
        cache.set(`audio:${bvid}`, metadata);
        return metadata;
      }

      // 缓存未命中，调用 B站 API
      return await this.fetchAndCacheMetadata(bvid);
    });
  }
}
```

---

## 3. 同步冲突解决方案

### 3.1 冲突类型与策略矩阵

| 冲突场景 | 策略 | 技术实现 | 用户交互 |
|---------|-----|---------|---------|
| 播放列表名称冲突 | 云端优先 + 本地重命名 | 比较更新时间戳 | Toast: "名称冲突，本地已重命名为「我的列表_本地1」" |
| 同一音频收藏状态 | 最后写入胜出 | 比较 `updated_at` | 无感知，同步后展示最新状态 |
| 离线添加项，云端已删除 | 保留本地 + 标记不可用 | 添加 `local_only` 标记 | 列表项显示灰色图标 + 提示文字 |
| 多设备同时修改播放列表 | 时间戳比较 + 逐项合并 | 使用 item 级别的 timestamp | Toast: "已合并来自其他设备的修改" |
| 网络中断时的离线修改 | 队列化 + 连网后重放 | 本地存储 pending_ops | 同步按钮显示数字角标 |

### 3.2 合并算法实现

```javascript
// services/syncService.js
class SyncService {
  /**
   * 合并播放列表项（逐项比较）
   */
  mergePlaylistItems(localItems, remoteItems) {
    const merged = [];
    const processedBvids = new Set();

    // 按时间戳排序（最新优先）
    localItems.sort((a, b) => b.updated_at - a.updated_at);
    remoteItems.sort((a, b) => b.updated_at - a.updated_at);

    // 处理本地项
    for (const local of localItems) {
      processedBvids.add(local.bvid);

      const remote = remoteItems.find(r => r.bvid === local.bvid);
      if (!remote) {
        // 云端没有，添加本地项
        merged.push({ ...local, sync_source: 'local' });
      } else if (local.updated_at > remote.updated_at) {
        // 本地更新
        merged.push({ ...local, sync_source: 'local' });
      } else {
        // 云端更新（或相同）
        merged.push({ ...remote, sync_source: 'remote' });
      }
    }

    // 添加仅存在于云端的项
    for (const remote of remoteItems) {
      if (!processedBvids.has(remote.bvid)) {
        merged.push({ ...remote, sync_source: 'remote' });
      }
    }

    // 重新计算 position
    merged.forEach((item, index) => {
      item.position = index + 1;
    });

    return merged;
  }
}
```

### 3.3 Flutter 端冲突处理 UI

```dart
// lib/providers/sync_provider.dart
enum SyncConflict {
  nameConflict,      // 名称冲突
  itemDeleted,       // 项已删除
  versionConflict    // 版本冲突
}

class SyncProvider extends ChangeNotifier {
  Future<List<Playlist>> resolveConflicts(
    List<Playlist> local,
    List<Playlist> remote,
  ) async {
    final conflicts = <ConflictInfo>[];

    // 检测名称冲突
    for (final localPlaylist in local) {
      final remotePlaylist = remote.firstWhereOrNull(
        (p) => p.id == localPlaylist.id && p.name != localPlaylist.name,
      );

      if (remotePlaylist != null) {
        // 名称冲突：云端优先，本地重命名
        final suffix = '_本地${DateTime.now().millisecondsSinceEpoch % 1000}';
        localPlaylist.name = '${localPlaylist.name}$suffix';

        conflicts.add(ConflictInfo(
          type: SyncConflict.nameConflict,
          message: '播放列表名称冲突，已自动重命名',
          resolvedValue: localPlaylist.name,
        ));
      }
    }

    // 显示冲突通知
    if (conflicts.isNotEmpty) {
      _showConflictNotification(conflicts);
    }

    return local;
  }

  void _showConflictNotification(List<ConflictInfo> conflicts) {
    // 使用 SnackBar 或 Dialog 通知用户
    for (final conflict in conflicts) {
      // 通知逻辑...
    }
  }
}
```

---

## 4. 异常场景测试

### 4.1 测试用例清单

#### 4.1.1 网络异常

| 测试用例 | 操作 | 预期结果 |
|---------|-----|---------|
| 断网获取视频信息 | 断开网络 → 调用 API | 返回本地缓存或友好错误 |
| 请求超时 | 模拟 30s 超时 | 返回超时错误，不阻塞UI |
| 服务器返回 500 | Mock 500 响应 | 显示"服务暂时不可用" |
| 限流触发 (429) | 快速连续请求 | 自动退避重试，指数退避 |

#### 4.1.2 边界测试

| 测试用例 | 输入 | 预期结果 |
|---------|-----|---------|
| 空 bvid | `""` 或 `null` | 返回 400 错误 |
| 超长关键词 | 200 字符搜索 | 截断或拒绝 |
| 特殊字符搜索 | `"; DROP TABLE--"` | 转义处理，正常搜索 |
| 负数页码 | `page=-1` | 返回 400 或默认第1页 |
| 超大页码 | `page=99999` | 返回空结果而非错误 |

#### 4.1.3 B站API异常

| 测试用例 | 模拟场景 | 预期结果 |
|---------|---------|---------|
| Cookie 过期 | 返回 -101 | 触发刷新流程 |
| 视频不存在 | 返回 -404 | 缓存空结果（TTL 1小时） |
| UP主视频过多 | 1000+ 视频 | 分页返回，不超时 |
| 音频流失效 | URL 404 | 尝试重新获取流URL |

### 4.2 测试代码示例

```javascript
// tests/bilibiliService.test.js
describe('BilibiliService - 异常场景测试', () => {
  test('应正确处理 Cookie 过期', async () => {
    // Mock B站 API 返回 -101 (Cookie过期)
    mockBiliApi.reply(-101, '账号未登录');

    const result = await service.getVideoInfo('BV123');

    expect(result.error).toBe('COOKIE_EXPIRED');
    expect(shouldRefreshCookie).toBe(true);
  });

  test('应缓存不存在的视频（防止重复请求）', async () => {
    mockBiliApi.reply(-404, '视频不存在');

    await service.getVideoInfo('NOTEXIST');
    const cached = await service.getVideoInfo('NOTEXIST');

    expect(cached).toBeNull();
    expect(biliApiCallCount).toBe(1); // 只调用一次
  });

  test('网络超时应返回友好错误', async () => {
    mockBiliApi.timeout(30000);

    const result = await service.getVideoInfo('BV123');

    expect(result.error).toBe('TIMEOUT');
    expect(result.message).toContain('请求超时');
  });
});
```

---

## 5. 客户端降级逻辑

### 5.1 服务端不可用时的降级

```dart
// lib/services/api_service.dart
class ApiService {
  final String baseUrl;
  final Dio _dio;

  Future<T> requestWithFallback<T>(
    String path,
    T Function(dynamic) parser,
  ) async {
    try {
      final response = await _dio.get('$baseUrl$path');
      return parser(response.data);
    } catch (e) {
      // 判断错误类型
      if (e is DioException && e.error is SocketException) {
        // 网络错误：尝试本地缓存
        return await _getLocalFallback(path, parser);
      }

      if (e is DioException && e.response?.statusCode == 503) {
        // 服务维护：显示维护提示
        throw ServiceMaintenanceException();
      }

      rethrow;
    }
  }

  Future<T> _getLocalFallback<T>(
    String path,
    T Function(dynamic) parser,
  ) async {
    // 从本地 SQLite 读取缓存
    final cache = await db.query('cache_table',
      where: 'path = ?',
      whereArgs: [path],
    );

    if (cache != null && cache.isNotEmpty) {
      // 标记数据可能过时
      return parser(cache.first['data']);
    }

    throw NoDataAvailableException();
  }
}
```

### 5.2 UI 降级状态

```dart
// lib/ui/pages/home_page.dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ApiStatusProvider>(
      builder: (context, status, child) {
        if (status.isServerDown) {
          return ServerDownBanner(
            message: '服务暂时不可用，显示本地缓存内容',
            actions: [
              TextButton(
                onPressed: () => status.retry(),
                child: Text('重试'),
              ),
            ],
          );
        }

        if (status.isReadOnlyMode) {
          return ReadOnlyBanner(
            message: '只读模式：修改将在网络恢复后同步',
          );
        }

        return child;
      },
    );
  }
}
```

### 5.3 离线修改队列化

```dart
// lib/services/offline_queue.dart
class OfflineOperationQueue {
  final List<Operation> _pending = [];

  void add(Operation op) {
    _pending.add(op);
    _saveToStorage();
  }

  Future<void> sync() async {
    if (_pending.isEmpty) return;

    final succeeded = <Operation>[];
    final failed = <Operation>[];

    for (final op in _pending) {
      try {
        await op.execute();
        succeeded.add(op);
      } catch (e) {
        failed.add(op);
      }
    }

    _pending.clear();
    _pending.addAll(failed); // 保留失败的
    _saveToStorage();

    // 通知用户同步结果
    _notifySyncResult(succeeded.length, failed.length);
  }
}
```

---

## 6. 数据一致性保障

### 6.1 双写补偿机制

```javascript
// services/dualWriteService.js
class DualWriteService {
  /**
   * 双写：本地 SQLite + 服务端 MySQL
   */
  async createPlaylist(userId, playlistData) {
    let localId = null;
    let remoteId = null;
    let localError = null;
    let remoteError = null;

    // 1. 同时写入本地和服务端
    const [localResult, remoteResult] = await Promise.allSettled([
      this._writeLocal(playlistData),
      this._writeRemote(userId, playlistData)
    ]);

    // 2. 处理本地写入结果
    if (localResult.status === 'fulfilled') {
      localId = localResult.value.id;
    } else {
      localError = localResult.reason;
      logger.error('本地写入失败:', localError);
    }

    // 3. 处理远程写入结果
    if (remoteResult.status === 'fulfilled') {
      remoteId = remoteResult.value.id;
    } else {
      remoteError = remoteResult.reason;
      logger.error('远程写入失败:', remoteError);
    }

    // 4. 补偿逻辑
    if (localId && !remoteId) {
      // 远程失败，标记待同步
      await this._markPendingSync(localId, 'CREATE', playlistData);
    } else if (remoteId && !localId) {
      // 本地失败，使用远程ID重试本地
      await this._retryLocalWrite(remoteId, playlistData);
    } else if (!localId && !remoteId) {
      throw new Error('双写均失败，请检查网络连接');
    }

    return {
      localId,
      remoteId,
      needsSync: !remoteId
    };
  }
}
```

### 6.2 数据库事务

```javascript
// services/playlistService.js
class PlaylistService {
  /**
   * 创建播放列表（带事务）
   */
  async createPlaylist(userId, name, items = []) {
    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      // 1. 插入播放列表
      const [playlistResult] = await connection.execute(
        'INSERT INTO playlists (user_id, name) VALUES (?, ?)',
        [userId, name]
      );
      const playlistId = playlistResult.insertId;

      // 2. 批量插入播放列表项
      if (items.length > 0) {
        const itemValues = items.map((item, index) => [
          playlistId,
          item.bvid,
          item.title,
          item.artist,
          index + 1 // position
        ]);

        const itemQuery = `
          INSERT INTO playlist_items
          (playlist_id, bvid, title, artist, position)
          VALUES ${itemValues.map(() => '(?, ?, ?, ?, ?)').join(', ')}
        `;

        await connection.execute(
          itemQuery,
          itemValues.flat()
        );
      }

      await connection.commit();
      return { id: playlistId, name, items };

    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}
```

---

## 7. 灰度发布与回滚

### 7.1 灰度发布流程

```javascript
// middleware/featureFlag.js
/**
 * 基于用户ID哈希的灰度控制
 */
class FeatureFlag {
  constructor() {
    this.features = {
      BILIBILI_SERVICE: {
        enabled: true,
        percentage: 10, // 初始 10%
        whitelist: [], // 白名单用户ID
      }
    };
  }

  /**
   * 检查用户是否在灰度范围内
   */
  isEnabled(feature, userId) {
    const config = this.features[feature];
    if (!config || !config.enabled) return false;

    // 白名单优先
    if (config.whitelist.includes(userId)) return true;

    // 基于哈希的百分比分配（一致性哈希）
    const hash = this._hashUserId(userId);
    const bucket = hash % 100;
    return bucket < config.percentage;
  }

  _hashUserId(userId) {
    let hash = 0;
    const str = userId.toString();
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash);
  }

  /**
   * 动态调整灰度百分比
   */
  setPercentage(feature, percentage) {
    if (this.features[feature]) {
      this.features[feature].percentage = percentage;
      logger.info(`Feature ${feature} 灰度调整为 ${percentage}%`);
    }
  }
}

module.exports = new FeatureFlag();
```

### 7.2 灰度发布步骤

```bash
# 1. 初始阶段：10% 灰度
curl -X POST http://localhost:3000/admin/feature-flag/BILIBILI_SERVICE \
  -H "Content-Type: application/json" \
  -d '{"percentage": 10}'

# 2. 监控 24 小时
# - API 成功率 >= 95%
# - P95 响应时间 < 500ms
# - 错误日志无异常增长

# 3. 扩大到 50%
curl -X POST http://localhost:3000/admin/feature-flag/BILIBILI_SERVICE \
  -H "Content-Type: application/json" \
  -d '{"percentage": 50}'

# 4. 再监控 24 小时，指标正常后全量
curl -X POST http://localhost:3000/admin/feature-flag/BILIBILI_SERVICE \
  -H "Content-Type: application/json" \
  -d '{"percentage": 100}'
```

### 7.3 回滚触发条件

```javascript
// utils/rollbackMonitor.js
class RollbackMonitor {
  constructor() {
    this.thresholds = {
      successRate: 0.90,      // 成功率 < 90%
      p95Latency: 1000,       // P95延迟 > 1s
      errorRate: 0.05         // 错误率 > 5%
    };
  }

  async checkMetrics() {
    const metrics = await this._collectMetrics();

    if (metrics.successRate < this.thresholds.successRate) {
      logger.error(`成功率过低: ${metrics.successRate}, 触发回滚`);
      return 'ROLLBACK';
    }

    if (metrics.p95Latency > this.thresholds.p95Latency) {
      logger.error(`P95延迟过高: ${metrics.p95Latency}ms, 触发回滚`);
      return 'ROLLBACK';
    }

    return 'OK';
  }

  async _collectMetrics() {
    // 从日志或监控系统收集指标
    // ...
  }
}
```

### 7.4 回滚数据迁移

```javascript
# 回滚时将云端数据回写到本地 SQLite
# 1. 导出用户数据
mysqldump -u root -p listenvision_app \
  --where="user_id IN (...)" \
  playlists playlist_items > rollback_backup.sql

# 2. 转换为 SQLite 格式
# 3. Flutter 端导入到本地数据库
# 4. 关闭后端功能开关
```

---

## 8. B站API风险应对

### 8.1 风险等级与应对

| 风险 | 等级 | 触发条件 | 应对措施 |
|-----|-----|---------|---------|
| 请求限流 | 🟡 低 | 返回 -412, 429 | 指数退避重试 |
| Cookie 失效 | 🟡 低 | 返回 -101 | 自动刷新 Cookie |
| IP 被封禁 | 🟠 中 | 连续失败 > 10次 | 切换代理池 |
| API 变更 | 🔴 高 | 返回格式变化 | 降级到客户端调用 |
| 服务关停 | 🔴 高 | 长时间无响应 | 启用备用方案 |

### 8.2 重试与熔断机制

```javascript
// utils/circuitBreaker.js
class CircuitBreaker {
  constructor(options = {}) {
    this.threshold = options.threshold || 5;      // 失败阈值
    this.timeout = options.timeout || 60000;      // 冷却时间
    this.failures = 0;
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.nextAttempt = 0;
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this._onSuccess();
      return result;
    } catch (error) {
      this._onFailure();
      throw error;
    }
  }

  _onSuccess() {
    this.failures = 0;
    if (this.state === 'HALF_OPEN') {
      this.state = 'CLOSED';
    }
  }

  _onFailure() {
    this.failures++;
    if (this.failures >= this.threshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
      logger.error('Circuit breaker opened due to failures');
    }
  }
}

// 使用示例
const breaker = new CircuitBreaker({ threshold: 5, timeout: 60000 });

async function callBilibiliAPI() {
  return breaker.execute(async () => {
    return await axios.get('https://api.bilibili.com/...');
  });
}
```

### 8.3 指数退避重试

```javascript
// utils/retry.js
async function retryWithBackoff(fn, options = {}) {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 10000
  } = options;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }

      // 计算退避时间: baseDelay * 2^attempt
      const delay = Math.min(baseDelay * Math.pow(2, attempt), maxDelay);
      logger.debug(`Retry ${attempt + 1}/${maxRetries} after ${delay}ms`);

      await sleep(delay);
    }
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### 8.4 备用方案

当 B站 API 完全不可用时：

```javascript
// services/backupService.js
class BackupService {
  /**
   * 备用方案1: 使用用户上传的本地音频
   */
  async getLocalAlternatives(keyword) {
    // 搜索用户本地音频库
    const results = await pool.execute(
      `SELECT * FROM user_uploads
       WHERE title LIKE ? OR artist LIKE ?
       LIMIT 20`,
      [`%${keyword}%`, `%${keyword}%`]
    );
    return results;
  }

  /**
   * 备用方案2: 返回缓存的热门内容
   */
  async getTrendingFallback() {
    return await pool.execute(
      `SELECT * FROM audio_metadata_cache
       ORDER BY created_at DESC
       LIMIT 50`
    );
  }
}
```

---

## 9. 服务端扩展性

### 9.1 集群部署架构

```
                      ┌─────────────┐
                      │   Nginx     │
                      │  (负载均衡)  │
                      └──────┬──────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
         │ Node-1  │    │ Node-2  │    │ Node-3  │
         │ :3000   │    │ :3000   │    │ :3000   │
         └────┬────┘    └────┬────┘    └────┬────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
         │  Redis  │    │  MySQL  │    │  BullMQ │
         │ (缓存)   │    │ (主库)   │    │ (任务)  │
         └─────────┘    └─────────┘    └─────────┘
```

### 9.2 会话共享

```javascript
// 使用 Redis 存储会话（多实例共享）
const session = require('express-session');
const RedisStore = require('connect-redis')(session);

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 }
}));
```

### 9.3 分布式任务队列

```javascript
// 使用 BullMQ 处理下载任务
const { Queue, Worker } = require('bullmq');

const downloadQueue = new Queue('download', {
  connection: { host: 'localhost', port: 6379 }
});

// 添加下载任务
async function addDownloadTask(userId, bvid) {
  await downloadQueue.add('download', {
    userId,
    bvid,
    priority: 1
  });
}

// Worker 处理任务
const worker = new Worker('download', async (job) => {
  const { userId, bvid } = job.data;

  // 下载逻辑
  const result = await downloadAudio(bvid);

  // 更新任务状态
  await updateTaskStatus(job.id, 'completed');

  return result;
}, {
  connection: { host: 'localhost', port: 6379 }
});
```

---

## 10. 开发检查清单

### 10.1 Phase 1 完成检查

- [ ] **安全**: Cookie 使用 AES-256-GCM 加密
- [ ] **缓存**: LRU 内存缓存 + 数据库持久化
- [ ] **击穿防护**: 单飞模式实现
- [ ] **重试**: 指数退避重试机制
- [ ] **熔断**: 5 次失败后熔断
- [ ] **降级**: 服务端不可用时使用本地缓存
- [ ] **灰度**: 10% → 50% → 100% 发布
- [ ] **监控**: API 成功率、P95延迟、错误率
- [ ] **日志**: 敏感信息脱敏
- [ ] **测试**: 异常场景、边界用例覆盖

### 10.2 上线前检查

- [ ] 密钥已从环境变量读取
- [ ] 生产数据库已迁移
- [ ] Redis 连接配置正确
- [ ] 日志级别设置为 INFO
- [ ] 限流阈值已调整
- [ ] CORS 域名已配置
- [ ] 健康检查端点可用
- [ ] 回滚预案已准备

---

## 附录

### A. 环境变量配置模板

```bash
# .env.production

# 数据库
DB_HOST=your-db-host
DB_PORT=3306
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_NAME=listenvision_app

# Redis
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# 加密密钥 (使用 openssl rand -hex 32 生成)
BILI_COOKIE_KEY=your-64-char-hex-key

# JWT
JWT_SECRET=your-jwt-secret

# 功能开关
ENABLE_BILIBILI_SERVICE=true
BILIBILI_SERVICE_PERCENTAGE=10

# 日志
LOG_LEVEL=info
```

### B. 监控指标定义

| 指标 | 类型 | 阈值 | 说明 |
|-----|-----|------|-----|
| api_success_rate | Gauge | > 0.95 | API 成功率 |
| api_latency_p95 | Histogram | < 500ms | P95 响应时间 |
| cache_hit_rate | Gauge | > 0.60 | 缓存命中率 |
| circuit_breaker_state | Gauge | CLOSED | 熔断器状态 |
| active_requests | Gauge | < 1000 | 当前请求数 |

---

**文档版本**: 1.0.0
**最后更新**: 2026-01-13
**维护者**: Claude Code
