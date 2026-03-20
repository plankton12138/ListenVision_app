from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum, Boolean
from sqlalchemy.orm import relationship
import enum
from app.db.database import Base


class PlatformType(str, enum.Enum):
    """平台类型"""
    BILIBILI = "bilibili"
    NETEASE = "netease"


class PlatformAccount(Base):
    """平台账号绑定"""
    __tablename__ = "platform_accounts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    platform_type = Column(Enum(PlatformType), nullable=False)

    # B站特有字段
    sessdata = Column(String(500), nullable=True)
    bili_jct = Column(String(255), nullable=True)
    dedeuserid = Column(String(50), nullable=True)

    # 网易云特有字段
    netease_cookie = Column(String(1000), nullable=True)
    netease_user_id = Column(String(50), nullable=True)

    # 元数据
    platform_username = Column(String(100), nullable=True)
    avatar_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    user = relationship("User", back_populates="platform_accounts")
