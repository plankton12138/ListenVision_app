# Phase 1 实施指南：后端基础设施搭建

## 📋 概述

Phase 1 是整个项目重构的第一阶段，主要目标是为新的 Bilibili 纯认证系统奠定后端基础。

**时间估算**: 2-3 天
**工作范围**: 数据库迁移 + 后端 API 端点实现 + 单元测试
**输出成果**: 4 个数据表 + 4 个 API 端点 + 单元测试 > 80%

---

## ✅ Pre-Phase 1 检查清单

在开始任何代码实现之前，请确保以下条件都已满足：

### 环境准备

- [ ] Node.js 版本 >= 14 (推荐 16+)
  ```bash
  node --version
  ```

- [ ] MySQL 服务正在运行
  ```bash
  mysql --version
  ```

- [ ] Flutter SDK 已安装且可用
  ```bash
  flutter --version
  ```

- [ ] Git 已初始化（如果需要版本控制）
  ```bash
  cd a:\Projects\flutter_demo_deving
  git status
  ```

### 文档阅读

按照以下顺序阅读相关文档：

- [ ] [BILIBILI_ONLY_ARCHITECTURE.md](./BILIBILI_ONLY_ARCHITECTURE.md) - 整体架构
- [ ] [DATABASE_MIGRATION.md](./DATABASE_MIGRATION.md) - 数据库脚本
- [ ] [API_SPECIFICATION.md](./API_SPECIFICATION.md) - API 详细规范
- [ ] [REQUIREMENTS_SPECIFICATION.md](./REQUIREMENTS_SPECIFICATION.md) - 需求细节
- [ ] [CODE_OPTIMIZATION_GUIDE.md](./CODE_OPTIMIZATION_GUIDE.md) - 代码优化建议
- [ ] [AUTHENTICATION_INTEGRATION.md](./AUTHENTICATION_INTEGRATION.md) - 认证集成设计

### 数据备份

- [ ] 备份现有数据库
  ```bash
  mysqldump -u plankton -p listenvision_app > backup_$(date +%Y%m%d).sql
  ```

- [ ] 备份现有 Flutter 项目（Git 提交或文件夹复制）
  ```bash
  git commit -am "Backup before Phase 1 implementation"
  ```

---

## 🔧 Phase 1 实施步骤

### 步骤 1: 执行数据库迁移（1 小时）

#### 1.1 创建新表

打开 MySQL 客户端并执行以下命令：

```bash
cd a:\Projects\flutter_demo_deving\docs
mysql -u plankton -p listenvision_app < DATABASE_MIGRATION.md
```

或者在 MySQL Workbench 中手动执行 [DATABASE_MIGRATION.md](./DATABASE_MIGRATION.md) 中的 SQL 脚本。

#### 1.2 验证表创建

```sql
-- 登录 MySQL
mysql -u plankton -p listenvision_app

-- 验证所有新表已创建
SHOW TABLES;

-- 检查 bilibili_bindings 表结构
DESCRIBE bilibili_bindings;

-- 检查 device_bindings 表结构
DESCRIBE device_bindings;

-- 检查 bilibili_operations_log 表结构
DESCRIBE bilibili_operations_log;

-- 验证索引
SHOW INDEX FROM bilibili_bindings;
SHOW INDEX FROM device_bindings;
```

**预期输出**:
```
Tables_in_listenvision_app
...
bilibili_bindings
bilibili_operations_log
device_bindings
...
```

#### 1.3 验证检查清单

- [ ] bilibili_bindings 表已创建
- [ ] device_bindings 表已创建
- [ ] bilibili_operations_log 表已创建
- [ ] 所有索引已创建
- [ ] 没有错误或警告

---

### 步骤 2: 创建后端 API 端点（1.5 天）

你需要创建或修改以下后端文件。假设你使用 Node.js + Express：

#### 2.1 创建 Bilibili 认证服务

**文件**: `backend/services/bilibili_auth_service.js` (新建)

