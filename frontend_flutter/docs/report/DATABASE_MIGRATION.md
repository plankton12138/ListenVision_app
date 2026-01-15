# 数据库迁移指南

## 📋 概述

本文档描述如何为纯 Bilibili 认证系统创建新的数据库表。

**关键原则**：
- ✅ 保留现有数据库表（users, favorites）
- ✅ 创建新的独立表（bilibili_*）
- ✅ 支持平滑过渡（新旧系统并存）

---

## 🔄 迁移步骤

### Step 1: 创建新表

```sql
-- 创建数据库（如果需要）
CREATE DATABASE IF NOT EXISTS listenvision_v2;

-- ============ B站绑定主表 ============
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

-- ============ 设备绑定表 ============
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

-- ============ 操作日志表 ============
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

-- ============ Cookie 管理表（可选）============
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

### Step 2: 修改现有表

```sql
-- 向 favorites 表添加新字段（保持向后兼容）
ALTER TABLE favorites
ADD COLUMN bilibili_uid BIGINT DEFAULT NULL COMMENT 'B站用户ID',
ADD FOREIGN KEY (bilibili_uid) REFERENCES bilibili_bindings(bilibili_uid)
  ON DELETE SET NULL;

-- 创建索引便于查询
CREATE INDEX idx_favorites_bilibili_uid ON favorites(bilibili_uid);
```

### Step 3: 验证表创建

```sql
-- 检查表是否创建成功
SHOW TABLES;

-- 检查每个表的结构
DESCRIBE bilibili_bindings;
DESCRIBE device_bindings;
DESCRIBE bilibili_operations_log;
DESCRIBE bilibili_cookies;

-- 检查 favorites 修改
DESCRIBE favorites;

-- 检查外键
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME IN ('device_bindings', 'bilibili_cookies', 'favorites');
```

---

## 🚨 回滚方案

如果需要回滚迁移：

```sql
-- ❌ 仅在确实需要时执行

-- 删除新表（注意顺序，先删有外键的）
DROP TABLE IF EXISTS bilibili_cookies;
DROP TABLE IF EXISTS bilibili_operations_log;
DROP TABLE IF EXISTS device_bindings;
DROP TABLE IF EXISTS bilibili_bindings;

-- 恢复 favorites 表
ALTER TABLE favorites DROP FOREIGN KEY favorites_ibfk_new;
ALTER TABLE favorites DROP COLUMN bilibili_uid;
```

---

## 📊 数据迁移策略（Phase 6 后期）

### 可选：将旧收藏迁移到新系统

```sql
-- 仅在完全确认废弃旧系统时执行

-- 1. 检查旧数据
SELECT COUNT(*) FROM favorites WHERE bilibili_uid IS NULL AND username IS NOT NULL;

-- 2. 对于有对应 B站账号的旧收藏，关联到新系统
UPDATE favorites f
SET f.bilibili_uid = (
  SELECT b.bilibili_uid
  FROM bilibili_bindings b
  WHERE b.bilibili_username = f.username
)
WHERE f.bilibili_uid IS NULL
  AND EXISTS (
    SELECT 1 FROM bilibili_bindings b
    WHERE b.bilibili_username = f.username
  );

-- 3. 检查迁移结果
SELECT COUNT(*) FROM favorites WHERE bilibili_uid IS NOT NULL;
```

---

## ✅ 验证清单

- [ ] 所有新表创建成功
- [ ] 表字段和类型正确
- [ ] 主键和唯一约束正确
- [ ] 外键关系正确
- [ ] 索引创建成功
- [ ] 旧表结构未被破坏
- [ ] 可以执行 CRUD 操作

---

**版本**: 1.0
**日期**: 2026-01-03
**执行人**: 待执行
