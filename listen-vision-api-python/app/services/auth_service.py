from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.db.repositories.user_repo import UserRepository
from app.db.repositories.platform_account_repo import PlatformAccountRepository
from app.utils.security import verify_password, hash_password, create_access_token, create_refresh_token, decode_token
from app.schemas.auth import UserCreate, UserResponse, TokenResponse, PlatformAccountResponse
from app.utils.logger import logger
from app.config import get_settings

settings = get_settings()


class AuthService:
    """认证服务"""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.platform_repo = PlatformAccountRepository(db)

    async def register(self, user_data: UserCreate) -> UserResponse:
        """用户注册"""
        # 检查邮箱是否已存在
        if await self.user_repo.exists_by_email(user_data.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="邮箱已被注册"
            )

        # 创建用户
        hashed_password = hash_password(user_data.password)
        user = await self.user_repo.create(
            email=user_data.email,
            hashed_password=hashed_password,
            username=user_data.username
        )

        logger.info(f"User registered: {user.email}")
        return UserResponse.model_validate(user)

    async def login(self, email: str, password: str) -> TokenResponse:
        """用户登录"""
        user = await self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="邮箱或密码错误"
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="账号已被禁用"
            )

        # 生成 Token
        access_token = create_access_token({"sub": str(user.id)})
        refresh_token = create_refresh_token({"sub": str(user.id)})

        logger.info(f"User logged in: {user.email}")
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=settings.access_token_expire_minutes * 60
        )

    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        """刷新 Token"""
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="无效的刷新 Token"
            )

        user_id = payload.get("sub")
        user = await self.user_repo.get_by_id(int(user_id))
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户不存在或已被禁用"
            )

        # 生成新 Token
        new_access_token = create_access_token({"sub": str(user.id)})
        new_refresh_token = create_refresh_token({"sub": str(user.id)})

        return TokenResponse(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            expires_in=settings.access_token_expire_minutes * 60
        )

    async def get_current_user(self, user_id: int) -> UserResponse:
        """获取当前用户"""
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        return UserResponse.model_validate(user)

    async def get_user_with_platforms(self, user_id: int) -> dict:
        """获取用户及其平台账号"""
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )

        accounts = await self.platform_repo.get_by_user(user_id)
        platform_responses = [
            PlatformAccountResponse.model_validate(acc) for acc in accounts
        ]

        return {
            **UserResponse.model_validate(user).model_dump(),
            "platform_accounts": [acc.model_dump() for acc in platform_responses]
        }