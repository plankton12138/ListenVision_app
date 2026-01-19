/**
 * Phase 2 功能交互式测试程序
 *
 * 测试内容：
 * - 歌单管理 (创建/获取/更新/删除)
 * - 收藏功能 (添加/移除/检查)
 * - 播放历史 (记录/获取/删除)
 * - 播放队列 (保存/获取)
 * - 推荐内容 (热门/榜单/分区)
 */

const readline = require('readline');

// API 基础配置
const BASE_URL = 'http://127.0.0.1:3000/api';

// 状态存储
let authToken = null;
let currentPlaylistId = null;
let testBvid = 'BV1xx411c7mD'; // 测试用 BV 号

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

function log(color, text) {
  console.log(`${color}${text}${colors.reset}`);
}

// 创建 readline 接口
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// 通用请求函数
async function request(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  };

  if (authToken && options.auth !== false) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers
    });

    const data = await response.json();
    return { status: response.status, data };
  } catch (error) {
    return { error: error.message };
  }
}

// 显示带颜色的响应结果
function showResponse(result) {
  if (result.error) {
    log(colors.red, `  ✗ 错误: ${result.error}`);
    return;
  }

  if (result.status >= 200 && result.status < 300) {
    log(colors.green, `  ✓ 成功 (${result.status})`);
  } else {
    log(colors.yellow, `  ⚠ 状态码: ${result.status}`);
  }

  // 显示响应数据
  const data = result.data;
  if (!data) return;

  // 显示消息
  if (data.message) {
    console.log(`  ${colors.blue}消息:${colors.reset} ${data.message}`);
  }

  // 显示数据内容
  const items = data.data || data;
  if (Array.isArray(items)) {
    console.log(`  ${colors.blue}数量:${colors.reset} ${items.length} 条`);
    if (items.length > 0) {
      console.log(`  ${colors.blue}数据预览:${colors.reset}`);
      items.slice(0, 3).forEach((item, i) => {
        const preview = JSON.stringify(item).substring(0, 100);
        console.log(`    [${i + 1}] ${preview}${preview.length >= 100 ? '...' : ''}`);
      });
      if (items.length > 3) {
        console.log(`    ... 还有 ${items.length - 3} 条`);
      }
    }
  } else if (typeof items === 'object') {
    console.log(`  ${colors.blue}数据:${colors.reset}`);
    const preview = JSON.stringify(items, null, 2).split('\n').slice(0, 10).join('\n');
    console.log(preview);
    if (JSON.stringify(items, null, 2).split('\n').length > 10) {
      console.log('    ...');
    }
  }
}

// ==================== 认证功能 ====================

async function login() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║                        用户登录                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  const username = await question('用户名: ');
  const password = await question('密码: ');

  log(colors.yellow, '\n→ 正在登录...\n');

  const result = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username, password })
  });

  // API 返回格式: { success: true, message: "...", data: { token: "...", user: {...} } }
  const data = result.data?.data || result.data;
  if (data && data.token) {
    authToken = data.token;
    log(colors.green, `✓ 登录成功! 用户: ${data.user?.username || username}`);
    log(colors.blue, `  Token: ${authToken.substring(0, 30)}...\n`);
  } else {
    log(colors.red, '✗ 登录失败\n');
    showResponse(result);
  }
}

async function register() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║                        用户注册                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  const username = await question('用户名: ');
  const email = await question('邮箱: ');
  const password = await question('密码: ');

  log(colors.yellow, '\n→ 正在注册...\n');

  const result = await request('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ username, email, password })
  });

  if (result.data && result.data.data && result.data.data.token) {
    authToken = result.data.data.token;
    log(colors.green, `✓ 注册成功! Token: ${authToken.substring(0, 20)}...\n`);
  } else {
    log(colors.red, '✗ 注册失败\n');
    showResponse(result);
  }
}

// ==================== 歌单功能 ====================

async function getPlaylists() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取用户歌单列表');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const result = await request('/playlists');
  showResponse(result);

  // 保存第一个用户歌单ID
  if (result.data && result.data.data && result.data.data.length > 0) {
    const userPlaylist = result.data.data.find(p => p.type === 'user');
    if (userPlaylist) {
      currentPlaylistId = userPlaylist.id;
      log(colors.blue, `\n  → 已记住歌单ID: ${currentPlaylistId} (${userPlaylist.name})`);
    }
  }
}

