"""音频元数据模型"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
import enum

from app.db.database import Base


class DownloadStatus(str, enum.Enum):
    """下载状态枚举"""
    PENDING = "pending"
    DOWNLOADING = "downloading"
    COMPLETED = "completed"
    FAILED = "failed"


class AudioMetadata(Base):
    """音频元数据模型"""
    __tablename__ = "audio_metadata"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    bvid = Column(String(20), nullable=False, index=True)
    title = Column(String(200))
    artist = Column(String(100))
    cover_url = Column(String(500))
    duration = Column(Integer, default=0)
    local_path = Column(String(500))
    file_size = Column(Integer, default=0)
    play_progress = Column(Integer, default=0)
    download_status = Column(
        Enum(DownloadStatus),
        default=DownloadStatus.PENDING
    )
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    user = relationship("User", back_populates="audio_metadata")