/**
 * QR码登录功能测试程序
 *
 * 功能演示：
 * 1. 获取QR码登录凭证
 * 2. 在终端显示QR码
 * 3. 轮询检查登录状态
 * 4. 显示登录结果
 */

const bilibiliService = require('../services/bilibiliService');
const QRCode = require('qrcode');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

function log(color, text) {
  console.log(`${color}${text}${colors.reset}`);
}

/**
 * 步骤1: 获取QR码
 */
async function step1_GetQRCode() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 1: 获取B站QR码登录凭证                      ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, '→ 正在调用B站API获取QR码...');

  try {
    const result = await bilibiliService.getQRCode();

    log(colors.green, '✓ QR码获取成功!\n');

    log(colors.blue, '═══════════════════════════════════════════════════════════');
    log(colors.blue, '  返回数据解析:');
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    console.log('');
    console.log(`  qrcodeKey  : ${colors.green}${result.qrcodeKey}${colors.reset}`);
    console.log(`  QR码URL    : ${result.qrCodeUrl}`);
    console.log(`  有效期     : ${result.expires_in} 秒`);
    console.log('');

    return result;
  } catch (error) {
    log(colors.red, `✗ 获取QR码失败: ${error.message}`);
    throw error;
  }
}

/**
 * 步骤2: 显示QR码
 */
async function step2_ShowQRCode(qrcodeUrl) {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 2: 显示QR码                                 ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, '→ 正在生成QR码图像...\n');

  // 在终端显示QR码
  const qrCodeString = await QRCode.toString(qrcodeUrl, { type: 'terminal', small: true });
  console.log(qrCodeString);

  log(colors.green, '\n✓ 请使用哔哩哔哩APP扫描上方QR码登录\n');
  log(colors.yellow, '  提示: 扫码后需要在手机上点击"确认登录"\n');
}

/**
 * 步骤3: 轮询检查登录状态
 */
async function step3_PollLoginStatus(qrcodeKey) {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 3: 轮询检查登录状态                          ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, '→ 开始轮询，每隔3秒检查一次登录状态...\n');

  const maxAttempts = 60; // 最多轮询60次（3分钟）
  let attempts = 0;

  while (attempts < maxAttempts) {
    attempts++;

    try {
      const result = await bilibiliService.checkQRLoginStatus(qrcodeKey);

      // 状态映射
      const statusMessages = {
        'pending': '⏳ 等待扫码...',
        'scanned': '📱 已扫码，等待确认...',
        'expired': '⏰ QR码已过期',
        'success': '✅ 登录成功!',
        'unknown': '❓ 未知状态'
      };

      const message = statusMessages[result.status] || statusMessages['unknown'];

      // 根据状态显示不同颜色
      if (result.status === 'success') {
        log(colors.green, `[${attempts}/${maxAttempts}] ${message}`);
        return result;
      } else if (result.status === 'expired') {
        log(colors.red, `[${attempts}/${maxAttempts}] ${message}`);
        return null;
      } else if (result.status === 'scanned') {
        log(colors.yellow, `[${attempts}/${maxAttempts}] ${message}`);
      } else {
        log(colors.blue, `[${attempts}/${maxAttempts}] ${message}`);
      }

      // 调试信息：显示原始状态码
      if (result.statusCode !== undefined) {
        console.log(`           └─ 原始状态码: ${result.statusCode}`);
      }

      // 如果不是最终状态，等待3秒后继续
      if (!['success', 'expired'].includes(result.status)) {
        await new Promise(resolve => setTimeout(resolve, 3000));
      }

    } catch (error) {
      log(colors.red, `[${attempts}/${maxAttempts}] 检查状态出错: ${error.message}`);
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
  }

  log(colors.red, '\n✗ 轮询超时，请重新运行程序');
  return null;
}

/**
 * 步骤4: 显示登录结果
 */
async function step4_ShowResult(loginResult) {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 4: 登录结果                                   ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  if (!loginResult || loginResult.status !== 'success') {
    log(colors.red, '✗ 登录失败或超时\n');
    return;
  }

  log(colors.green, '✅ 登录成功!\n');

  log(colors.blue, '═══════════════════════════════════════════════════════════');
  log(colors.blue, '  API返回数据:');
  log(colors.blue, '═══════════════════════════════════════════════════════════');
  console.log('');
  console.log(`  状态码       : ${loginResult.statusCode}`);
  console.log(`  RefreshToken : ${loginResult.refreshToken ? '已获取' : '无'}`);
  console.log(`  时间戳       : ${loginResult.timestamp ? new Date(loginResult.timestamp).toLocaleString() : '无'}`);
  console.log('');

  if (loginResult.refreshUrl) {
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    log(colors.blue, '  刷新URL (包含用户信息):');
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    console.log('');
    console.log(`  ${loginResult.refreshUrl.substring(0, 100)}...`);
    console.log('');
  }

  log(colors.yellow, '⚠️  注意: Web端QR码登录的Cookie通过HTTP响应头设置');
  log(colors.yellow, '          完整登录流程需要处理OAuth跳转\n');
}

/**
 * 主函数
 */
async function main() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '║           B站QR码登录功能测试程序                            ║');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝');

  try {
    // 步骤1: 获取QR码
    const qrData = await step1_GetQRCode();

    // 步骤2: 显示QR码
    await step2_ShowQRCode(qrData.qrCodeUrl);

    // 步骤3: 轮询检查登录状态
    const loginResult = await step3_PollLoginStatus(qrData.qrcodeKey);

    // 步骤4: 显示结果
    await step4_ShowResult(loginResult);

  } catch (error) {
    log(colors.red, `\n✗ 程序出错: ${error.message}`);
    process.exit(1);
  }
}

// 运行主函数
main();