```javascript
/**
 * Bilibili 认证服务
 * 处理 B站账号绑定、验证、解绑等业务逻辑
 */

const db = require('../database');
const crypto = require('crypto');

class BilibiliAuthService {
  /**
   * 创建或更新绑定
   * @param {Object} bindData - 绑定数据 { bilibili_uid, bilibili_username, avatar, device_id, device_name, platform }
   * @returns {Promise<Object>} 绑定信息
   */
  async bindBilibili(bindData) {
    const {
      bilibili_uid,
      bilibili_username,
      avatar,
      device_id,
      device_name,
      platform,
    } = bindData;

    try {
      // 检查绑定是否已存在
      const existing = await db.query(
        'SELECT * FROM bilibili_bindings WHERE bilibili_uid = ?',
        [bilibili_uid]
      );

      const now = new Date();

      if (existing.length > 0) {
        // 更新现有绑定
        await db.query(
          `UPDATE bilibili_bindings
           SET bilibili_username = ?, avatar = ?, last_login = ?
           WHERE bilibili_uid = ?`,
          [bilibili_username, avatar, now, bilibili_uid]
        );
      } else {
        // 创建新绑定
        await db.query(
          `INSERT INTO bilibili_bindings
           (bilibili_uid, bilibili_username, avatar, bind_time, last_login, status)
           VALUES (?, ?, ?, ?, ?, 'active')`,
          [bilibili_uid, bilibili_username, avatar, now, now]
        );
      }

      // 更新或创建设备绑定
      const existingDevice = await db.query(
        'SELECT * FROM device_bindings WHERE bilibili_uid = ? AND device_id = ?',
        [bilibili_uid, device_id]
      );

      if (existingDevice.length > 0) {
        await db.query(
          `UPDATE device_bindings
           SET last_active = ?, is_current = 1
           WHERE bilibili_uid = ? AND device_id = ?`,
          [now, bilibili_uid, device_id]
        );
      } else {
        await db.query(
          `INSERT INTO device_bindings
           (bilibili_uid, device_id, device_name, platform, is_current, last_active)
           VALUES (?, ?, ?, ?, 1, ?)`,
          [bilibili_uid, device_id, device_name, platform, now]
        );
      }

      // 记录操作日志
      await this.logOperation({
        bilibili_uid,
        device_id,
        operation: 'bind',
        operation_result: 'success',
        ip_address: '127.0.0.1', // 从请求中获取实际 IP
      });

      return {
        success: true,
        binding_info: {
          bilibili_uid,
          bilibili_username,
          avatar,
          status: 'active',
        },
      };
    } catch (error) {
      console.error('绑定失败:', error);
      throw new Error('绑定 Bilibili 账号失败');
    }
  }

  /**
   * 获取用户信息
   * @param {string} uid - Bilibili 用户 ID
   * @returns {Promise<Object>} 用户信息
   */
  async getUserInfo(uid) {
    try {
      const result = await db.query(
        'SELECT * FROM bilibili_bindings WHERE bilibili_uid = ?',
        [uid]
      );

      if (result.length === 0) {
        throw new Error('用户不存在');
      }

      return {
        success: true,
        user_info: result[0],
      };
    } catch (error) {
      console.error('获取用户信息失败:', error);
      throw new Error('获取用户信息失败');
    }
  }

  /**
   * 解绑账号
   * @param {string} uid - Bilibili 用户 ID
   * @param {string} deviceId - 设备 ID
   * @returns {Promise<Object>} 操作结果
   */
  async unbind(uid, deviceId) {
    try {
      // 删除设备绑定
      await db.query(
        'DELETE FROM device_bindings WHERE bilibili_uid = ? AND device_id = ?',
        [uid, deviceId]
      );

      // 检查是否还有其他设备
      const otherDevices = await db.query(
        'SELECT * FROM device_bindings WHERE bilibili_uid = ?',
        [uid]
      );

      // 如果没有其他设备，删除主绑定
      if (otherDevices.length === 0) {
        await db.query(
          'UPDATE bilibili_bindings SET status = ? WHERE bilibili_uid = ?',
          ['revoked', uid]
        );
      }

      // 记录操作日志
      await this.logOperation({
        bilibili_uid: uid,
        device_id: deviceId,
        operation: 'unbind',
        operation_result: 'success',
        ip_address: '127.0.0.1',
      });

      return { success: true };
    } catch (error) {
      console.error('解绑失败:', error);
      throw new Error('解绑账号失败');
    }
  }

  /**
   * 验证 Cookie 有效性
   * @param {string} uid - Bilibili 用户 ID
   * @returns {Promise<Object>} 验证结果
   */
  async validateCookie(uid) {
    try {
      const result = await db.query(
        'SELECT * FROM bilibili_bindings WHERE bilibili_uid = ?',
        [uid]
      );

      if (result.length === 0) {
        return { is_valid: false, reason: '用户不存在' };
      }

      const binding = result[0];

      // 检查 Cookie 是否过期
      if (binding.cookie_expire_time && binding.cookie_expire_time < new Date()) {
        return { is_valid: false, reason: 'Cookie 已过期' };
      }

      // 检查绑定状态
      if (binding.status !== 'active') {
        return { is_valid: false, reason: '绑定已失效' };
      }

      return { is_valid: true };
    } catch (error) {
      console.error('验证 Cookie 失败:', error);
      throw new Error('验证 Cookie 失败');
    }
  }

  /**
   * 记录操作日志
   * @param {Object} logData - 日志数据
   */
  async logOperation(logData) {
    const { bilibili_uid, device_id, operation, operation_result, ip_address } = logData;

    try {
      await db.query(
        `INSERT INTO bilibili_operations_log
         (bilibili_uid, device_id, operation, operation_result, ip_address, created_at)
         VALUES (?, ?, ?, ?, ?, NOW())`,
        [bilibili_uid, device_id, operation, operation_result, ip_address]
      );
    } catch (error) {
      console.error('记录操作日志失败:', error);
      // 日志失败不应该中断主流程
    }
  }
}

module.exports = new BilibiliAuthService();
```

