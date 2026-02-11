# 第三方平台绑定功能修复计划

## 文档信息
- **创建日期**: 2026-02-11
- **问题来源**: 日志调查发现绑定第三方平台失败
- **优先级**: 高

---

## 1. 问题概述

### 1.1 现象描述
用户在已绑定B站账号的情况下，设置页面仍显示"未绑定"状态，允许再次发起绑定流程。扫码登录成功后，后端返回 `500` 错误：
```
UNIQUE constraint failed: platform_accounts.user_id, platform_accounts.platform
```

### 1.2 影响范围
- 用户无法正确识别已绑定的平台账号
- 重复绑定导致数据库唯一约束冲突
- 用户体验受损（显示与实际状态不符）

---

## 2. 问题根因分析

### 2.1 数据库状态异常
```sql
SELECT * FROM platform_accounts WHERE user_id = 1;
-- 结果：
-- id: 1
-- user_id: 1
-- platform: bilibili
-- platform_user_id: 272017820
-- platform_username: ""          ← 空字符串
-- is_active: 0                   ← 未激活
-- created_at: 2026-02-10 05:47:20
-- updated_at: 2026-02-11 04:16:17
```

### 2.2 后端 Bug：getBindStatus 未检查 is_active

**文件**: `listen-vision_api/services/platformService.js` (第 141-170 行)

```javascript
const getBindStatus = (userId, platform) => {
  const account = stmt.get.get(userId, platform);
  if (!account) {
    return { isBound: false };
  }

  // 检查过期时间
  if (account.expires_at) { ... }

  // 检查 Cookie 解密
  if (account.cookie_encrypted && cookie === null) { ... }

  // ❌ 缺失：没有检查 account.is_active 字段！
  
  return {
    isBound: true,  // ← 即使 is_active=0 也返回 true
    userInfo: { id: account.platform_user_id, username: account.platform_username }
  };
};
```

### 2.3 后端 Bug：保存绑定未处理已存在记录

**文件**: `listen-vision_api/services/platformService.js`

当前使用 `INSERT` 语句直接插入，未检查是否已存在绑定记录，导致唯一约束冲突。

### 2.4 问题产生时序

```
1. 用户首次绑定B站 → 成功创建记录 (is_active=1)
2. Cookie 解密失败 → 系统停用绑定 (is_active=0, updated_at更新)
   - 日志："Cookie解密失败: Invalid initialization vector"
   - 日志："清理无效绑定: 用户ID 1"
3. 前端请求绑定状态 → 后端返回 isBound=true (未检查is_active)
4. 前端显示"已绑定"但用户名为空 → 用户看到不一致状态
5. 用户尝试重新绑定 → 后端 INSERT 冲突 → 500错误
```

---

## 3. 修复方案

### 3.1 后端修复

#### 3.1.1 修复 getBindStatus() 检查 is_active

**文件**: `listen-vision_api/services/platformService.js`

```javascript
const getBindStatus = (userId, platform) => {
  const account = stmt.get.get(userId, platform);
  if (!account) {
    return { isBound: false };
  }

  // ✅ 新增：检查账号是否处于激活状态
  if (!account.is_active) {
    return { isBound: false };
  }

  // 检查过期时间
  if (account.expires_at) {
    const expiresAt = new Date(account.expires_at);
    if (expiresAt < new Date()) {
      stmt.deactivate.run(userId, platform);
      return { isBound: false };
    }
  }

  // 检查 Cookie 解密
  const cookie = account.cookie_encrypted ? decrypt(account.cookie_encrypted) : null;
  if (account.cookie_encrypted && cookie === null) {
    logger.warn(`Cookie解密失败，停用账号 ${userId} 的 ${platform} 绑定`);
    stmt.deactivate.run(userId, platform);
    return { isBound: false };
  }

  return {
    isBound: true,
    platform,
    userInfo: {
      id: account.platform_user_id,
      username: account.platform_username,
    },
  };
};
```

#### 3.1.2 修复 saveAccount() 使用 UPSERT 语义

**文件**: `listen-vision_api/services/platformService.js`

