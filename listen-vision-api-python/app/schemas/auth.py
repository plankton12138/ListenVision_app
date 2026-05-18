from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """用户基础信息"""
    email: EmailStr
    username: Optional[str] = None


class UserCreate(UserBase):
    """用户注册请求"""
    password: str = Field(..., min_length=6)


class UserResponse(UserBase):
    """用户响应"""
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    """登录请求（支持邮箱或用户名）"""
    email: str = Field(..., description="邮箱或用户名")
    password: str


class VerifyAndRegisterRequest(BaseModel):
    """验证邮箱并完成注册请求"""
    email: EmailStr
    code: str
    password: str = Field(..., min_length=6)
    username: Optional[str] = None


class TokenResponse(BaseModel):
    """Token 响应"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    """刷新 Token 请求"""
    refresh_token: str


class PlatformAccountResponse(BaseModel):
    """平台账号响应"""
    id: int
    platform_type: str
    platform_username: Optional[str]
    avatar_url: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserMeResponse(UserResponse):
    """当前用户详情响应"""
    platform_accounts: list[PlatformAccountResponse] = []