async function createPlaylist() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  创建新歌单');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const name = await question('歌单名称: ');
  const description = await question('描述 (可选，直接回车跳过): ');

  log(colors.yellow, '\n→ 正在创建...\n');

  const body = { name };
  if (description) body.description = description;

  const result = await request('/playlists', {
    method: 'POST',
    body: JSON.stringify(body)
  });
  showResponse(result);

  if (result.data && result.data.data && result.data.data.id) {
    currentPlaylistId = result.data.data.id;
    log(colors.blue, `\n  → 已记住歌单ID: ${currentPlaylistId}`);
  }
}

async function getPlaylistDetail() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取歌单详情');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const id = await question(`歌单ID${currentPlaylistId ? ` (直接回车使用 ${currentPlaylistId})`: `: `}`);

  const playlistId = id || currentPlaylistId;
  if (!playlistId) {
    log(colors.red, '  ✗ 请输入歌单ID');
    return;
  }

  const result = await request(`/playlists/${playlistId}`);
  showResponse(result);
}

async function updatePlaylist() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  更新歌单信息');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const id = await question(`歌单ID${currentPlaylistId ? ` (直接回车使用 ${currentPlaylistId})`: `: `}`);
  const newName = await question('新名称 (直接回车不修改): ');
  const newDesc = await question('新描述 (直接回车不修改): ');

  const playlistId = id || currentPlaylistId;
  if (!playlistId) {
    log(colors.red, '  ✗ 请输入歌单ID');
    return;
  }

  const body = {};
  if (newName) body.name = newName;
  if (newDesc) body.description = newDesc;

  if (Object.keys(body).length === 0) {
    log(colors.yellow, '  ⚠ 没有修改内容');
    return;
  }

  log(colors.yellow, '\n→ 正在更新...\n');

  const result = await request(`/playlists/${playlistId}`, {
    method: 'PUT',
    body: JSON.stringify(body)
  });
  showResponse(result);
}

async function deletePlaylist() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  删除歌单');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const id = await question(`歌单ID${currentPlaylistId ? ` (直接回车使用 ${currentPlaylistId})`: `: `}`);

  const playlistId = id || currentPlaylistId;
  if (!playlistId) {
    log(colors.red, '  ✗ 请输入歌单ID');
    return;
  }

  const confirm = await question(`确认删除歌单 ${playlistId}? (y/n): `);
  if (confirm.toLowerCase() !== 'y') {
    log(colors.yellow, '  ⚠ 已取消');
    return;
  }

  log(colors.yellow, '\n→ 正在删除...\n');

  const result = await request(`/playlists/${playlistId}`, {
    method: 'DELETE'
  });
  showResponse(result);

  if (result.data && result.data.success) {
    if (currentPlaylistId === playlistId) {
      currentPlaylistId = null;
    }
  }
}

async function addItemToPlaylist() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  添加音频到歌单');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const id = await question(`歌单ID${currentPlaylistId ? ` (直接回车使用 ${currentPlaylistId})`: `: `}`);
  const bvid = await question(`BV号 (直接回车使用 ${testBvid}): `);
  const title = await question('标题 (可选): ');
  const artist = await question('UP主 (可选): ');

  const playlistId = id || currentPlaylistId;
  if (!playlistId) {
    log(colors.red, '  ✗ 请输入歌单ID');
    return;
  }

  log(colors.yellow, '\n→ 正在添加...\n');

  const body = { bvid: bvid || testBvid };
  if (title) body.title = title;
  if (artist) body.artist = artist;

  const result = await request(`/playlists/${playlistId}/items`, {
    method: 'POST',
    body: JSON.stringify(body)
  });
  showResponse(result);
}

async function removeItemFromPlaylist() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  从歌单移除音频');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const id = await question(`歌单ID${currentPlaylistId ? ` (直接回车使用 ${currentPlaylistId})`: `: `}`);
  const bvid = await question(`BV号: `);

  const playlistId = id || currentPlaylistId;
  if (!playlistId) {
    log(colors.red, '  ✗ 请输入歌单ID');
    return;
  }
  if (!bvid) {
    log(colors.red, '  ✗ 请输入BV号');
    return;
  }

  log(colors.yellow, '\n→ 正在移除...\n');

  const result = await request(`/playlists/${playlistId}/items/${bvid}`, {
    method: 'DELETE'
  });
  showResponse(result);
}

// ==================== 收藏功能 ====================

async function toggleFavorite() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  切换收藏状态');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const bvid = await question(`BV号 (直接回车使用 ${testBvid}): `);
  const title = await question('标题 (可选): ');
  const artist = await question('UP主 (可选): ');

  log(colors.yellow, '\n→ 正在切换收藏...\n');

  const body = { bvid: bvid || testBvid };
  if (title) body.title = title;
  if (artist) body.artist = artist;

  const result = await request('/playlists/favorites/toggle', {
    method: 'POST',
    body: JSON.stringify(body)
  });
  showResponse(result);
}

