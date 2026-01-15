# ListenVision API - 更新日志

## [v1.0.0] - 2026-01-12

### ✨ 新增功能

#### 📝 请求验证系统
- 使用 `express-validator` 实现完整的参数验证
- 验证规则包括：
  - 用户名：3-20 字符，仅字母数字下划线
  - 邮箱：标准邮箱格式验证
  - 密码：至少 6 位，必须包含字母和数字
  - URL：有效的 URL 格式
- 统一的错误响应格式

#### 🔒 请求限流保护
多级限流策略防止 API 滥用：
- **通用限流**：每小时 100 次请求
- **严格限流**：每小时 10 次请求（敏感操作）
- **登录限流**：每 15 分钟 5 次登录尝试
- **注册限流**：每天 3 次注册
- **验证码限流**：每 10 分钟 3 次请求

#### 📊 日志系统
基于 Winston 的完整日志系统：
- **日志级别**：error、warn、info、http、debug
- **日志文件**：
  - `logs/error.log` - 错误日志
  - `logs/combined.log` - 所有日志
  - `logs/http.log` - HTTP 请求日志（生产环境）
- **控制台输出**：开发环境彩色输出
- **日志轮转**：文件最大 5MB，保留 5-10 个文件

#### 📚 Swagger API 文档
自动生成的交互式 API 文档：
- **访问地址**：`http://localhost:3000/api-docs`
- **功能特性**：
  - 完整的 API 端点文档
  - 请求/响应示例
  - 在线测试功能
  - JWT Token 认证支持
  - 请求时长显示
  - API 分组浏览

#### 🛡️ 安全增强
- 统一错误处理中间件
- 优雅的服务器关闭
- 未捕获异常处理
- Promise 拒绝处理

### 🔧 改进

#### 代码质量
- 完整的分层架构（Routes → Controllers → Services → Database）
- 统一的响应格式
- Async/Await 错误捕获包装器
- 请求参数自动验证

#### 开发体验
- 健康检查端点：`GET /health`
- 实时 HTTP 请求日志
- 彩色控制台输出
- 详细的服务器启动信息

### 📦 新增依赖

```json
{
  "express-validator": "^7.x",
  "winston": "^3.x",
  "express-rate-limit": "^7.x",
  "swagger-ui-express": "^5.x",
  "swagger-jsdoc": "^6.x"
}
```

### 📁 新增文件

```
listen-vision_api/
├── utils/
│   └── logger.js          # Winston 日志系统
├── middleware/
│   ├── validator.js       # 请求验证中间件
│   └── rateLimiter.js     # 请求限流中间件
├── config/
│   └── swagger.js         # Swagger 配置
├── logs/                  # 日志目录（自动创建）
│   ├── error.log
│   ├── combined.log
│   └── http.log
├── API_ROUTES.md          # API 路由文档
└── CHANGELOG.md           # 更新日志
```

### 🎯 API 端点更新

所有端点现在都支持：
- ✅ 自动参数验证
- ✅ 请求限流保护
- ✅ HTTP 日志记录
- ✅ 统一错误处理
- ✅ Swagger 文档

### 🚀 使用说明

#### 启动服务器
```bash
cd listen-vision_api
node index.js
```

#### 访问 API 文档
在浏览器中打开：
```
http://localhost:3000/api-docs
```

#### 查看日志
```bash
# 查看错误日志
cat logs/error.log

# 查看所有日志
cat logs/combined.log

# 实时监控日志
tail -f logs/combined.log
```

### 📊 性能优化

- 连接池优化：启用 Keep-Alive
- 日志文件轮转：防止单个文件过大
- 限流保护：防止资源耗尽
- 优雅退出：安全关闭连接

### ⚠️ 重要提示

1. **生产环境配置**：
   - 修改 `.env` 中的 `JWT_SECRET`
   - 设置 `NODE_ENV=production`
   - 配置合适的限流参数

2. **日志管理**：
   - 定期清理旧日志
   - 考虑使用日志收集系统（如 ELK）

3. **限流调整**：
   - 根据实际负载调整限流参数
   - 考虑使用 Redis 实现分布式限流

### 🐛 已知问题

- 依赖包有一些 deprecated 警告（不影响使用）
- bcrypt 兼容性问题（已切换到 bcryptjs）

### 🔜 下一步计划

- [ ] 添加单元测试（Jest）
- [ ] API 性能监控
- [ ] Redis 缓存集成
- [ ] 文件上传功能
- [ ] WebSocket 支持
- [ ] Docker 容器化

---

## 快速开始

### 1. 安装依赖
```bash
npm install
```

### 2. 配置环境变量
```bash
cp .env.example .env
# 编辑 .env 文件，配置数据库和其他信息
```

### 3. 启动服务器
```bash
node index.js
```

### 4. 测试 API
```bash
# 健康检查
curl http://localhost:3000/health

# 注册用户
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"test123"}'

# 访问 API 文档
# http://localhost:3000/api-docs
```

---

**技术栈**：Node.js + Express + MySQL + JWT + Winston + Swagger

**许可证**：ISC
