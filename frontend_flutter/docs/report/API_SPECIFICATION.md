# Bilibili 认证 API 规范

## 📋 概述

本文档定义 Bilibili 纯认证系统的完整 API 规范。

**基础信息**：
- 基础 URL: `http://localhost:3000`
- 认证方式: Device ID (设备唯一标识)
- 数据格式: JSON
- 字符编码: UTF-8

---

## 🔐 认证方式

### Device ID 认证

所有请求需要在请求头或请求体中提供 `device_id`：

```javascript
// 方式 1: 请求头（推荐）
Headers: {
  'Device-Id': 'uuid-xxx-xxx-xxx'
}

// 方式 2: 请求体
Body: {
  device_id: 'uuid-xxx-xxx-xxx',
  ...
}
```

**Device ID 来源**：
- 由客户端生成（UUID v4）
- 每个设备唯一
- 首次绑定时创建，持久化存储

---

## 📡 API 端点

### 1. 创建/更新绑定 - POST /api/bilibili/bind

**功能**: 创建新的 B站绑定或更新现有绑定

**请求头**:
```
Content-Type: application/json
Device-Id: uuid-xxx-xxx-xxx (可选，也可在请求体中)
```

**请求体**:
```json
{
  "bilibili_uid": 272017820,
  "bilibili_username": "username",
  "avatar": "https://i0.hdslb.com/bfs/face/xxx",
  "device_id": "uuid-xxx-xxx-xxx",
  "device_name": "iPhone 15 Pro",
  "platform": "iOS",
  "os_version": "17.2",
  "app_version": "1.0.0"
}
```

**返回 (201 Created)**:
```json
{
  "success": true,
  "binding_info": {
    "id": 1,
    "bilibili_uid": 272017820,
    "bilibili_username": "username",
    "avatar": "https://i0.hdslb.com/bfs/face/xxx",
    "bind_time": "2026-01-03T12:00:00Z",
    "last_login": "2026-01-03T12:00:00Z",
    "status": "active",
    "devices": [
      {
        "id": 1,
        "device_id": "uuid-xxx-xxx-xxx",
        "device_name": "iPhone 15 Pro",
        "platform": "iOS",
        "is_current": true,
        "last_active": "2026-01-03T12:00:00Z"
      }
    ]
  }
}
```

**错误响应 (400)**:
```json
{
  "success": false,
  "error": "缺少必要参数: bilibili_uid"
}
```

**错误响应 (409 - 冲突)**:
```json
{
  "success": false,
  "error": "该B站账号已被其他设备绑定，请解绑后重试"
}
```

---

### 2. 获取用户信息 - GET /api/bilibili/user/:uid

**功能**: 获取已绑定用户的信息和设备列表

**URL 参数**:
- `uid`: B站用户ID (必需)

**请求头**:
```
Device-Id: uuid-xxx-xxx-xxx
```

**返回 (200)**:
```json
{
  "success": true,
  "user_info": {
    "bilibili_uid": 272017820,
    "bilibili_username": "username",
    "avatar": "https://i0.hdslb.com/bfs/face/xxx",
    "bind_time": "2026-01-03T12:00:00Z",
    "last_login": "2026-01-03T12:00:00Z",
    "status": "active",
    "cookie_expire_time": "2026-01-05T12:00:00Z"
  },
  "devices": [
    {
      "id": 1,
      "device_id": "uuid-xxx-xxx-xxx",
      "device_name": "iPhone 15 Pro",
      "platform": "iOS",
      "os_version": "17.2",
      "app_version": "1.0.0",
      "is_current": true,
      "last_active": "2026-01-03T12:00:00Z",
      "bind_time": "2026-01-03T12:00:00Z"
    },
    {
      "id": 2,
      "device_id": "uuid-yyy-yyy-yyy",
      "device_name": "Windows PC",
      "platform": "Windows",
      "os_version": "11",
      "app_version": "1.0.0",
      "is_current": false,
      "last_active": "2026-01-02T18:00:00Z",
      "bind_time": "2026-01-01T10:00:00Z"
    }
  ]
}
```

**错误响应 (404)**:
```json
{
  "success": false,
  "error": "用户未找到"
}
```

---

### 3. 解绑账号 - POST /api/bilibili/unbind

**功能**: 解绑账号或删除特定设备

**请求体**:
```json
{
  "bilibili_uid": 272017820,
  "device_id": "uuid-xxx-xxx-xxx",  // 可选：仅删除此设备，不提供则删除整个账号
  "reason": "user_request"  // 可选：解绑原因
}
```

**返回 (200)**:
```json
{
  "success": true,
  "message": "设备已解绑"  // 或 "账号已完全解绑"
}
```