```javascript
const saveAccount = (userId, platform, accountData) => {
  const { 
    platformUserId, 
    platformUsername, 
    cookieEncrypted, 
    tokenEncrypted,
    refreshTokenEncrypted,
    expiresAt,
    extraData 
  } = accountData;

  // ✅ 修改：使用 INSERT OR REPLACE 处理已存在记录
  // 或先查询再决定 INSERT 或 UPDATE
  const existing = stmt.get.get(userId, platform);
  
  if (existing) {
    // 更新现有记录
    stmt.update.run(
      platformUserId,
      platformUsername,
      cookieEncrypted,
      tokenEncrypted,
      refreshTokenEncrypted,
      expiresAt ? new Date(expiresAt).toISOString() : null,
      extraData ? JSON.stringify(extraData) : null,
      1, // is_active = 1
      new Date().toISOString(), // updated_at
      userId,
      platform
    );
    return { success: true, action: 'updated' };
  } else {
    // 插入新记录
    stmt.insert.run(
      userId,
      platform,
      platformUserId,
      platformUsername,
      cookieEncrypted,
      tokenEncrypted,
      refreshTokenEncrypted,
      expiresAt ? new Date(expiresAt).toISOString() : null,
      extraData ? JSON.stringify(extraData) : null,
      1, // is_active
      new Date().toISOString(), // created_at
      new Date().toISOString()  // updated_at
    );
    return { success: true, action: 'created' };
  }
};
```

需要确保 `stmt.update` SQL 已正确定义。

### 3.2 数据库修复

清理无效绑定记录（可选，视业务需求）：

```sql
-- 方案A：删除所有未激活的绑定记录
DELETE FROM platform_accounts WHERE is_active = 0;

-- 方案B：保留记录但确保状态一致
-- 已由代码修复保证
```

### 3.3 前端优化（可选）

#### 3.3.1 增强绑定状态验证

**文件**: `frontend_flutter/lib/presentation/viewmodels/auth/platform_auth_viewmodel.dart`

在 `_checkBilibiliBindStatus()` 中增加对空用户名的校验：

```dart
Future<PlatformAuthState> _checkBilibiliBindStatus() async {
  try {
    final statusData = await _bilibiliApi!.getBindStatus();
    final isBound = statusData['isBound'] as bool? ?? false;
    
    if (isBound) {
      final userInfo = statusData['userInfo'] as Map<String, dynamic>?;
      // ✅ 新增：验证用户信息的有效性
      if (userInfo != null && 
          userInfo['id'] != null && 
          userInfo['username'] != null && 
          (userInfo['username'] as String).isNotEmpty) {
        final account = BilibiliUserInfo.fromJson(userInfo);
        await _secureStorage!.setBilibiliAccount(userInfo);
        await _secureStorage!.setBilibiliBound(true);
        return PlatformAuthState.bound(account: account);
      }
      // 信息不完整，视为未绑定
      AppLogger.warn('PlatformAuthViewModel', '绑定信息不完整，视为未绑定');
    }
    
    // 清除本地数据
    await _secureStorage!.setBilibiliBound(false);
    await _secureStorage!.clearBilibiliAccount();
    return const PlatformAuthState.unbound();
  } catch (e) {
    // ...
  }
}
```

---

## 4. 实施步骤

### 步骤 1: 备份数据库
```powershell
cd A:\Projects\listen-vision-audio-app\listen-vision_api\data
copy listenvision.db listenvision.db.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')
```

### 步骤 2: 修改后端代码
1. 打开 `listen-vision_api/services/platformService.js`
2. 修改 `getBindStatus` 函数（第 141 行起）
3. 修改 `saveAccount` 函数，添加 UPSERT 逻辑
4. 确保 `stmt.update` SQL 语句已定义

### 步骤 3: 验证 SQL 语句
检查 `stmt.update` 是否已定义，如未定义需添加：

