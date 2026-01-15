# 纯 Bilibili 认证架构设计 - 完整重构计划

## 📋 执行摘要

本文档描述从**复杂的用户名/密码认证系统**重构为**纯 Bilibili 账号绑定系统**的完整计划。

**核心变化**：
- ✅ 保留现有数据库（user, favorites 表）
- ✅ 新建独立数据库体系（bilibili_* 表）
- ✅ 逐步迁移，完全兼容
- ✅ 每个阶段都有测试

---

## 🏗️ 架构对比

### 原架构（复杂）

```
Frontend (Flutter)
├─ Login Page (用户名/密码)
├─ Register Page (邮箱注册)
├─ Reset Password Page (密码重置)
└─ Binding Page (绑定 B站) ← 可选

Backend (Node.js)
├─ POST /api/register       (用户注册)
├─ POST /api/login          (用户登录)
├─ POST /api/send-code      (发送验证码)
├─ POST /api/reset-pwd      (重置密码)
└─ POST /api/bindings/*     (B站绑定)

Database
├─ users              (用户表)
├─ favorites          (收藏表)
└─ (platform_bindings) ← SQLite 本地

问题：
❌ 两套认证系统
❌ 用户可以不登录就使用（用硬编码 Cookie）
❌ 无法追踪真实用户
❌ 邮箱验证和密码重置成本高
```

### 新架构（简洁）

```
Frontend (Flutter)
├─ Binding Page (B站二维码扫码)
└─ Home Page (已绑定用户首页)

Backend (Node.js)
├─ POST /api/bilibili/bind          (创建/更新绑定)
├─ GET /api/bilibili/user/:uid      (获取用户信息)
├─ POST /api/bilibili/unbind        (解绑)
├─ POST /api/bilibili/validate      (验证 Cookie)
└─ 保留现有 /api/favorites/*        (收藏功能)

Database (新建)
├─ bilibili_bindings       (B站绑定表 - 主表)
├─ bilibili_cookies        (Cookie 管理表 - 备用)
├─ device_bindings         (设备绑定表 - 多设备支持)
└─ bilibili_bindings_log   (操作日志表 - 审计)

优势：
✅ 单一认证系统
✅ 真实用户身份追踪
✅ 简化后端逻辑
✅ 支持多设备登录
✅ 符合用户期望
```

---

## 📊 数据库设计

### 新建表结构（不修改旧表）

#### 表 1: `bilibili_bindings` - B站绑定主表

```sql
CREATE TABLE bilibili_bindings (
  id INT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  bilibili_uid BIGINT NOT NULL UNIQUE COMMENT 'B站用户ID',
  bilibili_username VARCHAR(255) NOT NULL COMMENT 'B站用户名',
  avatar TEXT COMMENT '用户头像',

  -- 绑定时间信息
  bind_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '绑定时间',
  last_login TIMESTAMP NULL COMMENT '最后登录时间',

  -- Cookie 管理
  last_cookie_refresh TIMESTAMP NULL COMMENT '最后刷新 Cookie 时间',
  cookie_expire_time TIMESTAMP NULL COMMENT 'Cookie 预计过期时间',

  -- 状态管理
  status ENUM('active', 'expired', 'revoked') DEFAULT 'active' COMMENT '绑定状态',

  -- 审计字段
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_status (status),
  INDEX idx_bind_time (bind_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='B站账号绑定信息表';
```

#### 表 2: `device_bindings` - 设备绑定表（支持多设备）