**错误响应 (400)**:
```json
{
  "success": false,
  "error": "无效的 bilibili_uid"
}
```

**错误响应 (404)**:
```json
{
  "success": false,
  "error": "用户或设备未找到"
}
```

---

### 4. 验证绑定有效性 - POST /api/bilibili/validate

**功能**: 验证账号或 Cookie 是否仍然有效

**请求体**:
```json
{
  "bilibili_uid": 272017820,
  "device_id": "uuid-xxx-xxx-xxx"  // 可选
}
```

**返回 (200)**:
```json
{
  "success": true,
  "is_valid": true,
  "status": "active",
  "cookie_expire_time": "2026-01-05T12:00:00Z",
  "remaining_days": 2
}
```

**Cookie 过期响应 (200)**:
```json
{
  "success": true,
  "is_valid": false,
  "status": "expired",
  "message": "Cookie已过期，请重新绑定",
  "cookie_expire_time": "2026-01-02T12:00:00Z"
}
```

---

## 📝 通用响应格式

### 成功响应

```json
{
  "success": true,
  "data": { /* 具体数据 */ },
  "message": "操作成功"  // 可选
}
```

### 错误响应

```json
{
  "success": false,
  "error": "错误信息",
  "error_code": "ERROR_CODE",  // 可选
  "timestamp": "2026-01-03T12:00:00Z"
}
```

### 常见错误码

| 错误码 | HTTP 状态码 | 说明 |
|-------|---------|------|
| `INVALID_PARAMS` | 400 | 参数错误 |
| `MISSING_PARAMS` | 400 | 缺少必要参数 |
| `UNAUTHORIZED` | 401 | 未授权 |
| `FORBIDDEN` | 403 | 禁止访问 |
| `NOT_FOUND` | 404 | 资源未找到 |
| `CONFLICT` | 409 | 资源冲突（如账号已绑定） |
| `SERVER_ERROR` | 500 | 服务器错误 |

---

## 🔄 业务流程

### 绑定流程

```
客户端 (Flutter)
  ↓
1. 调用 B站 API 获取二维码和 qrcode_key
  ↓
2. 用户扫码确认
  ↓
3. 调用 B站 API 轮询登录状态
  ↓
4. 登录成功，获取 Cookie 和用户信息
  ↓
5. POST /api/bilibili/bind
  ├─ 请求体: { bilibili_uid, username, avatar, device_id, ... }
  ├─ 服务器: 创建 bilibili_bindings 记录
  ├─ 服务器: 创建 device_bindings 记录
  ├─ 服务器: 记录日志
  └─ 返回: binding_info + 已有设备列表
  ↓
6. 客户端存储 bilibili_uid 到 SharedPreferences
  ↓
7. 客户端存储 Cookie 到 SecureStorage
  ↓
8. 客户端导航到首页
```

### 验证流程

```
每次启动应用
  ↓
1. 检查本地是否有 bilibili_uid
  ├─ 没有: 跳转到绑定页面
  └─ 有: 继续
  ↓
2. 读取本地 Cookie (SecureStorage)
  ├─ 找不到: Cookie 已丢失，重新绑定
  └─ 找到: 继续
  ↓
3. POST /api/bilibili/validate
  ├─ 有效: 进入首页
  ├─ 过期: 提示重新绑定
  └─ 错误: 处理错误
```

---

## 🧪 测试用例

### 单元测试

