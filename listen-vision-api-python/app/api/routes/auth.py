from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.auth_service import AuthService
from app.schemas.auth import (
    UserCreate, UserResponse, LoginRequest, TokenResponse,
    RefreshRequest, UserMeResponse, VerifyAndRegisterRequest
)
from app.schemas.email import SendCodeRequest, ResetPasswordRequest
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/register", response_model=ApiResponse[UserResponse])
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """用户注册（直接注册，无需验证码）"""
    service = AuthService(db)
    user = await service.register(user_data)
    return ApiResponse(success=True, message="注册成功", data=user)


@router.post("/send-code", response_model=ApiResponse)
async def send_verification_code(
    request: SendCodeRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    发送验证码

    purpose: register | reset_password
    """
    service = AuthService(db)
    code = await service.send_verification_code(request.email, request.purpose)
    return ApiResponse(
        success=True,
        message="验证码已发送",
        data={"code": code} if code else None  # 开发环境返回验证码
    )


@router.post("/verify-email")
async def verify_email_and_register(
    request: VerifyAndRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    验证邮箱并完成注册

    - **email**: 邮箱地址
    - **code**: 验证码
    - **password**: 密码
    - **username**: 用户名（可选）

    注册成功后直接返回 access_token / refresh_token
    """
    service = AuthService(db)
    result = await service.verify_email_and_register(
        email=request.email,
        code=request.code,
        password=request.password,
        username=request.username
    )
    return ApiResponse(success=True, message="注册成功", data=result)


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


@router.post("/reset-pwd", response_model=ApiResponse)
async def reset_password(
    request: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    重置密码

    需要先调用 /send-code 获取验证码
    """
    service = AuthService(db)
    await service.reset_password(
        email=request.email,
        code=request.code,
        new_password=request.new_password
    )
    return ApiResponse(success=True, message="密码重置成功")


@router.delete("/account", response_model=ApiResponse)
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    注销账号

    需要登录，删除当前用户的所有数据
    """
    service = AuthService(db)
    await service.delete_account(current_user.id)
    return ApiResponse(success=True, message="账号已注销")