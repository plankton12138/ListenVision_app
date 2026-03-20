from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import get_settings
from app.utils.logger import logger
from app.db.database import init_db
from app.api.routes import auth, bilibili, playlist

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时
    logger.info("Starting Listen Vision API...")
    await init_db()
    logger.info("Database initialized")

    yield

    # 关闭时
    logger.info("Shutting down Listen Vision API...")


app = FastAPI(
    title="Listen Vision API",
    description="音频应用后端 API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth.router, prefix="/api/v1")
app.include_router(bilibili.router, prefix="/api/v1")
app.include_router(playlist.router, prefix="/api/v1")


@app.get("/")
async def root():
    """健康检查"""
    return {"status": "ok", "message": "Listen Vision API is running"}


@app.get("/health")
async def health():
    """健康检查端点"""
    return {"status": "healthy"}