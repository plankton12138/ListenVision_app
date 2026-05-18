from datetime import datetime, timedelta
from typing import Optional
import random
import string
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.db.repositories.user_repo import UserRepository
from app.db.repositories.platform_account_repo import PlatformAccountRepository
from app.utils.security import verify_password, hash_password, create_access_token, create_refresh_token, decode_token
from app.schemas.auth import UserCreate, UserResponse, TokenResponse, PlatformAccountResponse
from app.services.email_service import email_service
from app.utils.logger import logger
from app.config import get_settings

settings = get_settings()


class AuthService:
    """认证服务"""

    # 内存验证码存储: {key: (code, expires_at)}
    _verification_codes: dict[str, tuple[str, datetime]] = {}

    # 验证码有效期（分钟）
    CODE_EXPIRE_MINUTES: int = 10

    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.platform_repo = PlatformAccountRepository(db)

    @staticmethod
    def _generate_code(length: int = 6) -> str:
        """生成数字验证码"""
        return ''.join(random.choices(string.digits, k=length))

    @staticmethod
    def _get_code_key(email: str, purpose: str) -> str:
        """生成验证码存储键"""
        return f"{purpose}:{email.lower()}"

    async def send_verification_code(self, email: str, purpose: str = "register") -> str:
        """
        发送验证码

        Args:
            email: 目标邮箱
            purpose: 用途 (register, reset_password)

        Returns:
            生成的验证码（开发环境）

        Raises:
            HTTPException: 发送失败
        """
        purpose_map = {
            "register": "注册",
            "reset_password": "重置密码"
        }
        purpose_text = purpose_map.get(purpose, purpose)

        # 检查邮箱状态
        if purpose == "register":
            # 注册时检查邮箱是否已被使用
            if await self.user_repo.exists_by_email(email):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="邮箱已被注册"
                )
        elif purpose == "reset_password":
            # 重置密码时检查邮箱是否存在
            if not await self.user_repo.exists_by_email(email):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="邮箱未注册"
                )

        # 生成验证码
        code = self._generate_code()
        key = self._get_code_key(email, purpose)
        expires_at = datetime.utcnow() + timedelta(minutes=self.CODE_EXPIRE_MINUTES)

        # 存储验证码
        self._verification_codes[key] = (code, expires_at)

        # 发送邮件
        success = await email_service.send_verification_code(email, code, purpose_text)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="发送验证码失败，请稍后重试"
            )

        logger.info(f"验证码已生成: {email}, purpose={purpose}")
        return code

    def _verify_code(self, email: str, code: str, purpose: str) -> bool:
        """
        验证验证码

        Args:
            email: 邮箱
            code: 用户输入的验证码
            purpose: 用途

        Returns:
            是否验证成功
        """
        key = self._get_code_key(email, purpose)

        if key not in self._verification_codes:
            return False

        stored_code, expires_at = self._verification_codes[key]

        # 检查是否过期
        if datetime.utcnow() > expires_at:
            del self._verification_codes[key]
            return False

        # 验证码匹配
        if stored_code == code:
            # 验证成功后删除
            del self._verification_codes[key]
            return True

        return False

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
        """用户登录（支持邮箱或用户名）"""
        user = await self.user_repo.get_by_email(email)
        if not user and '@' not in email:
            user = await self.user_repo.get_by_username(email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户不存在"
            )
        if not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="密码错误"
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

    async def verify_email_and_register(
        self,
        email: str,
        code: str,
        password: str,
        username: Optional[str] = None
    ) -> UserResponse:
        """
        验证邮箱并完成注册

        Args:
            email: 邮箱
            code: 验证码
            password: 密码
            username: 用户名（可选）

        Returns:
            注册成功的用户信息

        Raises:
            HTTPException: 验证失败
        """
        # 验证验证码
        if not self._verify_code(email, code, "register"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证码无效或已过期"
            )

        # 再次检查邮箱是否已被使用（防止竞态条件）
        if await self.user_repo.exists_by_email(email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="邮箱已被注册"
            )

        # 创建用户
        hashed_password = hash_password(password)
        user = await self.user_repo.create(
            email=email,
            hashed_password=hashed_password,
            username=username
        )

        # 生成 Token，注册后直接登录
        access_token = create_access_token({"sub": str(user.id)})
        refresh_token = create_refresh_token({"sub": str(user.id)})

        logger.info(f"User registered with email verification: {user.email}")
        return {
            "user": UserResponse.model_validate(user).model_dump(),
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": settings.access_token_expire_minutes * 60,
        }

    async def reset_password(
        self,
        email: str,
        code: str,
        new_password: str
    ) -> bool:
        """
        重置密码

        Args:
            email: 邮箱
            code: 验证码
            new_password: 新密码

        Returns:
            是否重置成功

        Raises:
            HTTPException: 验证失败
        """
        # 验证验证码
        if not self._verify_code(email, code, "reset_password"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="验证码无效或已过期"
            )

        # 获取用户
        user = await self.user_repo.get_by_email(email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )

        # 更新密码
        hashed_password = hash_password(new_password)
        await self.user_repo.update_password(user.id, hashed_password)

        logger.info(f"Password reset for user: {email}")
        return True

    async def delete_account(self, user_id: int) -> bool:
        """
        删除用户账号

        Args:
            user_id: 用户ID

        Returns:
            是否删除成功

        Raises:
            HTTPException: 用户不存在
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )

        # 删除关联的平台账号
        await self.platform_repo.delete_by_user(user_id)

        # 删除用户
        await self.user_repo.delete(user_id)

        logger.info(f"Account deleted: user_id={user_id}")
        return True