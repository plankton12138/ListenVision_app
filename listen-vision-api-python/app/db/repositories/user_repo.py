from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User


class UserRepository:
    """用户数据访问层"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, email: str, hashed_password: str, username: Optional[str] = None) -> User:
        """创建用户"""
        user = User(
            email=email,
            hashed_password=hashed_password,
            username=username
        )
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def get_by_id(self, user_id: int) -> Optional[User]:
        """根据ID获取用户"""
        result = await self.db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        """根据邮箱获取用户"""
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def exists_by_email(self, email: str) -> bool:
        """检查邮箱是否已存在"""
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none() is not None

    async def update_password(self, user_id: int, hashed_password: str) -> None:
        """更新用户密码"""
        user = await self.get_by_id(user_id)
        if user:
            user.hashed_password = hashed_password
            await self.db.commit()

    async def delete(self, user_id: int) -> None:
        """删除用户"""
        user = await self.get_by_id(user_id)
        if user:
            await self.db.delete(user)
            await self.db.commit()
