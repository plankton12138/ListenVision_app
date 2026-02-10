const nodemailer = require('nodemailer');
const db = require('../config/database');

// SMTP 邮件服务配置
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT) || 465,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// 预编译语句
const stmt = {
  userEmail: db.prepare('SELECT email FROM users WHERE username = ?'),
  setResetCode: db.prepare('UPDATE users SET reset_code = ?, code_expire = ? WHERE username = ?'),
};

// 发送密码重置验证码
const sendResetCode = async (username) => {
  // 查询用户邮箱
  const user = stmt.userEmail.get(username);
  // 统一返回成功，防止用户探测
  if (!user) {
    return { success: true };
  }

  const userEmail = user.email;

  // 生成 6 位随机验证码
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  // 10 分钟后过期（SQLite datetime 格式）
  const expiryDate = new Date(Date.now() + 10 * 60 * 1000);
  const expiry = expiryDate.toISOString().replace('T', ' ').substring(0, 19);

  console.log('发送验证码 - 邮箱:', userEmail, '验证码:', code, '有效期:', expiry);

  // 保存验证码到数据库
  stmt.setResetCode.run(code, expiry, username);

  // 发送邮件
  const mailOptions = {
    from: `"ListenVision" <${process.env.SMTP_USER}>`,
    to: userEmail,
    subject: '验证码通知',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">密码重置验证码</h2>
        <p>您好，</p>
        <p>您正在重置 ListenVision 账号的密码。</p>
        <p style="font-size: 24px; color: #007bff; font-weight: bold; letter-spacing: 2px;">
          ${code}
        </p>
        <p>验证码有效期为 <strong>10 分钟</strong>，请尽快使用。</p>
        <p style="color: #666; font-size: 14px;">如果这不是您的操作，请忽略此邮件。</p>
        <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">此邮件由系统自动发送，请勿回复。</p>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`验证码已发送至 ${userEmail}`);
  } catch (error) {
    console.error('邮件发送失败:', error);
    // 即使邮件发送失败，也返回成功（防止探测）
  }

  return { success: true };
};

// 发送普通邮件（通用方法）
const sendEmail = async (to, subject, html) => {
  const mailOptions = {
    from: `"ListenVision" <${process.env.SMTP_USER}>`,
    to,
    subject,
    html
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('邮件发送成功:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('邮件发送失败:', error);
    throw new Error('邮件发送失败');
  }
};

// 发送注册验证码
const sendVerificationCode = async (email, code) => {
  const mailOptions = {
    from: `"ListenVision" <${process.env.SMTP_USER}>`,
    to: email,
    subject: '注册验证码',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">欢迎注册 ListenVision</h2>
        <p>您好，</p>
        <p>您正在注册 ListenVision 账号，请使用以下验证码完成注册：</p>
        <p style="font-size: 32px; color: #007bff; font-weight: bold; letter-spacing: 4px; text-align: center; padding: 20px 0;">
          ${code}
        </p>
        <p>验证码有效期为 <strong>10 分钟</strong>，请尽快使用。</p>
        <p style="color: #666; font-size: 14px;">如果这不是您的操作，请忽略此邮件。</p>
        <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">此邮件由系统自动发送，请勿回复。</p>
      </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('注册验证码已发送至:', email);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('注册验证码发送失败:', error);
    throw new Error('邮件发送失败');
  }
};

// 生成验证码
const generateVerifyCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

module.exports = {
  sendResetCode,
  sendEmail,
  sendVerificationCode,
  generateVerifyCode
};
