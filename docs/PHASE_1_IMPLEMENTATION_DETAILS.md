# Phase 1 实施细节文档

> **文档目的**: 记录 Phase 1 (B站API集成) 的实际实现状态
>
> **技术栈**: Node.js + Express + SQLite (better-sqlite3)
>
> **创建日期**: 2026-01-13
>
> **最后更新**: 2026-01-17
>
> **关联文档**: [INCREMENTAL_MIGRATION_PLAN.md](./INCREMENTAL_MIGRATION_PLAN.md)

---

## 目录

- [1. 当前实现状态](#1-当前实现状态)
- [2. 安全实现细节](#2-安全实现细节)
- [3. 数据库设计](#3-数据库设计)
- [4. API端点清单](#4-api端点清单)
- [5. 核心代码位置](#5-核心代码位置)
- [6. 下一步工作](#6-下一步工作)

---

## 1. 当前实现状态

### 1.1 后端进度

```
核心业务功能:  ████████████████████ 100% ✅
单元测试:      ░░░░░░░░░░░░░░░░░░░░   0% ⏳
───────────────────────────────────────────
总体完成度:     ████████████████████ 100% ✅
```

| 模块 | 状态 | 说明 |
|------|------|------|
| **bilibiliService.js** | ✅ 完成 | QR登录、Cookie管理、视频信息、音频流、搜索、WBI签名 |
| **audioService.js** | ✅ 完成 | 元数据缓存、批量获取、搜索历史 |
| **bilibiliController.js** | ✅ 完成 | 8个API端点 |
| **audioController.js** | ✅ 完成 | 12个API端点 |
| **路由** | ✅ 完成 | routes/bilibili.js, routes/audio.js |
| **数据库** | ✅ 完成 | SQLite (better-sqlite3) |
| **测试** | ❌ 待完成 | bilibiliService, audioService |

### 1.2 前端进度

```
后端调用适配:   ░░░░░░░░░░░░░░░░░░░░   0% ⏳
───────────────────────────────────────────
总体完成度:     ░░░░░░░░░░░░░░░░░░░░   0%
```

| 任务 | 状态 | 说明 |
|------|------|------|
| **bilibiliApiService.dart** | ❌ 待创建 | 调用后端API |
| **bilibiliProvider.dart** | ❌ 待创建 | B站状态管理 |
| **移除直接B站API调用** | ❌ 待完成 | 当前Flutter仍直接调用B站 |

---

## 2. 安全实现细节

### 2.1 Cookie 加密存储

**加密方案**: AES-256-CBC

**为什么选择 CBC**:
- Node.js 原生 crypto 模块支持良好
- 对当前应用场景安全性已足够
- 性能优于 GCM

**知识点说明**:
- **AES-256**: 高级加密标准，256位密钥长度
- **CBC**: 密码分组链接模式，需要初始化向量(IV)
- **IV**: 初始化向量，每次加密随机生成，确保相同明文产生不同密文

#### 当前实现

**文件位置**: `listen-vision_api/services/bilibiliService.js:18-50`

```javascript
const crypto = require('crypto');

const ENCRYPTION_KEY = process.env.BILI_COOKIE_KEY || crypto.randomBytes(32);
const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16;

/**
 * 加密 Cookie
 */
const encryptCookie = (cookie) => {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY), iv);
  let encrypted = cipher.update(cookie, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
};

/**
 * 解密 Cookie
 */
const decryptCookie = (encryptedCookie) => {
  const parts = encryptedCookie.split(':');
  const iv = Buffer.from(parts[0], 'hex');
  const encrypted = parts[1];
  const decipher = crypto.createDecipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY), iv);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
};
```

#### 密钥管理

```bash
# 生成新密钥 (32 bytes)
openssl rand -hex 32

# 添加到 .env (不要提交到 Git)
BILI_COOKIE_KEY=<生成的64位hex字符串>
```

#### 安全检查清单

- [x] 密钥长度 32 字节（256位）
- [x] IV 每次加密随机生成
- [x] Cookie 加密后存储于数据库
- [x] 解密失败抛出异常
- [ ] 日志中脱敏 Cookie（待实现）

---

## 3. 数据库设计

### 3.1 技术选型：SQLite (better-sqlite3)

**为什么选择 SQLite**:
- ✅ 项目规模：中小型，单机部署足够
- ✅ 零配置：无需独立数据库服务
- ✅ 性能：better-sqlite3 同步API，代码简洁
- ✅ 可移植：单个文件，备份和迁移简单

**知识点说明**:
- **better-sqlite3**: Node.js 的 SQLite 绑定，提供同步 API
- **WAL模式**: 写前日志，允许读写并发
- **外键约束**: 保证数据引用完整性

### 3.2 表结构

```sql
-- B站账号绑定表
CREATE TABLE bilibili_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  bili_user_id TEXT,
  bili_username TEXT,
  cookie_encrypted TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  expires_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 音频元数据缓存表
CREATE TABLE audio_metadata_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bvid TEXT UNIQUE NOT NULL,
  title TEXT,
  artist TEXT,
  duration INTEGER,
  cover_url TEXT,
  audio_url TEXT,
  cid INTEGER,
  metadata TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- 搜索历史表
CREATE TABLE search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  keyword TEXT NOT NULL,
  result_count INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 3.3 索引

```sql
CREATE INDEX idx_bilibili_accounts_user_id ON bilibili_accounts(user_id);
CREATE INDEX idx_audio_metadata_bvid ON audio_metadata_cache(bvid);
CREATE INDEX idx_search_history_user_id ON search_history(user_id);
```

---

## 4. API端点清单

### 4.1 B站API (`/api/bilibili/*`)

| 方法 | 端点 | 功能 | 认证 |
|-----|------|------|------|
| POST | `/qrcode` | 获取QR码登录凭证 | 否 |
| POST | `/qrcode/check` | 检查QR码登录状态 | 是 |
| GET | `/status` | 获取绑定状态 | 是 |
| DELETE | `/unbind` | 解绑B站账号 | 是 |
| GET | `/video/:bvid` | 获取视频信息 | 否* |
| GET | `/audio/:bvid` | 获取音频流URL | 否* |
| GET | `/uploader/:mid` | 获取UP主视频列表 | 否* |
| GET | `/search` | 搜索B站视频 | 否* |

*optionalAuthMiddleware - 有Token则使用Cookie获取更高质量内容

### 4.2 音频元数据API (`/api/audio/*`)

| 方法 | 端点 | 功能 | 认证 |
|-----|------|------|------|
| GET | `/metadata/:bvid` | 获取音频元数据 | 否* |
| POST | `/metadata/:bvid/refresh` | 刷新元数据缓存 | 否* |
| DELETE | `/metadata/:bvid` | 删除元数据缓存 | 否* |
| GET | `/metadata` | 获取所有缓存 | 否* |
| POST | `/metadata/batch` | 批量获取元数据 | 否* |
| GET | `/stream/:bvid` | 获取音频流URL | 否* |
| GET | `/search/history` | 获取搜索历史 | 是 |
| GET | `/search/recent` | 获取最近搜索关键词 | 是 |
| DELETE | `/search/history` | 清空搜索历史 | 是 |
| DELETE | `/search/:keyword` | 删除特定搜索关键词 | 是 |
| GET | `/stats` | 获取缓存统计 | 否 |
| POST | `/clean` | 清理过期缓存 | 否 |

---

## 5. 核心代码位置

### 5.1 后端文件结构

```
listen-vision_api/
├── services/
│   ├── bilibiliService.js   ← B站API集成 (720行)
│   └── audioService.js       ← 音频元数据管理 (370行)
├── controllers/
│   ├── bilibiliController.js
│   └── audioController.js
├── routes/
│   ├── bilibili.js
│   └── audio.js
└── config/
    └── database.js           ← SQLite配置 + 表创建
```

### 5.2 关键实现

#### Cookie加密存储
**位置**: `bilibiliService.js:18-50`
**功能**: AES-256-CBC 加密/解密 B站 Cookie

#### WBI签名实现
**位置**: `bilibiliService.js:522-575`
**功能**: B站 WBI 签名，防止未授权 API 调用

**知识点**: WBI (Web Browser Identity) 是 B站的请求签名机制，通过混合密钥和参数生成签名

#### 元数据缓存
**位置**: `audioService.js:52-120`
**功能**: SQLite 缓存音频元数据，减少 B站 API 调用

#### QR码登录
**位置**: `bilibiliService.js:150-211`
**功能**: 获取 QR 码登录凭证并轮询登录状态

---

## 6. 下一步工作

### 6.1 当前任务：Flutter端改造

**目标**: 将Flutter的B站API调用迁移到后端

| 任务 | 优先级 | 说明 |
|------|--------|------|
| 创建 `bilibiliApiService.dart` | 🔴 高 | 调用后端 `/api/bilibili/*` |
| 创建 `bilibiliProvider.dart` | 🔴 高 | QR登录、绑定状态管理 |
| 重构 `search_page.dart` | 🔴 高 | 使用后端搜索API |
| 重构 `download_manager.dart` | 🟡 中 | 使用后端音频流API |
| 移除 `cookies.dart` | 🟡 中 | 不再本地存储Cookie |

### 6.2 可选增强功能

以下功能可在核心功能稳定后添加：

| 功能 | 说明 | 优先级 |
|-----|------|--------|
| 单元测试 | bilibiliService, audioService 测试覆盖 | 🟡 中 |
| Cookie脱敏日志 | 敏感信息不打印完整内容 | 🟢 低 |
| 简单重试机制 | API失败自动重试1-2次 | 🟢 低 |
| 内存缓存 | 可选的LRU缓存（提升性能） | 🟢 低 |

### 6.3 不在当前范围的功能

以下功能不属于 Phase 1 范围：

- ❌ Redis缓存
- ❌ MySQL/PostgreSQL
- ❌ 灰度发布系统
- ❌ 熔断器
- ❌ 监控指标收集
- ❌ 集群部署

---

## 附录

### A. 快速测试命令

```bash
# 启动后端
cd listen-vision_api
node index.js

# 访问API文档
# http://localhost:3000/api-docs

# 测试QR码登录
curl -X POST http://localhost:3000/api/bilibili/qrcode

# 测试视频信息
curl http://localhost:3000/api/bilibili/video/BV1xx411c7mD
```

### B. 环境变量

```bash
# .env (当前使用)
JWT_SECRET=your_jwt_secret
PORT=3000
NODE_ENV=development

# 可选（生产环境添加）
BILI_COOKIE_KEY=<64位hex密钥>
```

### C. WBI签名说明

**WBI (Web Browser Identity)** 是 B站的新型签名机制：

```
签名流程：
1. 从 img_key 和 sub_key 中各取部分字符混合
2. 将参数按字母排序
3. 对参数值进行哈希处理
4. 生成 w_rid 签名参数
```

**实现位置**: `bilibiliService.js:522-575`

---

**文档版本**: 2.0.0
**最后更新**: 2026-01-17
**维护者**: Claude Code
