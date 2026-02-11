# 网易云音乐 QR 登录修复计划

## 文档信息
- **创建日期**: 2026-02-11
- **问题来源**: 用户反馈 + 代码审查
- **优先级**: 高

---

## 1. 问题概述

### 1.1 现象描述
网易云音乐 QR 登录成功后，绑定状态异常：
- `getBindStatus` 返回空的 `userInfo`（`id` 为空字符串）
- 获取用户歌单时请求变成 `/user/playlist/`（缺少 uid 参数）
- 前端显示已绑定但无法获取用户歌单

### 1.2 问题根因

**对比两种登录方式的差异：**

| 登录方式 | 保存的字段 | 代码位置 |
|----------|-----------|----------|
| **手机号登录** | `platformUserId`, `platformUsername`, `cookie` | 第 70-75 行 ✅ |
| **QR 登录** | 仅 `cookie` | 第 32-37 行 ❌ |

**缺失字段导致的问题链：**

```
1. QR 登录成功
   ↓
2. saveAccount() 只保存 cookie，没有 platformUserId 和 platformUsername
   ↓
3. getBindStatus() 返回 { isBound: true, userInfo: { id: '', username: '' } }
   ↓
4. 前端拿到空 id
   ↓
5. 请求 /api/v1/netease/user/playlist/ 时 uid 为空
   ↓
6. 后端调用 /user/playlist?uid= 缺少 uid 参数，API 报错
```

---

## 2. 修复方案

### 2.1 方案概述

在 QR 登录成功后，使用已获取的 Cookie 调用网易云 `/user/account` API 获取用户信息，然后完整保存账号数据。

### 2.2 代码修改

#### 修改 1: neteaseService.js - 添加获取用户信息方法

**文件**: `listen-vision_api/services/neteaseService.js`

在 `checkQRLoginStatus` 函数后添加新方法：

```javascript
/**
 * 获取当前登录用户信息
 * @param {string} cookie - 登录后的 Cookie
 * @returns {Promise<{id: string, username: string, avatar: string}>} 用户信息
 */
const getCurrentUserInfo = async (cookie) => {
  try {
    const data = await httpGet(buildUrl('/user/account'), {
      'Cookie': cookie,
    });

    if (data.code !== 200) {
      throw new Error(data.message || '获取用户信息失败');
    }

    const profile = data.profile;
    if (!profile) {
      throw new Error('无法获取用户资料');
    }

    return {
      id: profile.userId?.toString() || '',
      username: profile.nickname || '',
      avatar: profile.avatarUrl || '',
    };
  } catch (error) {
    logger.error('[Netease] 获取用户信息失败: %s', error.message);
    throw new Error(`获取用户信息失败: ${error.message}`);
  }
};
```

#### 修改 2: neteaseController.js - QR 登录保存用户信息

**文件**: `listen-vision_api/controllers/neteaseController.js`

修改 `checkQRLoginStatus` 函数（第 20-53 行）：

```javascript
const checkQRLoginStatus = async (req, res) => {
  try {
    const { key } = req.body;
    if (!key) {
      return res.status(400).json({
        success: false,
        error: '缺少 key 参数',
      });
    }

    const data = await neteaseService.checkQRLoginStatus(key);

    if (data.status === 'success' && data.cookie) {
      const userId = req.user.id;
      
      // ✅ 新增：获取用户信息
      let userInfo;
      try {
        userInfo = await neteaseService.getCurrentUserInfo(data.cookie);
      } catch (error) {
        logger.warn('[Netease] 获取用户信息失败，使用默认空值: %s', error.message);
        userInfo = { id: '', username: '', avatar: '' };
      }

      // ✅ 修改：保存完整的账号信息
      await neteaseService.saveAccount(userId, {
        platformUserId: userInfo.id,
        platformUsername: userInfo.username,
        cookie: data.cookie,
        expiresInDays: 30,
      });

      logger.info('[Netease] 用户 %d 绑定成功 (ID: %s, 用户名: %s)', 
        userId, userInfo.id, userInfo.username);
      
      // ✅ 新增：返回用户信息给前端
      res.json({
        success: true,
        data: {
          status: data.status,
          userInfo: userInfo,
        },
      });
    } else {
      res.json({
        success: true,
        data: {
          status: data.status,
          message: data.message,
        },
      });
    }
  } catch (error) {
    logger.error('[Netease] 检查二维码状态失败: %s', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};
```

#### 修改 3: neteaseService.js - 导出新增方法

**文件**: `listen-vision_api/services/neteaseService.js`

在 `module.exports` 中添加：

```javascript
module.exports = {
  PLATFORM,
  getQRCode,
  checkQRLoginStatus,
  loginWithCellphone,
  saveAccount,
  getCookie,
  getAccount,
  getBindStatus,
  unbindAccount,
  search,
  getSongDetail,
  getSongUrl,
  getPlaylistDetail,
  getLyric,
  getUserPlaylist,
  getCurrentUserInfo, // ✅ 新增
};
```

---

## 3. 实施步骤

### 步骤 1: 修改 neteaseService.js

```powershell
cd A:\Projects\listen-vision-audio-app\listen-vision_api
```

1. 在 `checkQRLoginStatus` 函数后添加 `getCurrentUserInfo` 方法
2. 在 `module.exports` 中添加 `getCurrentUserInfo`

### 步骤 2: 修改 neteaseController.js