async function checkFavorite() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  检查是否已收藏');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const bvid = await question(`BV号 (直接回车使用 ${testBvid}): `);

  const result = await request(`/playlists/favorites/check/${bvid || testBvid}`);
  showResponse(result);
}

async function getFavorites() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取收藏列表');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const result = await request('/playlists/favorites');
  showResponse(result);
}

// ==================== 播放队列 ====================

async function saveNowPlaying() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  保存播放队列');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  log(colors.yellow, '→ 使用测试数据: 3个音频项\n');

  const items = [
    { bvid: 'BV1xx411c7mD', title: '测试音频1', artist: 'UP主1', duration: 180 },
    { bvid: 'BV1yy411c7mE', title: '测试音频2', artist: 'UP主2', duration: 240 },
    { bvid: 'BV1zz411c7mF', title: '测试音频3', artist: 'UP主3', duration: 200 }
  ];

  const result = await request('/playlists/now-playing', {
    method: 'POST',
    body: JSON.stringify({ items })
  });
  showResponse(result);
}

async function getNowPlaying() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取播放队列');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const result = await request('/playlists/now-playing');
  showResponse(result);
}

// ==================== 播放历史 ====================

async function recordPlay() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  记录播放');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const bvid = await question(`BV号 (直接回车使用 ${testBvid}): `);
  const title = await question('标题 (可选): ');
  const artist = await question('UP主 (可选): ');
  const progressInput = await question('播放进度/秒 (直接回车使用0): ');

  log(colors.yellow, '\n→ 正在记录...\n');

  const body = { bvid: bvid || testBvid };
  if (title) body.title = title;
  if (artist) body.artist = artist;
  if (progressInput) body.progress = parseInt(progressInput);

  const result = await request('/history', {
    method: 'POST',
    body: JSON.stringify(body)
  });
  showResponse(result);
}

async function getHistory() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取播放历史');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const limit = await question('返回数量 (直接回车使用10): ');

  const query = limit ? `?limit=${limit}` : '';
  const result = await request(`/history${query}`);
  showResponse(result);
}

async function getHistoryStats() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取播放统计');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const result = await request('/history/stats');
  showResponse(result);
}

async function clearHistory() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  清空播放历史');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const confirm = await question('确认清空所有播放历史? (y/n): ');
  if (confirm.toLowerCase() !== 'y') {
    log(colors.yellow, '  ⚠ 已取消');
    return;
  }

  log(colors.yellow, '\n→ 正在清空...\n');

  const result = await request('/history', {
    method: 'DELETE'
  });
  showResponse(result);
}

async function removeHistoryItem() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  删除指定播放记录');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const bvid = await question(`BV号: `);

  if (!bvid) {
    log(colors.red, '  ✗ 请输入BV号');
    return;
  }

  log(colors.yellow, '\n→ 正在删除...\n');

  const result = await request(`/history/${bvid}`, {
    method: 'DELETE'
  });
  showResponse(result);
}

// ==================== 推荐内容 ====================

async function getHotPlaylists() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取热门歌单');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const page = await question('页码 (直接回车使用1): ');

  const query = page && page !== '1' ? `?page=${page}` : '';
  const result = await request(`/recommendations/hot-playlists${query}`);
  showResponse(result);
}

async function getHotRank() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取热歌榜单');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const page = await question('页码 (直接回车使用1): ');

  const query = page && page !== '1' ? `?page=${page}` : '';
  const result = await request(`/recommendations/rank${query}`);
  showResponse(result);
}

async function getPersonalized() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取个性化推荐');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const limit = await question('返回数量 (直接回车使用20): ');

  const query = limit && limit !== '20' ? `?limit=${limit}` : '';
  const result = await request(`/recommendations/personalized${query}`);
  showResponse(result);
}

async function getCategoryRecommendation() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取分区推荐');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  log(colors.yellow, '  常用分区ID: 3=音乐, 1=动画, 129=舞蹈, 4=游戏\n');

  const tid = await question('分区ID (直接回车使用3-音乐): ');
  const page = await question('页码 (直接回车使用1): ');

  const params = [];
  if (page && page !== '1') params.push(`page=${page}`);
  const query = params.length ? `?${params.join('&')}` : '';

  const result = await request(`/recommendations/category/${tid || 3}${query}`);
  showResponse(result);
}

async function getMusicRecommendation() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取音乐区综合推荐');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const result = await request('/recommendations/music');
  showResponse(result);
}