#### 2.2 创建 API 路由

**文件**: `backend/routes/bilibili_routes.js` (新建)

```javascript
/**
 * Bilibili 认证 API 路由
 */

const express = require('express');
const router = express.Router();
const bilibiliAuthService = require('../services/bilibili_auth_service');

/**
 * POST /api/bilibili/bind
 * 绑定 Bilibili 账号
 *
 * 请求体:
 * {
 *   bilibili_uid: "272017820",
 *   bilibili_username: "username",
 *   avatar: "https://...",
 *   device_id: "device-abc123",
 *   device_name: "iPhone 12",
 *   platform: "iOS"
 * }
 */
router.post('/bind', async (req, res) => {
  try {
    const { bilibili_uid, bilibili_username, avatar, device_id, device_name, platform } =
      req.body;

    // 验证必要字段
    if (!bilibili_uid || !bilibili_username || !device_id) {
      return res.status(400).json({
        code: -400,
        message: '缺少必要参数',
      });
    }

    const result = await bilibiliAuthService.bindBilibili({
      bilibili_uid,
      bilibili_username,
      avatar,
      device_id,
      device_name,
      platform,
    });

    res.json({
      code: 0,
      message: '绑定成功',
      data: result.binding_info,
    });
  } catch (error) {
    console.error('绑定错误:', error);
    res.status(500).json({
      code: -500,
      message: error.message,
    });
  }
});

/**
 * GET /api/bilibili/user/:uid
 * 获取用户信息
 */
router.get('/user/:uid', async (req, res) => {
  try {
    const { uid } = req.params;

    const result = await bilibiliAuthService.getUserInfo(uid);

    res.json({
      code: 0,
      message: '获取成功',
      data: result.user_info,
    });
  } catch (error) {
    console.error('获取用户信息错误:', error);
    res.status(500).json({
      code: -500,
      message: error.message,
    });
  }
});

/**
 * POST /api/bilibili/unbind
 * 解绑账号
 *
 * 请求体:
 * {
 *   bilibili_uid: "272017820",
 *   device_id: "device-abc123"
 * }
 */
router.post('/unbind', async (req, res) => {
  try {
    const { bilibili_uid, device_id } = req.body;

    if (!bilibili_uid || !device_id) {
      return res.status(400).json({
        code: -400,
        message: '缺少必要参数',
      });
    }

    const result = await bilibiliAuthService.unbind(bilibili_uid, device_id);

    res.json({
      code: 0,
      message: '解绑成功',
      data: result,
    });
  } catch (error) {
    console.error('解绑错误:', error);
    res.status(500).json({
      code: -500,
      message: error.message,
    });
  }
});

/**
 * POST /api/bilibili/validate
 * 验证 Cookie 有效性
 *
 * 请求体:
 * {
 *   bilibili_uid: "272017820"
 * }
 */
router.post('/validate', async (req, res) => {
  try {
    const { bilibili_uid } = req.body;

    if (!bilibili_uid) {
      return res.status(400).json({
        code: -400,
        message: '缺少必要参数',
      });
    }

    const result = await bilibiliAuthService.validateCookie(bilibili_uid);

    res.json({
      code: 0,
      message: '验证完成',
      data: result,
    });
  } catch (error) {
    console.error('验证错误:', error);
    res.status(500).json({
      code: -500,
      message: error.message,
    });
  }
});

module.exports = router;
```

