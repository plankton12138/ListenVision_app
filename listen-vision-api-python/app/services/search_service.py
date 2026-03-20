"""本地搜索服务"""
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, desc, delete

from app.models.audio_metadata import AudioMetadata
from app.models.search_history import SearchHistory
from app.schemas.search import SearchHistoryCreate, SearchHistoryResponse, LocalSearchResult
from app.utils.logger import logger


class SearchService:
    """本地搜索服务"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def local_search(
        self,
        user_id: int,
        keyword: str,
        limit: int = 20
    ) -> List[LocalSearchResult]:
        """本地全文搜索（简化实现，使用 ILIKE）"""
        pattern = f"%{keyword}%"
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            or_(
                AudioMetadata.title.ilike(pattern),
                AudioMetadata.artist.ilike(pattern),
                AudioMetadata.bvid.ilike(pattern)
            )
        ).order_by(AudioMetadata.updated_at.desc()).limit(limit)

        result = await self.db.execute(stmt)
        items = result.scalars().all()

        results = []
        for item in items:
            # 确定匹配类型
            match_type = "bvid"
            keyword_lower = keyword.lower()
            if item.title and keyword_lower in item.title.lower():
                match_type = "title"
            elif item.artist and keyword_lower in item.artist.lower():
                match_type = "artist"

            results.append(LocalSearchResult(
                bvid=item.bvid,
                title=item.title or "",
                artist=item.artist,
                cover_url=item.cover_url,
                duration=item.duration,
                match_type=match_type
            ))

        logger.info(f"本地搜索: user={user_id}, keyword={keyword}, results={len(results)}")
        return results

    async def get_suggestions(self, user_id: int, prefix: str, limit: int = 10) -> List[str]:
        """获取搜索建议"""
        pattern = f"{prefix}%"
        stmt = select(AudioMetadata.title, AudioMetadata.artist).where(
            AudioMetadata.user_id == user_id,
            or_(
                AudioMetadata.title.ilike(pattern),
                AudioMetadata.artist.ilike(pattern)
            )
        ).distinct().limit(limit)

        result = await self.db.execute(stmt)
        rows = result.all()

        suggestions = set()
        prefix_lower = prefix.lower()
        for title, artist in rows:
            if title and title.lower().startswith(prefix_lower):
                suggestions.add(title)
            if artist and artist.lower().startswith(prefix_lower):
                suggestions.add(artist)

        return list(suggestions)[:limit]

    async def add_search_history(self, user_id: int, data: SearchHistoryCreate) -> None:
        """添加搜索历史"""
        history = SearchHistory(user_id=user_id, keyword=data.keyword)
        self.db.add(history)
        await self.db.commit()
        logger.debug(f"添加搜索历史: user={user_id}, keyword={data.keyword}")

    async def get_search_history(
        self,
        user_id: int,
        limit: int = 10
    ) -> List[SearchHistoryResponse]:
        """获取搜索历史"""
        stmt = select(SearchHistory).where(
            SearchHistory.user_id == user_id
        ).order_by(desc(SearchHistory.searched_at)).limit(limit)

        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [SearchHistoryResponse.model_validate(item) for item in items]

    async def delete_search_history(self, user_id: int, history_id: int) -> bool:
        """删除单条搜索历史"""
        stmt = select(SearchHistory).where(
            SearchHistory.id == history_id,
            SearchHistory.user_id == user_id
        )
        result = await self.db.execute(stmt)
        history = result.scalar_one_or_none()

        if not history:
            return False

        await self.db.delete(history)
        await self.db.commit()
        return True

    async def clear_search_history(self, user_id: int) -> int:
        """清空搜索历史"""
        stmt = delete(SearchHistory).where(SearchHistory.user_id == user_id)
        result = await self.db.execute(stmt)
        await self.db.commit()
        logger.info(f"清空搜索历史: user={user_id}, deleted={result.rowcount}")
        return result.rowcount