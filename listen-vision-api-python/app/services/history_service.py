"""播放历史服务"""
from typing import List, Tuple
from fastapi import HTTPException, status

from app.db.repositories.history_repo import HistoryRepository
from app.schemas.history import (
    PlayHistoryCreate,
    PlayHistoryResponse,
    PlayHistoryListResponse
)
from app.utils.logger import logger


class HistoryService:
    """播放历史服务"""

    def __init__(self, db):
        self.db = db
        self.history_repo = HistoryRepository(db)

    async def add_history(
        self,
        user_id: int,
        data: PlayHistoryCreate
    ) -> PlayHistoryResponse:
        """添加播放历史

        如果已存在相同记录，则更新播放次数和时间
        """
        # 检查是否已存在
        existing = await self.history_repo.get_by_user_and_bvid(
            user_id, data.bvid
        )

        if existing:
            # 更新播放信息
            updated = await self.history_repo.update_play_info(
                existing.id,
                data.progress
            )
            logger.info(f"播放历史更新: user_id={user_id}, bvid={data.bvid}, play_count={updated.play_count}")
            return PlayHistoryResponse.model_validate(updated)

        # 创建新记录
        history = await self.history_repo.create(
            user_id=user_id,
            bvid=data.bvid,
            title=data.title,
            artist=data.artist,
            cover_url=data.cover_url,
            duration=data.duration,
            progress=data.progress
        )
        logger.info(f"播放历史创建: user_id={user_id}, bvid={data.bvid}")
        return PlayHistoryResponse.model_validate(history)

    async def get_history(
        self,
        user_id: int,
        page: int = 1,
        page_size: int = 20
    ) -> PlayHistoryListResponse:
        """获取播放历史列表"""
        items, total = await self.history_repo.get_by_user(
            user_id, page, page_size
        )

        return PlayHistoryListResponse(
            items=[PlayHistoryResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size
        )

    async def delete_history(self, user_id: int, history_id: int) -> bool:
        """删除单条播放历史"""
        history = await self.history_repo.get_by_id(history_id)

        if not history:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="记录不存在"
            )

        if history.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="无权删除此记录"
            )

        success = await self.history_repo.delete(history_id)
        if success:
            logger.info(f"播放历史删除: user_id={user_id}, history_id={history_id}")
        return success

    async def clear_history(self, user_id: int) -> int:
        """清空播放历史"""
        count = await self.history_repo.delete_by_user(user_id)
        logger.info(f"播放历史清空: user_id={user_id}, count={count}")
        return count