```sql
CREATE TABLE device_bindings (
  id INT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  bilibili_uid BIGINT NOT NULL COMMENT 'B站用户ID',
  device_id VARCHAR(255) NOT NULL COMMENT '设备唯一标识 (UUID)',
  device_name VARCHAR(255) COMMENT '设备名称 (e.g., iPhone 15)',
  platform VARCHAR(50) COMMENT '操作系统 (Android/iOS/Windows/Web)',
  os_version VARCHAR(50) COMMENT '系统版本',
  app_version VARCHAR(50) COMMENT '应用版本',

  -- 设备状态
  is_current BOOLEAN DEFAULT FALSE COMMENT '是否为当前设备',
  last_active TIMESTAMP NULL COMMENT '最后活跃时间',

  -- 审计
  bind_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY unique_device (bilibili_uid, device_id),
  FOREIGN KEY (bilibili_uid) REFERENCES bilibili_bindings(bilibili_uid)
    ON DELETE CASCADE,
  INDEX idx_bilibili_uid (bilibili_uid),
  INDEX idx_last_active (last_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='设备绑定表';
```

#### 表 3: `bilibili_operations_log` - 操作日志表

```sql
CREATE TABLE bilibili_operations_log (
  id INT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  bilibili_uid BIGINT NOT NULL COMMENT 'B站用户ID',
  device_id VARCHAR(255) COMMENT '设备ID',

  -- 操作类型
  operation VARCHAR(50) COMMENT '操作类型 (bind/unbind/login/logout)',
  operation_result VARCHAR(50) COMMENT '操作结果 (success/failed)',
  error_message TEXT COMMENT '错误信息',

  -- IP 和用户代理
  ip_address VARCHAR(45) COMMENT '用户IP',
  user_agent TEXT COMMENT 'User-Agent',

  -- 时间戳
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_bilibili_uid (bilibili_uid),
  INDEX idx_operation (operation),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='B站操作日志表';
```

#### 表 4: `bilibili_cookies` - Cookie 管理表（可选）

```sql
CREATE TABLE bilibili_cookies (
  id INT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  bilibili_uid BIGINT NOT NULL UNIQUE COMMENT 'B站用户ID',

  -- Cookie 信息（加密存储）
  encrypted_cookie LONGTEXT NOT NULL COMMENT '加密的 Cookie',

  -- Cookie 元数据
  cookie_hash VARCHAR(255) COMMENT 'Cookie 哈希（用于快速比对）',
  obtain_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Cookie 获取时间',
  expire_time TIMESTAMP NOT NULL COMMENT 'Cookie 过期时间',
  refresh_count INT DEFAULT 0 COMMENT '刷新次数',

  -- 来源信息
  source VARCHAR(50) COMMENT 'Cookie 来源 (qrcode/manual)',

  -- 状态
  status ENUM('valid', 'expired', 'revoked') DEFAULT 'valid',

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (bilibili_uid) REFERENCES bilibili_bindings(bilibili_uid)
    ON DELETE CASCADE,
  INDEX idx_status (status),
  INDEX idx_expire_time (expire_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='B站 Cookie 管理表（可选，用于高级场景）';
```

#### 修改现有表：`favorites` 表

```sql
-- 添加新字段，保持向后兼容
ALTER TABLE favorites
ADD COLUMN bilibili_uid BIGINT DEFAULT NULL COMMENT 'B站用户ID' AFTER username,
ADD FOREIGN KEY (bilibili_uid) REFERENCES bilibili_bindings(bilibili_uid)
  ON DELETE SET NULL;

-- 迁移数据（过渡期）
-- 如果 username 对应一个 bilibili_uid，则填充 bilibili_uid
-- UPDATE favorites f
-- SET f.bilibili_uid = (SELECT b.bilibili_uid FROM bilibili_bindings b WHERE b.bilibili_username = f.username)
-- WHERE f.bilibili_uid IS NULL;
```

---

## 🔄 新旧数据库共存策略

### 过渡期方案

```
╔═══════════════════════════════════════════════════════════════╗
║                        过渡期共存                              ║
║  Phase 1-3: 新系统独立开发和测试（不影响现有系统）            ║
║  Phase 4-5: 并行运行，用户可选择登录方式                      ║
║  Phase 6+:  逐步迁移，最终废弃旧系统                          ║
╚═══════════════════════════════════════════════════════════════╝

老用户（使用 users 表）
  ├─ 仍然可以登录（用用户名/密码）
  ├─ 使用旧的 favorites 表
  └─ 可选：绑定 B站账号（迁移到新系统）

新用户（使用 bilibili_bindings 表）
  ├─ 直接扫码绑定 B站
  ├─ 使用新的 bilibili_* 表
  └─ 无需输入用户名/密码
```