1. 修改 `checkQRLoginStatus` 函数：
   - QR 登录成功后调用 `getCurrentUserInfo`
   - 完整保存 `platformUserId` 和 `platformUsername`
   - 返回用户信息给前端

### 步骤 3: 重启后端服务

```powershell
cd A:\Projects\listen-vision-audio-app\listen-vision_api
Get-Process node | Stop-Process -Force
node index.js
```

### 步骤 4: 测试验证

1. 进入设置页面，点击"绑定网易云音乐"
2. 扫描二维码登录
3. 确认绑定成功后：
   - 刷新页面，检查绑定状态显示正确的用户名
   - 进入"我的歌单"，确认能正确加载网易云歌单列表

---

## 4. 修复前后对比

### 修复前

```javascript
// neteaseController.js - checkQRLoginStatus
if (data.status === 'success' && data.cookie) {
  const userId = req.user.id;
  await neteaseService.saveAccount(userId, {
    cookie: data.cookie,           // ❌ 只保存 cookie
    expiresInDays: 30,
  });
}

// 结果：数据库记录
// platform_user_id: '',
// platform_username: '',
// cookie_encrypted: 'xxx...'
```

### 修复后

```javascript
// neteaseController.js - checkQRLoginStatus
if (data.status === 'success' && data.cookie) {
  const userId = req.user.id;
  
  // ✅ 先获取用户信息
  const userInfo = await neteaseService.getCurrentUserInfo(data.cookie);
  
  // ✅ 保存完整信息
  await neteaseService.saveAccount(userId, {
    platformUserId: userInfo.id,       // ✅ 例如: "123456789"
    platformUsername: userInfo.username, // ✅ 例如: "音乐爱好者"
    cookie: data.cookie,
    expiresInDays: 30,
  });
}

// 结果：数据库记录
// platform_user_id: '123456789',
// platform_username: '音乐爱好者',
// cookie_encrypted: 'xxx...'
```

---

## 5. 测试用例

### 5.1 手动测试场景

| 场景 | 步骤 | 期望结果 |
|------|------|----------|
| QR 登录绑定 | 1. 打开设置页<br>2. 点击绑定网易云<br>3. 扫描二维码<br>4. 确认登录 | 设置页显示正确的网易云用户名和 ID |
| 获取用户歌单 | 1. 完成绑定<br>2. 进入"我的歌单"页 | 正确显示网易云音乐的歌单列表 |
| 绑定状态持久化 | 1. 完成绑定<br>2. 关闭应用重新打开<br>3. 进入设置页 | 仍显示已绑定状态和用户信息 |
| 解绑后重新绑定 | 1. 解绑网易云<br>2. 重新扫描二维码绑定 | 新账号信息正确显示 |

### 5.2 后端单元测试（可选）

```javascript
// tests/services/neteaseService.test.js
describe('getCurrentUserInfo', () => {
  test('应返回正确的用户信息', async () => {
    const mockCookie = 'MUSIC_U=xxx; __csrf=yyy';
    const userInfo = await neteaseService.getCurrentUserInfo(mockCookie);
    
    expect(userInfo).toHaveProperty('id');
    expect(userInfo).toHaveProperty('username');
    expect(userInfo).toHaveProperty('avatar');
    expect(userInfo.id).not.toBe('');
  });
});
```

---

## 6. 数据修复

对于已经 QR 登录但缺少用户信息的记录，可以运行以下修复脚本：

**文件**: `listen-vision_api/scripts/fix-netease-bindings.js`

```javascript
const { getAccount, saveAccount, getCurrentUserInfo } = require('../services/neteaseService');
const { getAllBindings } = require('../services/platformService');
const { logger } = require('../utils/logger');

/**
 * 修复缺失用户信息的网易云绑定
 */
async function fixNeteaseBindings() {
  const db = require('../config/database');
  
  // 获取所有网易云绑定
  const stmt = db.prepare(`
    SELECT user_id, cookie_encrypted FROM platform_accounts 
    WHERE platform = 'netease' AND (platform_user_id IS NULL OR platform_user_id = '')
  `);
  const bindings = stmt.all();
  
  logger.info(`[FixNetease] 发现 ${bindings.length} 个需要修复的绑定`);
  
  for (const binding of bindings) {
    try {
      const cookie = decrypt(binding.cookie_encrypted);
      const userInfo = await getCurrentUserInfo(cookie);
      
      await saveAccount(binding.user_id, {
        platformUserId: userInfo.id,
        platformUsername: userInfo.username,
        cookie: cookie,
      });
      
      logger.info(`[FixNetease] 修复成功: 用户 ${binding.user_id} -> ${userInfo.username}`);
    } catch (error) {
      logger.error(`[FixNetease] 修复失败: 用户 ${binding.user_id}: ${error.message}`);
    }
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  fixNeteaseBindings().then(() => process.exit(0));
}

module.exports = { fixNeteaseBindings };
```

---

## 7. 附录

### 相关文件清单

| 文件 | 修改内容 |
|------|----------|
| `listen-vision_api/services/neteaseService.js` | 添加 `getCurrentUserInfo` 方法 |
| `listen-vision_api/controllers/neteaseController.js` | 修改 `checkQRLoginStatus` 保存用户信息 |

### API 参考

**网易云 API**: `/user/account`
- **方法**: GET
- **参数**: 需要 Cookie
- **响应示例**:
```json
{
  "code": 200,
  "profile": {
    "userId": 123456789,
    "nickname": "音乐爱好者",
    "avatarUrl": "https://p1.music.126.net/xxx.jpg"
  }
}
```
