from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text, Table
from sqlalchemy.orm import relationship
from app.db.database import Base


# 歌单项关联表
playlist_items = Table(
    "playlist_items",
    Base.metadata,
    Column("playlist_id", Integer, ForeignKey("playlists.id"), primary_key=True),
    Column("bvid", String(20), primary_key=True),
    Column("title", String(200)),
    Column("artist", String(100)),
    Column("cover_url", String(500)),
    Column("duration", Integer, default=0),
    Column("added_at", DateTime, default=datetime.utcnow),
    Column("order_index", Integer, default=0)
)


class Playlist(Base):
    """歌单模型"""
    __tablename__ = "playlists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    cover_url = Column(String(500), nullable=True)
    is_default = Column(Boolean, default=False)
    is_public = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    user = relationship("User", back_populates="playlists")