### 数据库隔离

```javascript
// 后端路由隔离
const oldAuth = require('./routes/auth-old');      // /api/auth/*
const newAuth = require('./routes/auth-bilibili'); // /api/bilibili/*
const favorites = require('./routes/favorites');    // /api/favorites/*

app.use('/api/auth', oldAuth);          // 旧认证系统（保留）
app.use('/api/bilibili', newAuth);      // 新认证系统（新增）
app.use('/api/favorites', favorites);   // 共享（两个系统都能用）
```

---

## 🚀 分阶段实施计划

### Phase 1: 后端数据库和 API 创建（2天）

#### 目标
- 创建新数据库表
- 实现 4 个新 API 端点
- 编写单元测试

#### 任务列表

**1.1 创建新表** ✓

- [ ] 创建 `bilibili_bindings` 表
- [ ] 创建 `device_bindings` 表
- [ ] 创建 `bilibili_operations_log` 表
- [ ] 创建 `bilibili_cookies` 表（可选）
- [ ] 修改 `favorites` 表

**1.2 实现 API 端点**

```
POST /api/bilibili/bind
  请求体：{
    bilibili_uid: 272017820,
    bilibili_username: "username",
    avatar: "https://...",
    device_id: "uuid",
    device_name: "iPhone 15",
    platform: "iOS"
  }
  返回：{ success: true, binding_info: {...} }

GET /api/bilibili/user/:uid
  请求头：Authorization: Bearer <device_id>
  返回：{ user_info: {...}, devices: [...] }

POST /api/bilibili/unbind
  请求体：{ bilibili_uid: 272017820, device_id?: "uuid" }
  返回：{ success: true }

POST /api/bilibili/validate
  请求体：{ bilibili_uid: 272017820 }
  返回：{ is_valid: true, expires_at: "2026-01-05" }
```

**1.3 编写单元测试**

- [ ] 数据库连接测试
- [ ] API 端点测试（POST /api/bilibili/bind）
- [ ] API 端点测试（GET /api/bilibili/user/:uid）
- [ ] 错误处理测试
- [ ] 数据验证测试

**1.4 集成测试**

- [ ] 完整绑定流程测试
- [ ] 多设备绑定测试
- [ ] 旧 API 兼容性测试

#### 验收标准

- ✅ 所有表创建成功
- ✅ 所有 API 端点可用
- ✅ 单元测试覆盖率 > 80%
- ✅ 集成测试全部通过
- ✅ 旧系统（users 表）不受影响

---

### Phase 2: Bilibili 认证服务（2-3天）

#### 目标
- 实现二维码生成和轮询
- 获取用户信息和 Cookie
- 与后端 API 集成

#### 任务列表

**2.1 创建 BilibiliAuthService**

```dart
class BilibiliAuthService {
  // 1. 生成二维码
  Future<QRCodeResult> generateQRCode()

  // 2. 轮询扫码状态
  Stream<QRCodePollResult> pollQRCodeStatus(String qrcodeKey)

  // 3. 获取用户信息
  Future<BilibiliUserInfo> getUserInfo(String cookie)

  // 4. 完整流程
  Stream<AuthProgress> startQRCodeLogin()
}
```

**2.2 处理 B站 API**

- [ ] 调用 `/x/passport-login/web/qrcode/generate`
- [ ] 调用 `/x/passport-login/web/qrcode/poll`
- [ ] 调用 `/x/web-interface/nav`
- [ ] 提取 Cookie

**2.3 编写集成测试**

- [ ] 二维码生成测试
- [ ] 轮询状态测试
- [ ] Cookie 提取测试
- [ ] 错误处理测试（过期、超时等）

