from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.db.repositories.playlist_repo import PlaylistRepository
from app.db.repositories.user_repo import UserRepository
from app.schemas.playlist import (
    PlaylistCreate, PlaylistUpdate, PlaylistResponse,
    PlaylistDetailResponse, PlaylistItem, PlaylistItemAddRequest
)
from app.utils.logger import logger


class PlaylistService:
    """歌单服务"""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.playlist_repo = PlaylistRepository(db)
        self.user_repo = UserRepository(db)

    async def create_playlist(
        self,
        user_id: int,
        data: PlaylistCreate
    ) -> PlaylistResponse:
        """创建歌单"""
        playlist = await self.playlist_repo.create(
            user_id=user_id,
            name=data.name,
            description=data.description,
            is_default=False
        )

        logger.info(f"歌单创建成功: user_id={user_id}, playlist_id={playlist.id}")
        return PlaylistResponse(
            id=playlist.id,
            user_id=playlist.user_id,
            name=playlist.name,
            description=playlist.description,
            cover_url=playlist.cover_url,
            is_default=playlist.is_default,
            is_public=playlist.is_public,
            created_at=playlist.created_at,
            updated_at=playlist.updated_at,
            item_count=0
        )

    async def get_user_playlists(self, user_id: int) -> List[PlaylistResponse]:
        """获取用户的所有歌单"""
        playlists = await self.playlist_repo.get_by_user(user_id)

        result = []
        for p in playlists:
            items = await self.playlist_repo.get_items(p.id)
            result.append(PlaylistResponse(
                id=p.id,
                user_id=p.user_id,
                name=p.name,
                description=p.description,
                cover_url=p.cover_url,
                is_default=p.is_default,
                is_public=p.is_public,
                created_at=p.created_at,
                updated_at=p.updated_at,
                item_count=len(items)
            ))

        return result

    async def get_playlist_detail(
        self,
        playlist_id: int,
        user_id: Optional[int] = None
    ) -> PlaylistDetailResponse:
        """获取歌单详情"""
        playlist = await self.playlist_repo.get_by_id(playlist_id)
        if not playlist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="歌单不存在"
            )

        # 检查权限
        if not playlist.is_public and playlist.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="无权访问此歌单"
            )

        items = await self.playlist_repo.get_items(playlist_id)
        playlist_items = [
            PlaylistItem(
                bvid=item["bvid"],
                title=item["title"],
                artist=item.get("artist"),
                cover_url=item.get("cover_url"),
                duration=item.get("duration", 0),
                added_at=item["added_at"]
            )
            for item in items
        ]

        return PlaylistDetailResponse(
            id=playlist.id,
            user_id=playlist.user_id,
            name=playlist.name,
            description=playlist.description,
            cover_url=playlist.cover_url,
            is_default=playlist.is_default,
            is_public=playlist.is_public,
            created_at=playlist.created_at,
            updated_at=playlist.updated_at,
            item_count=len(items),
            items=playlist_items
        )

    async def update_playlist(
        self,
        playlist_id: int,
        user_id: int,
        data: PlaylistUpdate
    ) -> PlaylistResponse:
        """更新歌单"""
        playlist = await self.playlist_repo.get_by_id(playlist_id)
        if not playlist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="歌单不存在"
            )

        if playlist.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="无权修改此歌单"
            )

        update_data = data.model_dump(exclude_unset=True)
        updated = await self.playlist_repo.update(playlist_id, **update_data)

        items = await self.playlist_repo.get_items(playlist_id)
        return PlaylistResponse(
            id=updated.id,
            user_id=updated.user_id,
            name=updated.name,
            description=updated.description,
            cover_url=updated.cover_url,
            is_default=updated.is_default,
            is_public=updated.is_public,
            created_at=updated.created_at,
            updated_at=updated.updated_at,
            item_count=len(items)
        )

    async def delete_playlist(self, playlist_id: int, user_id: int) -> bool:
        """删除歌单"""
        playlist = await self.playlist_repo.get_by_id(playlist_id)
        if not playlist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="歌单不存在"
            )

        if playlist.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="无权删除此歌单"
            )

        if playlist.is_default:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="无法删除默认歌单"
            )

        await self.playlist_repo.delete(playlist_id)
        logger.info(f"歌单删除成功: playlist_id={playlist_id}")
        return True

    async def add_item(
        self,
        playlist_id: int,
        user_id: int,
        data: PlaylistItemAddRequest
    ) -> bool:
        """添加歌单项"""
        playlist = await self.playlist_repo.get_by_id(playlist_id)
        if not playlist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="歌单不存在"
            )

        if playlist.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="无权修改此歌单"
            )

        success = await self.playlist_repo.add_item(
            playlist_id=playlist_id,
            bvid=data.bvid,
            title=data.title,
            artist=data.artist,
            cover_url=data.cover_url,
            duration=data.duration
        )

        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="歌曲已在歌单中"
            )

        logger.info(f"歌单项添加成功: playlist_id={playlist_id}, bvid={data.bvid}")
        return True

    async def remove_item(
        self,
        playlist_id: int,
        user_id: int,
        bvid: str
    ) -> bool:
        """移除歌单项"""
        playlist = await self.playlist_repo.get_by_id(playlist_id)
        if not playlist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="歌单不存在"
            )

        if playlist.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="无权修改此歌单"
            )

        success = await self.playlist_repo.remove_item(playlist_id, bvid)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="歌曲不存在"
            )

        logger.info(f"歌单项移除成功: playlist_id={playlist_id}, bvid={bvid}")
        return True