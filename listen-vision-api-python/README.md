# Listen Vision API - Python Backend

Python 后端服务，使用 FastAPI + SQLAlchemy 构建。

## 技术栈

- **FastAPI** - 现代 Web 框架
- **SQLAlchemy 2.0** - 异步 ORM
- **Pydantic v2** - 数据验证
- **bilibili-api-python** - B站 API 客户端
- **uv** - 快速包管理器

## 开发

```bash
# 安装依赖
uv sync

# 运行开发服务器
uv run uvicorn app.main:app --reload --port 3001

# 运行测试
uv run pytest

# 运行测试（覆盖率）
uv run pytest --cov=app
```

## 项目结构

```
listen-vision-api-python/
├── app/
│   ├── api/
│   │   ├── deps.py          # 依赖注入
│   │   └── routes/          # API 路由
│   ├── db/
│   │   ├── database.py      # 数据库配置
│   │   └── repositories/    # 数据访问层
│   ├── models/              # SQLAlchemy 模型
│   ├── schemas/             # Pydantic Schema
│   ├── services/            # 业务逻辑层
│   ├── utils/               # 工具函数
│   ├── config.py            # 配置管理
│   └── main.py              # FastAPI 入口
├── tests/                   # 测试
├── pyproject.toml           # 项目配置
└── .env.example             # 环境变量模板
```

## API 端点

### 认证
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/refresh` - 刷新令牌
- `GET /api/v1/auth/me` - 获取当前用户

### B站
- `GET /api/v1/bilibili/status` - 获取绑定状态
- `POST /api/v1/bilibili/qrcode` - 生成登录二维码
- `GET /api/v1/bilibili/qrcode/check` - 检查二维码状态
- `DELETE /api/v1/bilibili/unbind` - 解绑账号
- `GET /api/v1/bilibili/video/{bvid}` - 获取视频信息
- `GET /api/v1/bilibili/video/{bvid}/audio` - 获取音频流
- `GET /api/v1/bilibili/video/{bvid}/subtitle` - 获取字幕
- `GET /api/v1/bilibili/search` - 搜索视频
- `GET /api/v1/bilibili/recommend` - 获取推荐

### 歌单
- `POST /api/v1/playlists` - 创建歌单
- `GET /api/v1/playlists` - 获取歌单列表
- `GET /api/v1/playlists/{id}` - 获取歌单详情
- `PUT /api/v1/playlists/{id}` - 更新歌单
- `DELETE /api/v1/playlists/{id}` - 删除歌单
- `POST /api/v1/playlists/{id}/items` - 添加歌曲
- `DELETE /api/v1/playlists/{id}/items/{bvid}` - 移除歌曲