**2.4 与后端 API 集成**

- [ ] 调用 `POST /api/bilibili/bind`
- [ ] 保存绑定信息
- [ ] 错误恢复机制

#### 验收标准

- ✅ 二维码可正常生成
- ✅ 扫码登录流程完整
- ✅ 能正确获取 Cookie
- ✅ 集成测试全部通过
- ✅ 错误处理完善

---

### Phase 3: Flutter 数据模型简化（1-2天）

#### 目标
- 删除复杂的用户模型
- 创建简洁的 BilibiliUser 模型
- 删除平台账号相关模型

#### 任务列表

**3.1 创建新数据模型**

- [ ] 创建 `BilibiliUser` 模型
- [ ] 创建 `DeviceBinding` 模型
- [ ] 创建 `AuthStatus` 枚举
- [ ] 创建 API 响应模型

**3.2 删除旧模型**

- [ ] ❌ 删除 `User` 模型
- [ ] ❌ 删除 `PlatformAccount` 类
- [ ] ❌ 删除 `PlatformBindingModel` 类
- [ ] ❌ 删除所有认证相关模型

**3.3 单元测试**

- [ ] 模型序列化测试
- [ ] 模型验证测试
- [ ] JSON 解析测试

**3.4 更新现有模型**

- [ ] 修改 `AudioModel`（关联到 BilibiliUser）
- [ ] 修改 `FavoriteModel`（关联到 BilibiliUser）

#### 验收标准

- ✅ 新模型完整且可用
- ✅ 旧模型完全移除
- ✅ 单元测试全部通过
- ✅ 代码编译无错误

---

### Phase 4: UI 改造和启动流程（2-3天）

#### 目标
- 创建/修改绑定页面
- 实现启动检查流程
- 删除登录/注册页面

#### 任务列表

**4.1 创建绑定页面**

- [ ] 创建 `BilibiliBindingPage`
- [ ] 显示二维码（QrImageView）
- [ ] 显示扫码状态
- [ ] 处理成功/失败
- [ ] 支持重试

**4.2 删除旧页面**

- [ ] ❌ 删除 `LoginPage`
- [ ] ❌ 删除 `RegisterPage`
- [ ] ❌ 删除 `ResetPasswordPage`

**4.3 实现启动检查**

```dart
class AppInitializer {
  Future<void> initializeApp() {
    // 1. 检查是否已绑定
    // 2. 验证 Cookie 有效性
    // 3. 导航到首页或绑定页面
  }
}
```

**4.4 更新路由**

- [ ] 修改 `lib/routes/router.dart`
- [ ] 删除旧路由
- [ ] 添加新路由

**4.5 E2E 测试**

- [ ] 冷启动测试（未绑定）
- [ ] 热启动测试（已绑定）
- [ ] 绑定流程测试
- [ ] 导航流程测试

#### 验收标准

- ✅ 绑定页面可用
- ✅ 启动流程完整
- ✅ 旧页面完全移除
- ✅ E2E 测试全部通过

---

### Phase 5: 功能集成和多设备支持（2-3天）

#### 目标
- 搜索、下载、收藏功能集成
- 支持多设备登录
- 完整的用户体验

#### 任务列表

**5.1 集成搜索功能**

- [ ] 修改 `SearchPage`
- [ ] 使用 BilibiliUser 的 Cookie
- [ ] 更新搜索 API 调用

**5.2 集成下载功能**

- [ ] 修改 `DownloadManager`
- [ ] 关联到 BilibiliUser
- [ ] 保存下载记录到用户账号

**5.3 集成收藏功能**

- [ ] 修改 `FavoriteModel`
- [ ] 调用 `/api/favorites/*`
- [ ] 关联到 BilibiliUser

**5.4 多设备管理**

- [ ] 创建 `DeviceManagementPage`
- [ ] 显示已绑定设备列表
- [ ] 支持远程解绑设备

**5.5 系统测试**

