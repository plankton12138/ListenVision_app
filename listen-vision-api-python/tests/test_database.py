import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import engine, AsyncSessionLocal, init_db


@pytest.mark.asyncio
async def test_database_connection():
    """测试数据库连接"""
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT 1"))
        assert result.scalar() == 1


@pytest.mark.asyncio
async def test_session_creation():
    """测试会话创建"""
    async with AsyncSessionLocal() as session:
        assert isinstance(session, AsyncSession)
        assert session.is_active