#### 2.3 在 Express 主应用中注册路由

**文件**: `backend/app.js` (修改)

```javascript
// ... existing code ...

const bilibiliRoutes = require('./routes/bilibili_routes');

// ... other middleware ...

// 注册 Bilibili 路由
app.use('/api/bilibili', bilibiliRoutes);

// ... rest of app ...
```

#### 2.4 验证 API 端点

启动后端服务器：

```bash
npm start
```

使用 Postman 或 curl 测试各个端点：

```bash
# 测试绑定端点
curl -X POST http://localhost:3000/api/bilibili/bind \
  -H "Content-Type: application/json" \
  -d '{
    "bilibili_uid": "272017820",
    "bilibili_username": "testuser",
    "avatar": "https://example.com/avatar.jpg",
    "device_id": "device-test-001",
    "device_name": "Test Device",
    "platform": "iOS"
  }'

# 预期响应
# {
#   "code": 0,
#   "message": "绑定成功",
#   "data": {
#     "bilibili_uid": "272017820",
#     "bilibili_username": "testuser",
#     "avatar": "https://example.com/avatar.jpg",
#     "status": "active"
#   }
# }

# 测试获取用户信息
curl http://localhost:3000/api/bilibili/user/272017820

# 测试验证
curl -X POST http://localhost:3000/api/bilibili/validate \
  -H "Content-Type: application/json" \
  -d '{"bilibili_uid": "272017820"}'

# 测试解绑
curl -X POST http://localhost:3000/api/bilibili/unbind \
  -H "Content-Type: application/json" \
  -d '{
    "bilibili_uid": "272017820",
    "device_id": "device-test-001"
  }'
```

---

### 步骤 3: 编写单元测试（0.5 天）

#### 3.1 创建测试文件

**文件**: `backend/tests/bilibili_auth_service.test.js` (新建)