- [ ] 搜索功能测试
- [ ] 下载功能测试
- [ ] 收藏功能测试
- [ ] 多设备同步测试
- [ ] 离线功能测试

#### 验收标准

- ✅ 所有功能正常工作
- ✅ 多设备支持完整
- ✅ 用户体验流畅
- ✅ 系统测试全部通过

---

### Phase 6: 性能优化和文档完善（1-2天）

#### 目标
- 性能优化
- 完整的项目文档
- 发布准备

#### 任务列表

**6.1 性能优化**

- [ ] 本地缓存优化
- [ ] API 调用优化
- [ ] 数据库查询优化
- [ ] UI 渲染优化

**6.2 文档更新**

- [ ] 更新 README.md
- [ ] 创建用户使用文档
- [ ] 创建开发者指南
- [ ] API 文档（OpenAPI/Swagger）

**6.3 代码审查**

- [ ] 代码质量检查
- [ ] 安全审计
- [ ] 性能审计

**6.4 发布测试**

- [ ] Android 打包测试
- [ ] iOS 打包测试（如适用）
- [ ] Windows 打包测试
- [ ] 版本号更新

#### 验收标准

- ✅ 性能指标达标
- ✅ 文档完整
- ✅ 代码审查通过
- ✅ 可发布状态

---

## 🧪 测试策略

### 测试金字塔

```
        🎯 E2E 测试
       /   \      (冷启动/热启动/绑定流程)
      /     \
     / 集成测试 \  (API 集成/多功能协作)
    /         \
   / 单元测试   \ (模型/服务/工具函数)
  /___________\
```

### 测试清单

#### Phase 1: 后端测试

**单元测试**：
- [ ] 数据库操作测试
- [ ] 输入验证测试
- [ ] 错误处理测试

**集成测试**：
- [ ] API 完整流程测试
- [ ] 数据库事务测试
- [ ] 错误场景测试

#### Phase 2: 认证服务测试

**单元测试**：
- [ ] 二维码生成测试
- [ ] 轮询逻辑测试
- [ ] 数据解析测试

**集成测试**：
- [ ] 完整认证流程测试
- [ ] API 集成测试
- [ ] 网络错误处理测试

#### Phase 3: 模型测试

**单元测试**：
- [ ] 序列化/反序列化测试
- [ ] 验证逻辑测试
- [ ] 边界条件测试

#### Phase 4: UI 测试

**Widget 测试**：
- [ ] 页面渲染测试
- [ ] 用户交互测试
- [ ] 状态管理测试

**E2E 测试**：
- [ ] 冷启动流程
- [ ] 绑定流程
- [ ] 导航流程

#### Phase 5: 功能测试

**功能测试**：
- [ ] 搜索功能
- [ ] 下载功能
- [ ] 收藏功能
- [ ] 多设备同步

**性能测试**：
- [ ] 启动时间
- [ ] API 响应时间
- [ ] 内存使用

#### Phase 6: 完整系统测试

**回归测试**：
- [ ] 所有功能回归
- [ ] 边界条件回归
- [ ] 性能回归

---

## 📈 成功标准

### 后端标准

- ✅ 新表创建成功，结构正确
- ✅ API 端点全部可用
- ✅ 单元测试覆盖率 > 80%
- ✅ 集成测试全部通过
- ✅ 旧系统兼容，无破坏

### Flutter 标准

- ✅ 代码编译通过（0 个错误）
- ✅ 新模型完整且可用
- ✅ UI 页面流畅可用
- ✅ 功能测试全部通过
- ✅ E2E 测试全部通过

### 集成标准

- ✅ 前后端通信正常
- ✅ 数据流通畅
- ✅ 用户流程完整
- ✅ 多设备支持正常
- ✅ 系统稳定可靠

---

## 🔐 安全检查清单

### 后端安全

- [ ] 输入验证（防 SQL 注入）
- [ ] 输出编码（防 XSS）
- [ ] 认证验证（确认用户身份）
- [ ] 授权检查（确认用户权限）
- [ ] HTTPS 强制
- [ ] CORS 配置正确

