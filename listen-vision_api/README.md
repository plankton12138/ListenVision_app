# ListenVision API Server

> ListenVision 的 Node.js / Express 后端，提供认证、平台绑定、搜索、推荐、歌单、历史与同步接口。

## 技术栈

- Node.js 24.13.x
- Express 5
- better-sqlite3
- jsonwebtoken / bcryptjs
- winston
- swagger-ui-express

## 目录结构

```
listen-vision_api/
├── config/
│   ├── database.js           # better-sqlite3 初始化与表结构
│   ├── jwt.js                # JWT 配置
│   └── swagger.js            # Swagger 文档配置
├── controllers/              # 请求/响应适配
├── middleware/               # auth / logger / rate limiter / error handler
├── routes/                   # /api/v1 路由拆分
├── services/                 # 业务逻辑与数据库访问
├── tests/                    # Jest 测试
├── utils/                    # 日志与统一响应工具
├── .env.example
├── index.js
└── package.json
```

## 环境要求

- Node.js `>=24.13.0 <25.0.0`
- pnpm
- Windows 环境下构建 `better-sqlite3` 需要 C++ Build Tools

## 环境变量

复制模板：

```bash
cp .env.example .env
```

关键配置：

```env
JWT_SECRET=replace_me
JWT_EXPIRES_IN=7d
DATABASE_PATH=./data/listenvision.db
PORT=3000
NODE_ENV=development
```

- `DATABASE_PATH` 可选；未配置时默认使用 `listen-vision_api/data/listenvision.db`
- `JWT_SECRET` 为必填

## 常用命令

```bash
cd listen-vision_api
pnpm install
node index.js
pnpm test
pnpm test:coverage
```

## API 入口

- Health: `GET /health`
- Swagger: `GET /api-docs`
- Versioned API: `GET /api/v1/*`

主要业务域：

- `/api/v1/auth`
- `/api/v1/users`
- `/api/v1/playlists`
- `/api/v1/history`
- `/api/v1/search`
- `/api/v1/recommendations`
- `/api/v1/bilibili`
- `/api/v1/netease`
- `/api/v1/audio`
- `/api/v1/sync`

## 响应约定

标准 JSON 接口优先返回：

```json
{
  "success": true,
  "message": "操作成功",
  "data": {}
}
```

错误返回：

```json
{
  "success": false,
  "error": "错误信息"
}
```

说明：音频 / 图片代理等流式接口会直接写入 `res`，不使用统一 JSON 包装。

## 开发说明

- 控制器负责请求校验与响应适配
- 服务层承载核心业务逻辑
- 统一错误处理通过 `middleware/errorHandler.js`
- 日志统一通过 `utils/logger.js` 输出
- 当前后端不做音频格式转换，主要负责代理与元数据接口
