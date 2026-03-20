from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from app.models.platform_account import PlatformAccount, PlatformType


class PlatformAccountRepository:
    """平台账号数据访问层"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_bilibili(
        self,
        user_id: int,
        sessdata: str,
        bili_jct: str,
        dedeuserid: str,
        platform_username: Optional[str] = None
    ) -> PlatformAccount:
        """创建B站账号绑定"""
        # 先删除旧的绑定
        await self.delete_by_platform(user_id, PlatformType.BILIBILI)

        account = PlatformAccount(
            user_id=user_id,
            platform_type=PlatformType.BILIBILI,
            sessdata=sessdata,
            bili_jct=bili_jct,
            dedeuserid=dedeuserid,
            platform_username=platform_username
        )
        self.db.add(account)
        await self.db.commit()
        await self.db.refresh(account)
        return account

    async def get_by_user_and_platform(
        self,
        user_id: int,
        platform: PlatformType
    ) -> Optional[PlatformAccount]:
        """获取用户的平台账号"""
        result = await self.db.execute(
            select(PlatformAccount).where(
                and_(
                    PlatformAccount.user_id == user_id,
                    PlatformAccount.platform_type == platform,
                    PlatformAccount.is_active == True
                )
            )
        )
        return result.scalar_one_or_none()

    async def get_by_user(self, user_id: int) -> List[PlatformAccount]:
        """获取用户的所有平台账号"""
        result = await self.db.execute(
            select(PlatformAccount).where(
                and_(
                    PlatformAccount.user_id == user_id,
                    PlatformAccount.is_active == True
                )
            )
        )
        return result.scalars().all()

    async def delete_by_platform(self, user_id: int, platform: PlatformType) -> None:
        """删除用户的平台绑定"""
        account = await self.get_by_user_and_platform(user_id, platform)
        if account:
            account.is_active = False
            await self.db.commit()

    async def delete_by_user(self, user_id: int) -> None:
        """删除用户的所有平台账号"""
        accounts = await self.get_by_user(user_id)
        for account in accounts:
            account.is_active = False
        await self.db.commit()