```javascript
const stmt = {
  get: db.prepare(`
    SELECT * FROM platform_accounts 
    WHERE user_id = ? AND platform = ?
  `),
  insert: db.prepare(`
    INSERT INTO platform_accounts 
    (user_id, platform, platform_user_id, platform_username, 
     cookie_encrypted, token_encrypted, refresh_token_encrypted,
     expires_at, extra_data, is_active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `),
  // ✅ 确保 update 语句存在
  update: db.prepare(`
    UPDATE platform_accounts 
    SET platform_user_id = ?,
        platform_username = ?,
        cookie_encrypted = ?,
        token_encrypted = ?,
        refresh_token_encrypted = ?,
        expires_at = ?,
        extra_data = ?,
        is_active = ?,
        updated_at = ?
    WHERE user_id = ? AND platform = ?
  `),
  deactivate: db.prepare(`
    UPDATE platform_accounts 
    SET is_active = 0, updated_at = ? 
    WHERE user_id = ? AND platform = ?
  `),
  // ...
};
```

### 步骤 4: 重启后端服务
```powershell
cd A:\Projects\listen-vision-audio-app\listen-vision_api
# 停止现有服务
Get-Process node | Stop-Process -Force
# 启动服务
node index.js
```

### 步骤 5: 验证修复
1. 登录应用
2. 进入设置页面
3. 检查B站绑定状态显示
4. 如显示"未绑定"，尝试扫码绑定
5. 确认绑定成功后状态正确显示

---

## 5. 测试用例

### 5.1 后端单元测试

**文件**: `listen-vision_api/tests/services/platformService.test.js`

```javascript
describe('getBindStatus', () => {
  test('is_active=0 应返回未绑定', () => {
    // 准备：插入 is_active=0 的记录
    // 执行：getBindStatus(userId, 'bilibili')
    // 断言：返回 { isBound: false }
  });

  test('绑定已存在时应更新而非插入', () => {
    // 准备：已有绑定记录
    // 执行：saveAccount() 同一用户和平台
    // 断言：记录被更新，无唯一约束错误
  });
});
```

### 5.2 手动测试场景

| 场景 | 步骤 | 期望结果 |
|------|------|----------|
| 已绑定用户刷新 | 1. 已绑定用户进入设置页 | 显示"已绑定"和正确的用户名 |
| 绑定后重新绑定 | 1. 已绑定用户再次扫码<br>2. 使用新账号绑定 | 成功更新绑定到新账号 |
| 失效绑定显示 | 1. 手动将 is_active 设为 0<br>2. 刷新设置页 | 显示"未绑定"，允许重新绑定 |
| Cookie失效处理 | 1. 等待Cookie过期<br>2. 刷新页面 | 显示"未绑定"，清除失效状态 |

---

## 6. 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 数据丢失 | 低 | 高 | 修复前备份数据库 |
| 向后兼容 | 低 | 中 | 保持API响应格式不变 |
| 并发绑定 | 中 | 低 | 使用事务处理 UPSERT |
| 其他平台影响 | 低 | 中 | platformService 为通用服务，修复影响所有平台 |

---

## 7. 后续改进建议

1. **添加唯一约束降级处理**: 在应用层捕获唯一约束错误，转换为友好提示
2. **绑定状态同步机制**: 定期验证绑定有效性，自动清理失效绑定
3. **前端状态刷新**: 进入设置页时强制刷新绑定状态
4. **日志增强**: 在绑定流程关键节点增加详细日志，便于问题排查

---

## 8. 附录

### 8.1 相关文件清单

| 类型 | 路径 | 修改内容 |
|------|------|----------|
| 后端 | `listen-vision_api/services/platformService.js` | getBindStatus, saveAccount |
| 后端 | `listen-vision_api/services/bilibiliService.js` | 确认调用方式 |
| 后端 | `listen-vision_api/controllers/bilibiliController.js` | 确认响应格式 |
| 前端(可选) | `frontend_flutter/lib/presentation/viewmodels/auth/platform_auth_viewmodel.dart` | 增强验证 |

### 8.2 相关日志位置

| 类型 | 路径 |
|------|------|
| 后端日志 | `A:\Projects\listen-vision-audio-app\listen-vision_api\logs\combined.log` |
| 前端日志 | `C:\Users\<username>\Documents\logs\app-<date>.log` |

### 8.3 数据库表结构

```sql
CREATE TABLE platform_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  platform TEXT NOT NULL,
  platform_user_id TEXT NOT NULL,
  platform_username TEXT,
  cookie_encrypted TEXT,
  token_encrypted TEXT,
  refresh_token_encrypted TEXT,
  expires_at DATETIME,
  extra_data TEXT,
  is_active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, platform)
);
```
