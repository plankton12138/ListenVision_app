from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, delete
from app.models.playlist import Playlist, playlist_items


class PlaylistRepository:
    """歌单数据访问层"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(
        self,
        user_id: int,
        name: str,
        description: Optional[str] = None,
        is_default: bool = False
    ) -> Playlist:
        """创建歌单"""
        playlist = Playlist(
            user_id=user_id,
            name=name,
            description=description,
            is_default=is_default
        )
        self.db.add(playlist)
        await self.db.commit()
        await self.db.refresh(playlist)
        return playlist

    async def get_by_id(self, playlist_id: int) -> Optional[Playlist]:
        """根据ID获取歌单"""
        result = await self.db.execute(
            select(Playlist).where(Playlist.id == playlist_id)
        )
        return result.scalar_one_or_none()

    async def get_by_user(self, user_id: int) -> List[Playlist]:
        """获取用户的所有歌单"""
        result = await self.db.execute(
            select(Playlist).where(Playlist.user_id == user_id)
        )
        return result.scalars().all()

    async def update(self, playlist_id: int, **kwargs) -> Optional[Playlist]:
        """更新歌单"""
        playlist = await self.get_by_id(playlist_id)
        if not playlist:
            return None

        for key, value in kwargs.items():
            if hasattr(playlist, key):
                setattr(playlist, key, value)

        await self.db.commit()
        await self.db.refresh(playlist)
        return playlist

    async def delete(self, playlist_id: int) -> bool:
        """删除歌单"""
        playlist = await self.get_by_id(playlist_id)
        if not playlist:
            return False

        await self.db.delete(playlist)
        await self.db.commit()
        return True

    async def add_item(self, playlist_id: int, bvid: str, title: str,
                       artist: Optional[str] = None, cover_url: Optional[str] = None,
                       duration: int = 0) -> bool:
        """添加歌单项"""
        # 检查是否已存在
        result = await self.db.execute(
            select(playlist_items).where(
                and_(
                    playlist_items.c.playlist_id == playlist_id,
                    playlist_items.c.bvid == bvid
                )
            )
        )
        if result.scalar_one_or_none():
            return False

        # 获取当前最大order_index
        result = await self.db.execute(
            select(playlist_items.c.order_index)
            .where(playlist_items.c.playlist_id == playlist_id)
            .order_by(playlist_items.c.order_index.desc())
        )
        max_order = result.scalar() or 0

        await self.db.execute(
            playlist_items.insert().values(
                playlist_id=playlist_id,
                bvid=bvid,
                title=title,
                artist=artist,
                cover_url=cover_url,
                duration=duration,
                order_index=max_order + 1
            )
        )
        await self.db.commit()
        return True

    async def remove_item(self, playlist_id: int, bvid: str) -> bool:
        """移除歌单项"""
        result = await self.db.execute(
            delete(playlist_items).where(
                and_(
                    playlist_items.c.playlist_id == playlist_id,
                    playlist_items.c.bvid == bvid
                )
            )
        )
        await self.db.commit()
        return result.rowcount > 0

    async def get_items(self, playlist_id: int) -> List[dict]:
        """获取歌单所有项"""
        result = await self.db.execute(
            select(playlist_items)
            .where(playlist_items.c.playlist_id == playlist_id)
            .order_by(playlist_items.c.order_index)
        )
        rows = result.all()
        return [
            {
                "bvid": row.bvid,
                "title": row.title,
                "artist": row.artist,
                "cover_url": row.cover_url,
                "duration": row.duration,
                "added_at": row.added_at
            }
            for row in rows
        ]
