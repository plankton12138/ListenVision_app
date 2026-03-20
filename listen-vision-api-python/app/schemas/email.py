"""邮件相关 Schema"""
from pydantic import BaseModel, EmailStr


class SendCodeRequest(BaseModel):
    """发送验证码请求"""
    email: EmailStr
    purpose: str = "register"  # register, reset_password


class VerifyEmailRequest(BaseModel):
    """验证邮箱请求"""
    email: EmailStr
    code: str


class ResetPasswordRequest(BaseModel):
    """重置密码请求"""
    email: EmailStr
    code: str
    new_password: str