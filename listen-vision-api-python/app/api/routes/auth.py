from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.auth_service import AuthService
from app.schemas.auth import (
    UserCreate, UserResponse, LoginRequest, TokenResponse,
    RefreshRequest, UserMeResponse
)
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/register", response_model=ApiResponse[UserResponse])
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """用户注册"""
    service = AuthService(db)
    user = await service.register(user_data)
    return ApiResponse(success=True, message="注册成功", data=user)


@router.post("/login", response_model=ApiResponse[TokenResponse])
async def login(
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """用户登录"""
    service = AuthService(db)
    token = await service.login(login_data.email, login_data.password)
    return ApiResponse(success=True, message="登录成功", data=token)


@router.post("/refresh", response_model=ApiResponse[TokenResponse])
async def refresh_token(
    refresh_data: RefreshRequest,
    db: AsyncSession = Depends(get_db)
):
    """刷新令牌"""
    service = AuthService(db)
    token = await service.refresh_token(refresh_data.refresh_token)
    return ApiResponse(success=True, message="刷新成功", data=token)


@router.get("/me", response_model=ApiResponse[UserMeResponse])
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取当前用户信息"""
    service = AuthService(db)
    user_data = await service.get_user_with_platforms(current_user.id)
    return ApiResponse(success=True, data=UserMeResponse(**user_data))