### Flutter 安全

- [ ] SecureStorage 正确使用
- [ ] Cookie 不打印到日志
- [ ] 敏感信息加密传输
- [ ] 请求签名或验证
- [ ] 本地缓存加密

---

## 📋 关键文件清单

### 后端文件（Node.js）

**新增**：
- `routes/bilibili.js` - B站认证路由
- `controllers/bilibiliController.js` - B站业务逻辑
- `models/BilibiliBinding.js` - 绑定模型
- `tests/bilibili.test.js` - 单元测试
- `migrations/001_create_bilibili_tables.sql` - 数据库迁移

**修改**：
- `index.js` - 添加新路由
- `routes/favorites.js` - 支持新的 bilibili_uid

### Flutter 文件

**新增**：
- `lib/models/bilibili_user.dart` - B站用户模型
- `lib/models/device_binding.dart` - 设备绑定模型
- `lib/services/bilibili_auth_service.dart` - 认证服务
- `lib/ui/pages/bilibili_binding_page.dart` - 绑定页面
- `lib/providers/bilibili_auth_provider.dart` - 状态管理
- `test/bilibili_auth_service_test.dart` - 单元测试
- `test/bilibili_binding_page_test.dart` - Widget 测试

**删除**：
- `lib/ui/pages/login_page.dart`
- `lib/ui/pages/register_page.dart`
- `lib/ui/pages/reset_password_page.dart`
- `lib/models/user_model.dart`（旧的）
- `lib/models/platform_account.dart`
- `lib/models/bilibili_account.dart`
- `lib/models/platform_binding_model.dart`

**修改**：
- `lib/routes/router.dart` - 更新路由
- `lib/main.dart` - 更新启动逻辑
- `lib/services/secure_storage_service.dart` - 仅存 Cookie
- `lib/ui/pages/search_page.dart` - 集成新认证
- `lib/ui/pages/settings_page.dart` - 添加设备管理

---

## 📝 文档结构

```
docs/
├─ 00_ORIGINAL_ARCHITECTURE.md      (原架构说明，用于参考)
├─ 01_BILIBILI_ONLY_ARCHITECTURE.md (本文件，新架构设计)
├─ 02_DATABASE_MIGRATION.md         (数据库迁移指南)
├─ 03_API_SPECIFICATION.md          (API 详细规范)
├─ 04_TESTING_GUIDE.md              (测试指南)
├─ 05_DEPLOYMENT_GUIDE.md           (部署指南)
└─ 06_USER_DOCUMENTATION.md         (用户文档)
```

---

## ⏱️ 时间估算

| Phase | 任务 | 预计天数 |
|-------|------|---------|
| **1** | 后端表 + API + 测试 | 2 天 |
| **2** | Bilibili 认证 + 测试 | 2-3 天 |
| **3** | 数据模型简化 + 测试 | 1-2 天 |
| **4** | UI 改造 + E2E 测试 | 2-3 天 |
| **5** | 功能集成 + 系统测试 | 2-3 天 |
| **6** | 优化 + 文档 + 发布 | 1-2 天 |
| **总计** | | **10-16 天** |

**相比原计划的 16-23 天，节省 7 天（30%）**

---

## 🎯 里程碑

- **Week 1**: Phase 1-2 完成，后端可用
- **Week 2**: Phase 3-4 完成，UI 可用
- **Week 3**: Phase 5-6 完成，系统就绪
- **发布**: 新系统上线

---

## 📞 沟通计划

### 每日更新
- 09:00 - 晨会（进度同步）
- 17:00 - 下午总结（问题讨论）

### 周报
- 每周五下午 - 周报（总结和下周计划）

### 文档更新
- 每个 Phase 完成后更新对应文档

---

**版本**: 1.0
**日期**: 2026-01-03
**状态**: 待批准
**下一步**: 确认方案后启动 Phase 1
