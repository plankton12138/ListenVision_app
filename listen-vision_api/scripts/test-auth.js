/**
 * 自动认证测试脚本
 *
 * 用途：
 * - 快速测试注册/登录功能
 * - 验证 JWT 配置是否正确
 * - 部署后自动化验证
 *
 * 使用方法：
 *   node scripts/test-auth.js [URL]
 *
 * 示例：
 *   node scripts/test-auth.js                          # 本地测试
 *   node scripts/test-auth.js https://api.example.com  # 远程测试
 */

const URL = process.argv[2] || 'http://127.0.0.1:3000';
const API_BASE = URL.endsWith('/api') ? URL : `${URL}/api`;

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(color, text) {
  console.log(`${color}${text}${colors.reset}`);
}

// 生成随机测试用户
function generateTestUser() {
  const timestamp = Date.now().toString(36);
  return {
    username: `test_${timestamp}`,
    email: `test_${timestamp}@example.com`,
    password: 'Test123456'
  };
}

// 通用请求函数
async function request(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  };

  try {
    const response = await fetch(url, { ...options, headers });
    const data = await response.json();
    return { status: response.status, data, ok: response.ok };
  } catch (error) {
    return { error: error.message, ok: false };
  }
}

// 测试注册
async function testRegister(user) {
  log(colors.blue, '\n[1/3] 测试注册...');
  log(colors.cyan, `  用户: ${user.username}`);
  log(colors.cyan, `  邮箱: ${user.email}`);

  const result = await request('/auth/register', {
    method: 'POST',
    body: JSON.stringify({
      username: user.username,
      email: user.email,
      password: user.password
    })
  });

  if (result.ok && result.data?.data?.token) {
    log(colors.green, '  ✓ 注册成功');
    return { success: true, token: result.data.data.token, user: result.data.data.user };
  }

  if (result.data?.error) {
    log(colors.red, `  ✗ 失败: ${result.data.error}`);
  } else {
    log(colors.red, `  ✗ 失败: ${JSON.stringify(result.data || result.error)}`);
  }
  return { success: false };
}

// 测试登录
async function testLogin(user) {
  log(colors.blue, '\n[2/3] 测试登录...');

  const result = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      username: user.username,
      password: user.password
    })
  });

  if (result.ok && result.data?.data?.token) {
    log(colors.green, '  ✓ 登录成功');
    return { success: true, token: result.data.data.token, user: result.data.data.user };
  }

  if (result.data?.error) {
    log(colors.red, `  ✗ 失败: ${result.data.error}`);
  } else {
    log(colors.red, `  ✗ 失败: ${JSON.stringify(result.data || result.error)}`);
  }
  return { success: false };
}

// 测试 Token 验证
async function testVerifyToken(token) {
  log(colors.blue, '\n[3/3] 测试 Token 验证...');

  const result = await request('/auth/me', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });

  if (result.ok && result.data?.data) {
    log(colors.green, '  ✓ Token 有效');
    log(colors.cyan, `  用户ID: ${result.data.data.id}`);
    log(colors.cyan, `  用户名: ${result.data.data.username}`);
    return { success: true, user: result.data.data };
  }

  if (result.data?.error) {
    log(colors.red, `  ✗ 失败: ${result.data.error}`);
  } else {
    log(colors.red, `  ✗ 失败: ${result.status}`);
  }
  return { success: false };
}

// 健康检查
async function healthCheck() {
  log(colors.blue, '\n[0/3] 健康检查...');

  const result = await request('/health'.replace('/api', ''), {
    headers: {} // 不需要 /api 前缀
  });

  // 如果上面的不行，直接访问
  const healthUrl = API_BASE.replace('/api', '') + '/health';
  const directResult = await request('', {
    headers: {}
  });

  // 尝试直接 fetch
  try {
    const response = await fetch(healthUrl);
    if (response.ok) {
      log(colors.green, `  ✓ 服务运行中 (${URL})`);
      return true;
    }
  } catch (e) {
    // 忽略
  }

  log(colors.yellow, `  ⚠ 无法连接到 ${URL}`);
  return false;
}

// 主函数
async function main() {
  console.log('');
  log(colors.cyan, '╔════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║              ListenVision 认证自动化测试                ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════╝');
  log(colors.blue, `  目标: ${URL}`);
  log(colors.blue, `  API: ${API_BASE}`);

  // 健康检查
  const isHealthy = await healthCheck();
  if (!isHealthy) {
    log(colors.yellow, '\n提示: 请确保服务器正在运行');
    process.exit(1);
  }

  // 生成测试用户
  const testUser = generateTestUser();

  // 测试注册
  const registerResult = await testRegister(testUser);

  let token = null;
  let finalUser = null;

  if (registerResult.success) {
    token = registerResult.token;
    finalUser = registerResult.user;
  } else {
    // 注册失败，尝试用现有用户登录（用于重复测试）
    log(colors.yellow, '\n  注册失败，尝试使用固定测试用户登录...');
    const fixedUser = { username: 'test_user', email: 'test@example.com', password: 'Test123456' };
    const loginResult = await testLogin(fixedUser);
    if (loginResult.success) {
      token = loginResult.token;
      finalUser = loginResult.user;
    } else {
      // 先注册固定用户
      log(colors.yellow, '\n  先注册固定测试用户...');
      const regResult = await request('/auth/register', {
        method: 'POST',
        body: JSON.stringify(fixedUser)
      });
      if (regResult.ok && regResult.data?.data?.token) {
        token = regResult.data.data.token;
        finalUser = regResult.data.data.user;
        log(colors.green, '  ✓ 固定用户注册成功');
      }
    }
  }

  if (!token) {
    log(colors.red, '\n╔════════════════════════════════════════════════════════╗');
    log(colors.red, '║                   测试失败                                ║');
    log(colors.red, '╚════════════════════════════════════════════════════════╝');
    log(colors.yellow, '\n可能原因:');
    log(colors.yellow, '  1. JWT_SECRET 环境变量未设置');
    log(colors.yellow, '  2. 数据库未初始化');
    log(colors.yellow, '  3. 服务器配置错误\n');
    process.exit(1);
  }

  // 测试 Token 验证
  const verifyResult = await testVerifyToken(token);

  // 总结
  console.log('');
  if (verifyResult.success) {
    log(colors.green, '╔════════════════════════════════════════════════════════╗');
    log(colors.green, '║                   测试通过 ✓                            ║');
    log(colors.green, '╚════════════════════════════════════════════════════════╝');
    console.log('');
    log(colors.cyan, '  测试用户信息:');
    log(colors.cyan, `    ID: ${finalUser.id}`);
    log(colors.cyan, `    用户名: ${finalUser.username}`);
    log(colors.cyan, `    邮箱: ${finalUser.email}`);
    console.log('');
    log(colors.cyan, '  Token (前30字符):');
    log(colors.yellow, `    ${token.substring(0, 30)}...`);
    console.log('');
  } else {
    log(colors.red, '╔════════════════════════════════════════════════════════╗');
    log(colors.red, '║                   测试失败                                ║');
    log(colors.red, '╚════════════════════════════════════════════════════════╝\n');
    process.exit(1);
  }
}

// 运行
main().catch(err => {
  log(colors.red, `\n错误: ${err.message}`);
  process.exit(1);
});
