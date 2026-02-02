# ListenVision API Server

> ListenVision 应用的后端 API 服务 - 基于 Node.js + Express + better-sqlite3 构建的 RESTful API (v1)

## 项目概述

ListenVision API 是一个为音频流媒体应用设计的后端服务，采用分层架构设计，提供用户认证、数据管理和 API 文档功能。

**当前版本**: v1.0.0
**API 前缀**: `/api/v1`

### 开发进度

| 模块 | 状态 | 说明 |
|------|------|------|
| 基础框架 | ✅ 完成 | Express + 中间件 + 日志系统 |
| 用户认证系统 | ✅ 完成 | 注册、登录、JWT、密码重置 |
| 歌单管理 | ✅ 完成 | 创建、更新、删除、排序 |
| 收藏管理 | ✅ 完成 | 添加、查询、删除收藏 |
| B站 API 集成 | ✅ 完成 | 视频信息、音频流获取 |
| 音频服务 | ✅ 完成 | 元数据缓存、格式转换 |
| 搜索功能 | ✅ 完成 | 视频/音频搜索、搜索历史 |
| API 文档 | ✅ 完成 | Swagger UI 集成 |

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
| 音频处理 | fluent-ffmpeg | 2.1.3 | 音频格式转换 |

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
│   ├── logger.js             # HTTP 请求日志
│   ├── rateLimiter.js        # 请求限流策略
│   └── validator.js          # 请求验证中间件
│
├── routes/                    # 路由定义
│   ├── v1.js                 # v1 API 路由统一入口
│   ├── auth.js               # 认证相关路由
│   ├── users.js              # 用户管理路由
│   ├── playlists.js          # 歌单管理路由
│   ├── bilibili.js           # B站 API 代理路由
│   ├── audio.js              # 音频服务路由
│   ├── search.js             # 搜索功能路由
│   ├── history.js            # 播放历史路由
│   └── recommendations.js    # 推荐功能路由
│
├── controllers/               # 控制器（业务逻辑入口）
│   ├── authController.js     # 认证控制器
│   ├── userController.js     # 用户控制器
│   ├── playlistController.js # 歌单控制器
│   ├── bilibiliController.js # B站 API 控制器
│   ├── audioController.js    # 音频服务控制器
│   └── ...
│
├── services/                  # 服务层（核心业务逻辑）
│   ├── audio/                # 音频服务模块
│   │   ├── index.js          # 统一入口
│   │   ├── conversionService.js    # 音频转换
│   │   ├── metadataService.js      # 元数据缓存
│   │   └── searchHistoryService.js # 搜索历史
│   ├── userService.js        # 用户服务
│   ├── emailService.js       # 邮件服务
│   ├── playlistService.js    # 歌单服务
│   ├── bilibiliService.js    # B站 API 服务
│   └── searchService.js      # 搜索服务
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
│  /api/v1/auth/* → auth.js                                       │
│  /api/v1/users/* → users.js                                     │
│  /api/v1/playlists/* → playlists.js                             │
│  /api/v1/bilibili/* → bilibili.js                               │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Controller Layer (控制器层) - 请求/响应处理                    │
│  • 参数提取                                                    │
│  • 调用 Service                                                │
│  • 格式化响应                                                   │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Service Layer (服务层) - 核心业务逻辑                          │
│  • 业务规则处理                                                 │
│  • 数据库操作 (better-sqlite3 预编译语句)                       │
│  • 外部服务调用 (B站 API 等)                                    │
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
| **路由** | `routes/` | 端点定义、HTTP 方法绑定 | RESTful 风格、v1 版本前缀 |
| **控制器** | `controllers/` | 请求/响应适配 | 参数解析、响应格式化 |
| **服务** | `services/` | 核心业务逻辑 | 可复用、与协议无关 |
| **工具** | `utils/` | 通用函数 | 日志、响应格式 |
| **配置** | `config/` | 基础设施配置 | 数据库、JWT、Swagger |

### 设计原则

1. **单一职责**：每层只处理自己的关注点
2. **依赖向下**：上层依赖下层，下层不感知上层
3. **预编译语句**：服务层使用 `db.prepare()` 提高性能
4. **同步优先**：better-sqlite3 同步 API，代码更简洁
5. **版本控制**：API 使用 `/api/v1` 前缀，便于未来扩展

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

---

## 快速开始

### 环境要求

- **Node.js** = 24.13.0（固定版本，重要！）
- **pnpm**
- **FFmpeg** - 用于音频格式转换
- **构建工具**：Windows 需要 Visual Studio Build Tools

> ⚠️ **重要提示**：本项目使用 `better-sqlite3` 和 `fluent-ffmpeg` 原生模块，必须在目标服务器上重新编译。不同 Node.js 版本的二进制文件不兼容。

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
========================================
  ListenVision API Server
========================================
  Status: Running
  Port: 3000
  Env: development
  Time: 2026/2/2 12:00:00
========================================
  API Docs: http://localhost:3000/api-docs
  Health: http://localhost:3000/health
========================================
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

### 核心 API 端点 (v1)

| 端点 | 方法 | 描述 | 认证 |
|------|------|------|------|
| `/health` | GET | 健康检查 | 否 |
| `/api/v1/auth/register` | POST | 用户注册 | 否 |
| `/api/v1/auth/login` | POST | 用户登录 | 否 |
| `/api/v1/auth/me` | GET | 获取用户信息 | 是 |
| `/api/v1/auth/send-code` | POST | 发送重置验证码 | 否 |
| `/api/v1/auth/reset-pwd` | POST | 重置密码 | 否 |
| `/api/v1/playlists` | GET | 获取歌单列表 | 是 |
| `/api/v1/playlists` | POST | 创建歌单 | 是 |
| `/api/v1/playlists/:id` | GET | 获取歌单详情 | 是 |
| `/api/v1/playlists/:id` | PUT | 更新歌单 | 是 |
| `/api/v1/playlists/:id` | DELETE | 删除歌单 | 是 |
| `/api/v1/bilibili/video/:bvid` | GET | 获取视频信息 | 否 |
| `/api/v1/bilibili/audio/:bvid` | GET | 获取音频流 | 否 |
| `/api/v1/search` | GET | 搜索视频 | 否 |
| `/api/v1/search/history` | GET | 获取搜索历史 | 是 |

### 请求示例

```bash
# 用户注册
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "email": "test@example.com", "password": "test123"}'

# 用户登录
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "test123"}'

# 获取用户信息（需要 Token）
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 创建歌单
curl -X POST http://localhost:3000/api/v1/playlists \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"name": "我的歌单", "description": "测试歌单"}'

# 获取视频信息
curl http://localhost:3000/api/v1/bilibili/video/BV1xx411c7mD

# 搜索视频
curl "http://localhost:3000/api/v1/search?keyword=周杰伦"
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
| 登录限流 | 每 15 分钟 5 次 | `/api/v1/auth/login` |
| 注册限流 | 每天 3 次 | `/api/v1/auth/register` |
| 验证码限流 | 每 10 分钟 3 次 | `/api/v1/auth/send-code` |

---

## 开发规范

### 代码规范

- 使用 ESLint 进行代码检查
- 遵循 Airbnb JavaScript 风格指南
- 所有函数必须包含 JSDoc 注释

### Git 提交规范

```
<type>: <subject>

<body>

<footer>
```

Type 类型：
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

### API 版本控制

- 当前版本：v1
- 版本前缀：`/api/v1`
- 所有新功能在 v1 中开发
- 未来版本通过 `/api/v2` 等路径扩展

---

## 部署指南

### 生产环境配置

```env
NODE_ENV=production
PORT=3000
JWT_SECRET=your_production_secret_key
JWT_EXPIRES_IN=7d
```

### 使用 PM2 部署

```bash
# 安装 PM2
npm install -g pm2

# 启动应用
pm2 start index.js --name listenvision-api

# 查看状态
pm2 status

# 查看日志
pm2 logs listenvision-api
```

---

## 许可证

MIT License - 详见 [LICENSE](../LICENSE) 文件

---

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

## 联系方式

- 项目主页：[https://github.com/yourusername/listenvision](https://github.com/yourusername/listenvision)
- 问题反馈：[Issues](https://github.com/yourusername/listenvision/issues)
- 邮箱：support@listenvision.com
