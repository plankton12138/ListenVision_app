"""音频元数据服务"""
from typing import List, Optional
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from app.models.audio_metadata import AudioMetadata, DownloadStatus
from app.schemas.audio import AudioMetadataCreate, AudioMetadataResponse, AudioMetadataUpdate
from app.utils.logger import logger


class AudioService:
    """音频元数据服务"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_metadata(self, user_id: int, bvid: str) -> Optional[AudioMetadataResponse]:
        """获取音频元数据"""
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == bvid
        )
        result = await self.db.execute(stmt)
        metadata = result.scalar_one_or_none()
        return AudioMetadataResponse.model_validate(metadata) if metadata else None

    async def create_or_update(
        self,
        user_id: int,
        data: AudioMetadataCreate
    ) -> AudioMetadataResponse:
        """创建或更新音频元数据"""
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == data.bvid
        )
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            # 更新现有记录
            for key, value in data.model_dump().items():
                if value is not None:
                    setattr(existing, key, value)
            existing.updated_at = datetime.utcnow()
            await self.db.commit()
            await self.db.refresh(existing)
            logger.info(f"更新音频元数据: user={user_id}, bvid={data.bvid}")
            return AudioMetadataResponse.model_validate(existing)

        # 创建新记录
        metadata = AudioMetadata(user_id=user_id, **data.model_dump())
        self.db.add(metadata)
        await self.db.commit()
        await self.db.refresh(metadata)
        logger.info(f"创建音频元数据: user={user_id}, bvid={data.bvid}")
        return AudioMetadataResponse.model_validate(metadata)

    async def update_metadata(
        self,
        user_id: int,
        bvid: str,
        data: AudioMetadataUpdate
    ) -> Optional[AudioMetadataResponse]:
        """更新音频元数据"""
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == bvid
        )
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if not existing:
            return None

        for key, value in data.model_dump(exclude_unset=True).items():
            if value is not None:
                if key == "download_status":
                    setattr(existing, key, DownloadStatus(value))
                else:
                    setattr(existing, key, value)

        existing.updated_at = datetime.utcnow()
        await self.db.commit()
        await self.db.refresh(existing)
        logger.info(f"更新音频元数据: user={user_id}, bvid={bvid}")
        return AudioMetadataResponse.model_validate(existing)

    async def delete_metadata(self, user_id: int, bvid: str) -> bool:
        """删除音频元数据"""
        stmt = delete(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == bvid
        )
        await self.db.execute(stmt)
        await self.db.commit()
        logger.info(f"删除音频元数据: user={user_id}, bvid={bvid}")
        return True

    async def list_by_user(
        self,
        user_id: int,
        status: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> List[AudioMetadataResponse]:
        """列出用户的音频元数据"""
        offset = (page - 1) * page_size
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id
        )

        if status:
            try:
                download_status = DownloadStatus(status)
                stmt = stmt.where(AudioMetadata.download_status == download_status)
            except ValueError:
                logger.warning(f"无效的下载状态: {status}")

        stmt = stmt.order_by(AudioMetadata.updated_at.desc()).offset(offset).limit(page_size)
        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [AudioMetadataResponse.model_validate(item) for item in items]

    async def get_by_status(
        self,
        user_id: int,
        status: DownloadStatus
    ) -> List[AudioMetadataResponse]:
        """获取指定状态的音频"""
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.download_status == status
        )
        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [AudioMetadataResponse.model_validate(item) for item in items]