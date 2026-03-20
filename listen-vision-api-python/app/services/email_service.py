"""邮件服务"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional

from app.config import get_settings
from app.utils.logger import logger

settings = get_settings()


class EmailService:
    """邮件发送服务"""

    def __init__(self):
        self.smtp_host = settings.smtp_host
        self.smtp_port = settings.smtp_port
        self.smtp_user = settings.smtp_user
        self.smtp_pass = settings.smtp_pass
        self.from_email = settings.smtp_from_email or settings.smtp_user

    async def send_verification_code(
        self,
        to_email: str,
        code: str,
        purpose: str = "注册"
    ) -> bool:
        """
        发送验证码邮件

        Args:
            to_email: 目标邮箱
            code: 验证码
            purpose: 用途（注册、重置密码等）

        Returns:
            是否发送成功
        """
        if not all([self.smtp_host, self.smtp_user, self.smtp_pass]):
            logger.warning(f"SMTP 配置不完整，跳过邮件发送: {to_email}")
            # 开发环境（未配置SMTP）模拟发送成功
            logger.info(f"[开发模式] 验证码: {code}, 邮箱: {to_email}")
            return True

        subject = f"Listen Vision - {purpose}验证码"
        body = f"""
        <html>
        <body>
            <h2>Listen Vision {purpose}验证</h2>
            <p>您的验证码是：<strong style="font-size: 24px; color: #2563eb;">{code}</strong></p>
            <p>验证码有效期为 10 分钟，请尽快使用。</p>
            <p>如果您没有请求此验证码，请忽略此邮件。</p>
            <hr>
            <p style="color: #6b7280; font-size: 12px;">
                此邮件由系统自动发送，请勿回复。
            </p>
        </body>
        </html>
        """

        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = self.from_email
            msg["To"] = to_email
            msg.attach(MIMEText(body, "html", "utf-8"))

            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_pass)
                server.sendmail(self.smtp_user, to_email, msg.as_string())

            logger.info(f"验证码邮件已发送: {to_email}, purpose={purpose}")
            return True
        except Exception as e:
            logger.error(f"发送邮件失败: {e}")
            return False


# 单例
email_service = EmailService()