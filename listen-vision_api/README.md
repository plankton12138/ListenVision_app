# ListenVision API Server

> ListenVision 应用的后端 API 服务 - 基于 Node.js + Express + better-sqlite3 构建的 RESTful API

## 项目概述

ListenVision API 是一个为音频流媒体应用设计的后端服务，采用分层架构设计，提供用户认证、数据管理和 API 文档功能。

**当前开发阶段**：基础框架完成，核心业务功能（B站API集成）待开发

### 开发进度

| 模块 | 状态 | 说明 |
|------|------|------|
| 基础框架 | ✅ 完成 | Express + 中间件 + 日志系统 |
| 用户认证系统 | ✅ 完成 | 注册、登录、JWT、密码重置 |
| 收藏管理 | ✅ 完成 | 添加、查询、删除收藏 |
| API 文档 | ✅ 完成 | Swagger UI 集成 |
| B站 API 集成 | ❌ 未开发 | QR码登录、视频信息获取 |
| 音频服务 | ❌ 未开发 | 元数据缓存、流式传输 |
| 搜索功能 | ❌ 未开发 | 视频/音频搜索 |

---

## 技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 运行环境 | Node.js | 24.13.0 | JavaScript 运行时 (固定版本) |
| Web 框架 | Express | 5.1.0 | HTTP 服务器框架 |
| 数据库 | SQLite | 3.x | 嵌入式关系型数据库 |
| 数据库驱动 | better-sqlite3 | 12.6.0 | 同步 API、高性能 |
| 认证 | JWT | 9.0.3 | JSON Web Token 身份验证 |
| 密码加密 | bcryptjs | 3.0.2 | 密码哈希 |
| 参数验证 | express-validator | 7.3.1 | 请求参数验证 |
| 限流 | express-rate-limit | 8.2.1 | API 请求限流 |
| 日志 | Winston | 3.19.0 | 日志管理系统 |
| API 文档 | Swagger UI | 5.0.1 | 交互式 API 文档 |
| CORS | cors | 2.8.5 | 跨域资源共享 |
| 邮件 | nodemailer | 7.0.3 | 邮件发送服务 |

---

## 项目结构

```
listen-vision_api/
├── config/                    # 配置文件
│   ├── database.js           # better-sqlite3 数据库配置
│   ├── jwt.js                # JWT Token 生成和验证
│   └── swagger.js            # Swagger API 文档配置
│
├── middleware/                # 中间件
│   ├── auth.js               # JWT 认证中间件
│   ├── errorHandler.js       # 统一错误处理
│   ├── rateLimiter.js        # 请求限流策略
│   └── validator.js          # 请求验证中间件
│
├── routes/                    # 路由定义
│   ├── auth.js               # 认证相关路由
│   ├── users.js              # 用户管理路由
│   └── favorites.js          # 收藏管理路由
│
├── controllers/               # 控制器（业务逻辑入口）
│   ├── authController.js     # 认证控制器
│   ├── userController.js     # 用户控制器
│   └── favoriteController.js # 收藏控制器
│
├── services/                  # 服务层（核心业务逻辑）
│   ├── userService.js        # 用户服务
│   ├── emailService.js       # 邮件服务
│   └── favoriteService.js    # 收藏服务
│
├── utils/                     # 工具函数
│   ├── logger.js             # Winston 日志配置
│   └── response.js           # 统一响应格式
│
├── data/                      # 数据存储目录
│   └── listenvision.db       # SQLite 数据库文件
│
├── logs/                      # 日志文件目录
│   ├── error.log             # 错误日志
│   ├── combined.log          # 所有日志
│   └── http.log              # HTTP 请求日志
│
├── .env                       # 环境变量配置
├── .env.example               # 环境变量模板
├── index.js                   # 应用入口文件
└── package.json               # 项目依赖配置
```

---

## 架构设计

