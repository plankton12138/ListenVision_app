"""播放历史数据访问层"""
from datetime import datetime
from typing import Optional, List, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, and_

from app.models.play_history import PlayHistory


class HistoryRepository:
    """播放历史数据访问层"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(
        self,
        user_id: int,
        bvid: str,
        title: Optional[str] = None,
        artist: Optional[str] = None,
        cover_url: Optional[str] = None,
        duration: int = 0,
        progress: int = 0
    ) -> PlayHistory:
        """创建播放历史记录"""
        history = PlayHistory(
            user_id=user_id,
            bvid=bvid,
            title=title,
            artist=artist,
            cover_url=cover_url,
            duration=duration,
            progress=progress
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(history)
        return history

    async def get_by_id(self, history_id: int) -> Optional[PlayHistory]:
        """根据ID获取播放历史"""
        result = await self.db.execute(
            select(PlayHistory).where(PlayHistory.id == history_id)
        )
        return result.scalar_one_or_none()

    async def get_by_user_and_bvid(
        self,
        user_id: int,
        bvid: str
    ) -> Optional[PlayHistory]:
        """根据用户ID和BVID获取播放历史"""
        result = await self.db.execute(
            select(PlayHistory).where(
                and_(
                    PlayHistory.user_id == user_id,
                    PlayHistory.bvid == bvid
                )
            )
        )
        return result.scalar_one_or_none()

    async def get_by_user(
        self,
        user_id: int,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[PlayHistory], int]:
        """获取用户的播放历史（分页）"""
        # 计算总数
        count_result = await self.db.execute(
            select(func.count(PlayHistory.id)).where(
                PlayHistory.user_id == user_id
            )
        )
        total = count_result.scalar() or 0

        # 分页查询
        offset = (page - 1) * page_size
        result = await self.db.execute(
            select(PlayHistory)
            .where(PlayHistory.user_id == user_id)
            .order_by(desc(PlayHistory.last_played_at))
            .offset(offset)
            .limit(page_size)
        )
        items = result.scalars().all()

        return items, total

    async def update(
        self,
        history_id: int,
        **kwargs
    ) -> Optional[PlayHistory]:
        """更新播放历史"""
        history = await self.get_by_id(history_id)
        if not history:
            return None

        for key, value in kwargs.items():
            if hasattr(history, key):
                setattr(history, key, value)

        await self.db.commit()
        await self.db.refresh(history)
        return history

    async def update_play_info(
        self,
        history_id: int,
        progress: int
    ) -> Optional[PlayHistory]:
        """更新播放信息（增加播放次数，更新进度和时间）"""
        history = await self.get_by_id(history_id)
        if not history:
            return None

        history.play_count += 1
        history.progress = progress
        history.last_played_at = datetime.utcnow()

        await self.db.commit()
        await self.db.refresh(history)
        return history

    async def delete(self, history_id: int) -> bool:
        """删除播放历史"""
        history = await self.get_by_id(history_id)
        if not history:
            return False

        await self.db.delete(history)
        await self.db.commit()
        return True

    async def delete_by_user(self, user_id: int) -> int:
        """删除用户的所有播放历史"""
        result = await self.db.execute(
            select(PlayHistory).where(PlayHistory.user_id == user_id)
        )
        histories = result.scalars().all()

        count = 0
        for history in histories:
            await self.db.delete(history)
            count += 1

        await self.db.commit()
        return count