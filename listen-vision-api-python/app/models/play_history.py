"""播放历史模型"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.db.database import Base


class PlayHistory(Base):
    """播放历史模型"""
    __tablename__ = "play_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    bvid = Column(String(20), nullable=False, index=True)
    title = Column(String(200), nullable=True)
    artist = Column(String(100), nullable=True)
    cover_url = Column(String(500), nullable=True)
    duration = Column(Integer, default=0)
    progress = Column(Integer, default=0)
    play_count = Column(Integer, default=1)
    last_played_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    # 关系
    user = relationship("User", back_populates="play_history")