### 整体架构：MVC 分层设计

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Request                          │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Middleware Layer (中间件层)                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │   CORS   │ │   JSON   │ │   日志   │ │   限流   │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Router Layer (路由层) - 端点定义                               │
│  /api/auth/* → auth.js                                          │
│  /api/users/* → users.js                                        │
│  /api/favorites/* → favorites.js                                │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Controller Layer (控制器层) - 请求/响应处理                    │
│  • 参数验证                                                    │
│  • 调用 Service                                                │
│  • 格式化响应                                                   │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Service Layer (服务层) - 核心业务逻辑                          │
│  • 业务规则处理                                                 │
│  • 数据库操作 (better-sqlite3 预编译语句)                       │
│  • 外部服务调用 (邮件等)                                        │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Database Layer (数据层) - better-sqlite3                       │
│  • 同步 API 调用                                                │
│  • WAL 模式 + 外键约束                                          │
│  • 文件持久化                                                   │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Response                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 各层职责

| 层级 | 目录 | 职责 | 关键点 |
|------|------|------|--------|
| **入口** | `index.js` | 应用启动、中间件配置、路由注册 | Express 配置、优雅退出 |
| **中间件** | `middleware/` | 横切关注点处理 | 认证、限流、验证、错误处理 |
| **路由** | `routes/` | 端点定义、HTTP 方法绑定 | RESTful 风格 |
| **控制器** | `controllers/` | 请求/响应适配 | 参数解析、响应格式化 |
| **服务** | `services/` | 核心业务逻辑 | 可复用、与协议无关 |
| **工具** | `utils/` | 通用函数 | 日志、响应格式 |
| **配置** | `config/` | 基础设施配置 | 数据库、JWT、Swagger |

### 设计原则

1. **单一职责**：每层只处理自己的关注点
2. **依赖向下**：上层依赖下层，下层不感知上层
3. **预编译语句**：服务层使用 `db.prepare()` 提高性能
4. **同步优先**：better-sqlite3 同步 API，代码更简洁

---

### 数据层：better-sqlite3

**为什么选择 better-sqlite3？**

```
对比 sql.js 和 better-sqlite3：

┌─────────────────────┬──────────────────┬─────────────────────┐
│      sql.js         │ better-sqlite3   │                     │
├─────────────────────┼──────────────────┼─────────────────────┤
│ WebAssembly         │ 原生 C 绑定      │ 性能                │
│ 内存数据库           │ 文件数据库       │ 持久化              │
│ 手动持久化           │ 自动持久化       │ 便利性              │
│ ~100ms/1000 inserts  │ ~5ms/1000 inserts│ 性能差距 20x       │
│ 需适配器             │ 原生 API         │ 代码简洁度          │
└─────────────────────┴──────────────────┴─────────────────────┘
```

**better-sqlite3 特性**：
- **同步 API**：无需回调/Promise，代码简洁
- **高性能**：原生 C 绑定，性能接近纯 C
- **自动持久化**：数据实时写入磁盘
- **WAL 模式**：读写并发支持
- **事务支持**：完整的 ACID 事务

**代码示例**：
```javascript
// 预编译语句（推荐）
const getUser = db.prepare('SELECT * FROM users WHERE id = ?');
const user = getUser.get(userId);

// 事务
const insertMany = db.transaction((items) => {
  const stmt = db.prepare('INSERT INTO users (name) VALUES (?)');
  for (const item of items) stmt.run(item.name);
});
insertMany(allUsers);
```

### 数据表结构

```sql
-- 用户表
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  reset_code TEXT,
  code_expire TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

-- 收藏表
CREATE TABLE favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  url TEXT NOT NULL,
  title TEXT NOT NULL,
  username TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_favorites_username ON favorites(username);
CREATE INDEX idx_favorites_url ON favorites(url);
```

---

## 快速开始

### 环境要求

- **Node.js** = 24.13.0（固定版本，重要！）
- **pnpm**
- **构建工具**：Windows 需要 Visual Studio Build Tools

> ⚠️ **重要提示**：本项目使用 `better-sqlite3` 原生模块，必须在目标服务器上重新编译。不同 Node.js 版本的二进制文件不兼容。

### 1. 安装依赖

```bash
cd listen-vision_api
pnpm install
```

> **注意**：better-sqlite3 需要原生编译。Windows 用户请安装 [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/)，选择"使用 C++ 的桌面开发"工作负载。

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
# JWT 配置
JWT_SECRET=your_jwt_secret_key_here_change_it_in_production
JWT_EXPIRES_IN=7d

# 邮件服务配置（可选）
SMTP_HOST=smtp.qq.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=your_email@qq.com
SMTP_PASS=your_smtp_authorization_code

# 服务器配置
PORT=3000
NODE_ENV=development
```

### 3. 启动服务器

```bash
node index.js
```

启动成功后会看到：

```
PRAGMA foreign_keys = ON
PRAGMA journal_mode = WAL
PRAGMA synchronous = NORMAL
✅ 数据库表初始化完成

╔══════════════════════════════════════════════╗
║   ListenVision API Server                    ║
╠══════════════════════════════════════════════╣
║   Status: ✅ Running                          ║
║   Port: 3000                                ║
║   Env: development                           ║
║   Time: 2026/1/16 12:54:31                   ║
╠══════════════════════════════════════════════╣
║   API 文档: http://localhost:3000/api-docs    ║
║   健康检查: http://localhost:3000/health       ║
╚══════════════════════════════════════════════╝
```

### 4. 访问 API 文档

```
http://localhost:3000/api-docs
```

---

## API 使用指南

### 通用响应格式

**成功响应：**
```json
{
  "success": true,
  "message": "操作成功",
  "data": { ... }
}
```

**错误响应：**
```json
{
  "success": false,
  "error": "错误信息描述"
}
```

### 核心 API 端点

| 端点 | 方法 | 描述 | 认证 |
|------|------|------|------|
| `/health` | GET | 健康检查 | 否 |
| `/api/auth/register` | POST | 用户注册 | 否 |
| `/api/auth/login` | POST | 用户登录 | 否 |
| `/api/auth/me` | GET | 获取用户信息 | 是 |
| `/api/auth/send-code` | POST | 发送重置验证码 | 否 |
| `/api/auth/reset-pwd` | POST | 重置密码 | 否 |
| `/api/favorites` | GET | 获取收藏列表 | 否* |
| `/api/favorites` | POST | 添加收藏 | 是 |
| `/api/favorites/:id` | DELETE | 删除收藏 | 是 |

*未登录获取所有收藏，已登录只获取自己的

### 请求示例

```bash
# 用户注册
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "email": "test@example.com", "password": "test123"}'

# 用户登录
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "test123"}'

# 获取用户信息（需要 Token）
curl http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 添加收藏
curl -X POST http://localhost:3000/api/favorites \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"url": "https://example.com/audio.mp3", "title": "测试音频"}'
```

---

## 安全特性

### 1. 密码安全

- 使用 **bcryptjs** 进行密码哈希（10 轮加密）
- 密码长度要求：至少 6 位
- 数据库中不存储明文密码

### 2. JWT 认证

- Token 有效期：7 天（可配置）
- 请求头格式：`Authorization: Bearer <token>`

### 3. 请求限流

| 限流类型 | 限制 | 适用端点 |
|---------|------|---------|
| 通用限流 | 每小时 100 次 | 所有 API |
| 登录限流 | 每 15 分钟 5 次 | `/api/auth/login` |
| 注册限流 | 每天 3 次 | `/api/auth/register` |
| 验证码限流 | 每 10 分钟 3 次 | `/api/auth/send-code` |

### 4. 参数验证

- 用户名：3-20 个字符，仅字母数字下划线
- 邮箱：标准邮箱格式
- 密码：至少 6 位

---

## 日志系统

### 日志文件

| 文件 | 内容 |
|------|------|
| `logs/combined.log` | 所有日志 |
| `logs/error.log` | 错误日志 |
| `logs/http.log` | HTTP 请求日志（生产环境） |

---

## 待开发功能

### 高优先级

1. **B站 API 集成**
   - QR码登录
   - 视频信息获取
   - 音频流获取
   - Cookie 管理

2. **音频服务**
   - 音频元数据缓存
   - 音频流式传输
   - 音频搜索

3. **搜索功能**
   - 视频搜索
   - 音频搜索
   - 搜索历史

### 中优先级

4. **播放列表管理**
   - 创建/编辑/删除播放列表
   - 添加/移除音频

5. **下载任务管理**
   - 创建下载任务
   - 进度追踪

---

## 常见问题

### Q: better-sqlite3 安装失败？

**A**: 需要安装 C++ 构建工具：
- Windows: [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/)，选择"使用 C++ 的桌面开发"
- macOS: `xcode-select --install`
- Linux: `sudo apt-get install build-essential`

### Q: 数据库文件在哪里？

`data/listenvision.db` - SQLite 文件数据库

### Q: 如何重置数据库？

删除 `data/listenvision.db` 文件，重启服务器即可创建新数据库。

---

## 许可证

ISC License

---

**最后更新：** 2026-01-16
**文档版本：** 3.0.0