```javascript
/**
 * Bilibili 认证服务单元测试
 */

const { describe, test, expect, beforeAll, afterAll } = require('@jest/globals');
const bilibiliAuthService = require('../services/bilibili_auth_service');
const db = require('../database');

// Mock 数据库
jest.mock('../database');

describe('BilibiliAuthService', () => {
  const mockUid = '272017820';
  const mockUsername = 'testuser';
  const mockAvatar = 'https://example.com/avatar.jpg';
  const mockDeviceId = 'device-test-001';
  const mockDeviceName = 'Test Device';
  const mockPlatform = 'iOS';

  describe('bindBilibili', () => {
    test('应该成功创建新绑定', async () => {
      // Mock 数据库查询
      db.query.mockResolvedValueOnce([]); // 检查现有绑定，返回空

      const result = await bilibiliAuthService.bindBilibili({
        bilibili_uid: mockUid,
        bilibili_username: mockUsername,
        avatar: mockAvatar,
        device_id: mockDeviceId,
        device_name: mockDeviceName,
        platform: mockPlatform,
      });

      expect(result.success).toBe(true);
      expect(result.binding_info.bilibili_uid).toBe(mockUid);
      expect(db.query).toHaveBeenCalledTimes(4); // 1个检查 + 1个插入绑定 + 1个插入设备 + 1个日志
    });

    test('应该正确处理缺少参数的情况', async () => {
      const invalidData = {
        bilibili_uid: mockUid,
        // 缺少 bilibili_username
      };

      await expect(
        bilibiliAuthService.bindBilibili(invalidData)
      ).rejects.toThrow();
    });
  });

  describe('getUserInfo', () => {
    test('应该返回存在用户的信息', async () => {
      const mockUserData = {
        bilibili_uid: mockUid,
        bilibili_username: mockUsername,
        status: 'active',
      };

      db.query.mockResolvedValueOnce([mockUserData]);

      const result = await bilibiliAuthService.getUserInfo(mockUid);

      expect(result.success).toBe(true);
      expect(result.user_info).toEqual(mockUserData);
    });

    test('用户不存在时应该抛出错误', async () => {
      db.query.mockResolvedValueOnce([]); // 返回空结果

      await expect(bilibiliAuthService.getUserInfo(mockUid)).rejects.toThrow('用户不存在');
    });
  });

  describe('validateCookie', () => {
    test('有效的 Cookie 应该返回 true', async () => {
      const mockBinding = {
        bilibili_uid: mockUid,
        status: 'active',
        cookie_expire_time: new Date(Date.now() + 86400000), // 24小时后
      };

      db.query.mockResolvedValueOnce([mockBinding]);

      const result = await bilibiliAuthService.validateCookie(mockUid);

      expect(result.is_valid).toBe(true);
    });

    test('过期的 Cookie 应该返回 false', async () => {
      const mockBinding = {
        bilibili_uid: mockUid,
        status: 'active',
        cookie_expire_time: new Date(Date.now() - 86400000), // 24小时前
      };

      db.query.mockResolvedValueOnce([mockBinding]);

      const result = await bilibiliAuthService.validateCookie(mockUid);

      expect(result.is_valid).toBe(false);
      expect(result.reason).toBe('Cookie 已过期');
    });
  });

  describe('unbind', () => {
    test('应该成功解绑设备', async () => {
      // Mock 删除设备
      db.query.mockResolvedValueOnce({ affectedRows: 1 });
      // Mock 检查其他设备
      db.query.mockResolvedValueOnce([]); // 没有其他设备
      // Mock 更新主绑定状态
      db.query.mockResolvedValueOnce({ affectedRows: 1 });
      // Mock 日志
      db.query.mockResolvedValueOnce({ affectedRows: 1 });

      const result = await bilibiliAuthService.unbind(mockUid, mockDeviceId);

      expect(result.success).toBe(true);
    });
  });
});
```

#### 3.2 运行测试

```bash
# 安装 Jest (如果还没有)
npm install --save-dev jest

# 运行测试
npm test

# 生成覆盖率报告
npm test -- --coverage
```