async function getCategories() {
  log(colors.cyan, '\n─────────────────────────────────────────────────────────────');
  log(colors.cyan, '  获取可用分区列表');
  log(colors.cyan, '─────────────────────────────────────────────────────────────\n');

  const result = await request('/recommendations/categories');
  showResponse(result);
}

// ==================== 主菜单 ====================

function showMainMenu() {
  console.log('\n');
  log(colors.cyan, '╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           Phase 2 功能测试 - 主菜单                        ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝');
  console.log('');
  log(colors.yellow, `  当前状态: ${authToken ? colors.green + '已登录' + colors.yellow : colors.red + '未登录' + colors.yellow}`);
  if (currentPlaylistId) {
    log(colors.blue, `  当前歌单ID: ${currentPlaylistId}`);
  }
  console.log('');
  log(colors.green, '  【认证】');
  console.log('    1. 登录');
  console.log('    2. 注册');
  console.log('');
  log(colors.blue, '  【歌单管理】');
  console.log('    11. 获取歌单列表');
  console.log('    12. 创建新歌单');
  console.log('    13. 获取歌单详情');
  console.log('    14. 更新歌单');
  console.log('    15. 删除歌单');
  console.log('    16. 添加音频到歌单');
  console.log('    17. 从歌单移除音频');
  console.log('');
  log(colors.magenta, '  【收藏功能】');
  console.log('    21. 切换收藏');
  console.log('    22. 检查收藏状态');
  console.log('    23. 获取收藏列表');
  console.log('');
  log(colors.cyan, '  【播放队列】');
  console.log('    31. 保存播放队列');
  console.log('    32. 获取播放队列');
  console.log('');
  log(colors.yellow, '  【播放历史】');
  console.log('    41. 记录播放');
  console.log('    42. 获取播放历史');
  console.log('    43. 获取播放统计');
  console.log('    44. 清空播放历史');
  console.log('    45. 删除指定记录');
  console.log('');
  log(colors.green, '  【推荐内容】');
  console.log('    51. 热门歌单');
  console.log('    52. 热歌榜单');
  console.log('    53. 个性化推荐');
  console.log('    54. 分区推荐');
  console.log('    55. 音乐区综合推荐');
  console.log('    56. 获取分区列表');
  console.log('');
  log(colors.red, '    0. 退出');
  console.log('');
}

function question(prompt) {
  return new Promise(resolve => {
    rl.question(`${colors.cyan}${prompt}${colors.reset}`, resolve);
  });
}

async function handleChoice(choice) {
  switch (choice) {
    // 认证
    case '1': await login(); break;
    case '2': await register(); break;
    // 歌单管理
    case '11': await getPlaylists(); break;
    case '12': await createPlaylist(); break;
    case '13': await getPlaylistDetail(); break;
    case '14': await updatePlaylist(); break;
    case '15': await deletePlaylist(); break;
    case '16': await addItemToPlaylist(); break;
    case '17': await removeItemFromPlaylist(); break;
    // 收藏功能
    case '21': await toggleFavorite(); break;
    case '22': await checkFavorite(); break;
    case '23': await getFavorites(); break;
    // 播放队列
    case '31': await saveNowPlaying(); break;
    case '32': await getNowPlaying(); break;
    // 播放历史
    case '41': await recordPlay(); break;
    case '42': await getHistory(); break;
    case '43': await getHistoryStats(); break;
    case '44': await clearHistory(); break;
    case '45': await removeHistoryItem(); break;
    // 推荐内容
    case '51': await getHotPlaylists(); break;
    case '52': await getHotRank(); break;
    case '53': await getPersonalized(); break;
    case '54': await getCategoryRecommendation(); break;
    case '55': await getMusicRecommendation(); break;
    case '56': await getCategories(); break;
    // 退出
    case '0':
      rl.close();
      process.exit(0);
    default:
      log(colors.red, '\n  ✗ 无效选择\n');
  }
}

async function main() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '║           Phase 2 功能交互式测试程序                          ║');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '║  测试 API 端点:                                               ║');
  log(colors.cyan, '║  - 歌单管理 (/api/playlists/*)                               ║');
  log(colors.cyan, '║  - 收藏功能 (/api/playlists/favorites/*)                     ║');
  log(colors.cyan, '║  - 播放队列 (/api/playlists/now-playing)                     ║');
  log(colors.cyan, '║  - 播放历史 (/api/history/*)                                 ║');
  log(colors.cyan, '║  - 推荐内容 (/api/recommendations/*)                         ║');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝');

  while (true) {
    showMainMenu();
    const choice = await question('请选择功能: ');
    console.log('');
    await handleChoice(choice);
  }
}

// 启动程序
main();