```javascript
// tests/bilibili.test.js

describe('POST /api/bilibili/bind', () => {
  test('应该成功创建新绑定', async () => {
    const response = await request(app)
      .post('/api/bilibili/bind')
      .send({
        bilibili_uid: 272017820,
        bilibili_username: 'test_user',
        avatar: 'https://example.com/avatar.jpg',
        device_id: 'test-device-id',
        device_name: 'Test Device',
        platform: 'Android'
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.binding_info.bilibili_uid).toBe(272017820);
  });

  test('应该拒绝重复绑定', async () => {
    // 第一次绑定
    await request(app).post('/api/bilibili/bind').send({ /* ... */ });

    // 尝试用另一个设备重复绑定
    const response = await request(app)
      .post('/api/bilibili/bind')
      .send({
        bilibili_uid: 272017820,  // 相同的 uid
        device_id: 'another-device-id',  // 不同的设备
        // ...
      });

    expect(response.status).toBe(409);
    expect(response.body.success).toBe(false);
  });

  test('应该验证必需参数', async () => {
    const response = await request(app)
      .post('/api/bilibili/bind')
      .send({
        // 缺少 bilibili_uid
        bilibili_username: 'test_user',
        // ...
      });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('bilibili_uid');
  });
});

describe('GET /api/bilibili/user/:uid', () => {
  test('应该返回用户信息和设备列表', async () => {
    // 先创建绑定
    await request(app).post('/api/bilibili/bind').send({ /* ... */ });

    const response = await request(app)
      .get('/api/bilibili/user/272017820')
      .set('Device-Id', 'test-device-id');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.user_info.bilibili_uid).toBe(272017820);
    expect(Array.isArray(response.body.devices)).toBe(true);
  });

  test('应该返回 404 当用户不存在', async () => {
    const response = await request(app)
      .get('/api/bilibili/user/999999999')
      .set('Device-Id', 'test-device-id');

    expect(response.status).toBe(404);
  });
});

describe('POST /api/bilibili/unbind', () => {
  test('应该成功解绑设备', async () => {
    // 先创建绑定
    await request(app).post('/api/bilibili/bind').send({ /* ... */ });

    const response = await request(app)
      .post('/api/bilibili/unbind')
      .send({
        bilibili_uid: 272017820,
        device_id: 'test-device-id'
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
  });

  test('应该成功解绑整个账号', async () => {
    // 先创建绑定
    await request(app).post('/api/bilibili/bind').send({ /* ... */ });

    const response = await request(app)
      .post('/api/bilibili/unbind')
      .send({
        bilibili_uid: 272017820
        // 不提供 device_id，删除整个账号
      });

    expect(response.status).toBe(200);
    expect(response.body.message).toContain('完全解绑');
  });
});
```

### 集成测试

```javascript
describe('B站绑定完整流程', () => {
  test('应该完成绑定 → 验证 → 解绑的完整流程', async () => {
    const deviceId = 'integration-test-device';

    // 1. 绑定
    let response = await request(app)
      .post('/api/bilibili/bind')
      .send({
        bilibili_uid: 272017820,
        bilibili_username: 'test_user',
        avatar: 'https://example.com/avatar.jpg',
        device_id: deviceId,
        device_name: 'Test Device',
        platform: 'Android'
      });
    expect(response.status).toBe(201);

    // 2. 验证
    response = await request(app)
      .post('/api/bilibili/validate')
      .send({ bilibili_uid: 272017820, device_id: deviceId });
    expect(response.status).toBe(200);
    expect(response.body.is_valid).toBe(true);

    // 3. 获取用户信息
    response = await request(app)
      .get('/api/bilibili/user/272017820')
      .set('Device-Id', deviceId);
    expect(response.status).toBe(200);
    expect(response.body.devices.length).toBeGreaterThan(0);

    // 4. 解绑
    response = await request(app)
      .post('/api/bilibili/unbind')
      .send({ bilibili_uid: 272017820 });
    expect(response.status).toBe(200);

    // 5. 验证已解绑
    response = await request(app)
      .get('/api/bilibili/user/272017820')
      .set('Device-Id', deviceId);
    expect(response.status).toBe(404);
  });
});
```

---

## 📊 数据库操作示例

### 创建绑定

```javascript
async function createBinding(bindingData) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    // 1. 创建绑定记录
    const [bindingResult] = await connection.execute(
      `INSERT INTO bilibili_bindings
       (bilibili_uid, bilibili_username, avatar, status)
       VALUES (?, ?, ?, 'active')`,
      [bindingData.bilibili_uid, bindingData.bilibili_username, bindingData.avatar]
    );

    // 2. 创建设备绑定记录
    await connection.execute(
      `INSERT INTO device_bindings
       (bilibili_uid, device_id, device_name, platform, os_version, app_version, is_current)
       VALUES (?, ?, ?, ?, ?, ?, true)`,
      [
        bindingData.bilibili_uid,
        bindingData.device_id,
        bindingData.device_name,
        bindingData.platform,
        bindingData.os_version,
        bindingData.app_version
      ]
    );

    // 3. 记录操作日志
    await connection.execute(
      `INSERT INTO bilibili_operations_log
       (bilibili_uid, device_id, operation, operation_result, ip_address)
       VALUES (?, ?, 'bind', 'success', ?)`,
      [bindingData.bilibili_uid, bindingData.device_id, bindingData.ip_address]
    );

    await connection.commit();
    return { success: true, id: bindingResult.insertId };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.release();
  }
}
```

---

## 🔒 安全要求

- [ ] 验证所有输入参数
- [ ] 使用 HTTPS
- [ ] 限制请求频率（防止暴力破解）
- [ ] 记录所有操作日志
- [ ] 定期备份数据库
- [ ] Cookie 不在日志中打印

---

**版本**: 1.0
**日期**: 2026-01-03
**最后更新**: 待执行