**预期输出**:
```
PASS  tests/bilibili_auth_service.test.js
  BilibiliAuthService
    bindBilibili
      ✓ 应该成功创建新绑定
      ✓ 应该正确处理缺少参数的情况
    getUserInfo
      ✓ 应该返回存在用户的信息
      ✓ 用户不存在时应该抛出错误
    validateCookie
      ✓ 有效的 Cookie 应该返回 true
      ✓ 过期的 Cookie 应该返回 false
    unbind
      ✓ 应该成功解绑设备

Test Suites: 1 passed, 1 total
Tests:       7 passed, 7 total
Coverage:    85% statements, 82% branches, 80% functions, 86% lines

```

---

## 🧪 Phase 1 验收标准

Phase 1 完成后，应满足以下所有条件：

### 数据库

- [ ] 所有 4 个新表已创建
- [ ] 所有索引已创建且有效
- [ ] 表结构与 [DATABASE_MIGRATION.md](./DATABASE_MIGRATION.md) 一致
- [ ] 能够成功插入测试数据
- [ ] 能够成功查询和更新数据

### API 端点

- [ ] `/api/bilibili/bind` - POST 端点可调用且返回正确响应
- [ ] `/api/bilibili/user/:uid` - GET 端点可调用且返回用户信息
- [ ] `/api/bilibili/unbind` - POST 端点可调用
- [ ] `/api/bilibili/validate` - POST 端点可调用
- [ ] 所有端点都有正确的错误处理

### 单元测试

- [ ] 所有测试用例都通过
- [ ] 代码覆盖率 >= 80%
- [ ] 测试覆盖以下场景：
  - 创建新绑定
  - 更新现有绑定
  - 用户存在/不存在
  - Cookie 有效/过期
  - 解绑操作
  - 错误处理

### 文档

- [ ] 代码中包含清晰的注释
- [ ] 函数和方法都有 JSDoc 注释
- [ ] API 文档已更新
- [ ] 测试用例已文档化

---

## 📊 Phase 1 进度跟踪

使用以下表格跟踪进度：

| 任务 | 状态 | 完成日期 | 备注 |
|------|------|---------|------|
| 数据库迁移 | ☐ | - | - |
| API 认证服务实现 | ☐ | - | - |
| API 路由实现 | ☐ | - | - |
| API 端点测试 | ☐ | - | - |
| 单元测试编写 | ☐ | - | - |
| 单元测试通过 | ☐ | - | - |
| 覆盖率检查 | ☐ | - | - |
| 代码审查 | ☐ | - | - |
| **Phase 1 完成** | ☐ | - | - |

---

## 🚨 常见问题和解决方案

### Q: 数据库迁移失败

**A**: 检查以下几点：
1. MySQL 服务是否运行
2. 数据库 `listenvision_app` 是否存在
3. 用户是否有正确的权限
4. SQL 脚本是否有语法错误

```bash
# 测试数据库连接
mysql -u plankton -p -e "SELECT 1;"

# 列出所有数据库
mysql -u plankton -p -e "SHOW DATABASES;"
```

### Q: API 端点返回 500 错误

**A**: 检查：
1. 服务器日志中的错误信息
2. 是否正确导入了依赖模块
3. 是否正确连接了数据库
4. 是否缺少必要的环境变量

```bash
# 查看完整错误
npm start

# 或使用调试模式
DEBUG=* npm start
```

### Q: 单元测试失败

**A**:
1. 检查 mock 配置是否正确
2. 验证测试数据是否符合数据库架构
3. 检查异步操作是否正确处理

```bash
# 运行单个测试文件的调试
node --inspect-brk node_modules/.bin/jest tests/bilibili_auth_service.test.js

# 运行特定测试
npm test -- --testNamePattern="bindBilibili"
```

---

## ✨ 下一步

当 Phase 1 完成并验收后，你将准备好进入 **Phase 2: 实现 BilibiliAuthService + 集成测试**，其中将：

1. 集成 Bilibili QR 码登录流程
2. 实现更复杂的认证逻辑
3. 添加集成测试
4. 与前端开始联调

---

**预计完成时间**: 2-3 天
**下一个里程碑**: Phase 1 验收完成后开始 Phase 2

