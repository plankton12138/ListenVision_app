from typing import Optional
from datetime import datetime
from bilibili_api import user, Credential
from bilibili_api.login_v2 import QrCodeLogin
from bilibili_api.exceptions import ResponseCodeException, LoginError

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.repositories.platform_account_repo import PlatformAccountRepository
from app.utils.logger import logger
from app.schemas.bilibili import QRCodeResponse, QRCodeCheckResponse, BilibiliStatusResponse


class BilibiliAuthService:
    """B站认证服务"""

    def __init__(self, db: Optional[AsyncSession] = None):
        self.db = db
        if db:
            self.platform_repo = PlatformAccountRepository(db)

    async def generate_qrcode(self) -> QRCodeResponse:
        """生成登录二维码"""
        try:
            qr_login = QrCodeLogin()
            qr_data = await qr_login.get_qrcode()
            return QRCodeResponse(
                qrcode_key=qr_data.qrcode_key,
                qr_url=qr_data.url,
                expires_in=300
            )
        except Exception as e:
            logger.error(f"生成二维码失败: {e}")
            raise

    async def check_qrcode(self, qrcode_key: str) -> tuple[QRCodeCheckResponse, Optional[Credential]]:
        """检查二维码扫描状态"""
        try:
            qr_login = QrCodeLogin()
            result = await qr_login.check_qrcode(qrcode_key)

            if result.code == 0:
                # 登录成功
                return QRCodeCheckResponse(
                    status="success",
                    message="登录成功"
                ), result.credential
            elif result.code == 86038:
                return QRCodeCheckResponse(
                    status="expired",
                    message="二维码已过期"
                ), None
            elif result.code == 86090:
                return QRCodeCheckResponse(
                    status="scanned",
                    message="已扫描，等待确认"
                ), None
            elif result.code == 86101:
                return QRCodeCheckResponse(
                    status="pending",
                    message="等待扫描"
                ), None
            else:
                return QRCodeCheckResponse(
                    status="error",
                    message=f"未知错误: {result.code}"
                ), None
        except Exception as e:
            logger.error(f"检查二维码失败: {e}")
            raise

    async def bind_bilibili_account(
        self,
        user_id: int,
        sessdata: str,
        bili_jct: str,
        dedeuserid: str
    ) -> dict:
        """绑定B站账号"""
        if not self.db:
            raise ValueError("Database session required")

        try:
            # 使用凭证获取用户信息
            credential = Credential(
                sessdata=sessdata,
                bili_jct=bili_jct,
                dedeuserid=dedeuserid
            )
            u = user.User(credential=credential)
            my_info = await u.get_user_info()

            platform_username = my_info.get("name", "")
            avatar_url = my_info.get("face", "")

            # 保存到数据库
            account = await self.platform_repo.create_bilibili(
                user_id=user_id,
                sessdata=sessdata,
                bili_jct=bili_jct,
                dedeuserid=dedeuserid,
                platform_username=platform_username
            )

            logger.info(f"B站账号绑定成功: user_id={user_id}, bili_name={platform_username}")

            return {
                "id": account.id,
                "platform_type": "bilibili",
                "platform_username": platform_username,
                "avatar_url": avatar_url
            }
        except Exception as e:
            logger.error(f"绑定B站账号失败: {e}")
            raise

    async def unbind_bilibili_account(self, user_id: int) -> bool:
        """解绑B站账号"""
        if not self.db:
            raise ValueError("Database session required")

        from app.models.platform_account import PlatformType
        await self.platform_repo.delete_by_platform(user_id, PlatformType.BILIBILI)
        logger.info(f"B站账号解绑成功: user_id={user_id}")
        return True

    async def get_bilibili_status(self, user_id: int) -> BilibiliStatusResponse:
        """获取B站绑定状态"""
        if not self.db:
            raise ValueError("Database session required")

        from app.models.platform_account import PlatformType
        account = await self.platform_repo.get_by_user_and_platform(
            user_id, PlatformType.BILIBILI
        )

        if account:
            return BilibiliStatusResponse(
                is_bound=True,
                username=account.platform_username,
                avatar_url=account.avatar_url
            )
        return BilibiliStatusResponse(is_bound=False)