/**
 * B站音频功能测试程序
 *
 * 功能演示：
 * 1. 搜索B站视频/音频
 * 2. 获取视频详细信息
 * 3. 获取音频流URL
 * 4. 代理封面/音频（解决防盗链）
 *
 * 使用方法：
 *   node tests/test-audio-manual.js
 *
 * ┌─────────────────────────────────────────────────────────────────┐
 * │                    测试程序与后端架构映射                      │
 * ├─────────────────────────────────────────────────────────────────┤
 * │  测试步骤        │  API端点             │  后端实现            │
 * ├─────────────────────────────────────────────────────────────────┤
 * │  1.健康检查      │  GET /health         │  index.js            │
 * │  2.搜索视频      │  GET /api/bilibili/search  │  bilibiliController.searchBilibili() │
 * │                 │                      │  └─> bilibiliService.searchBilibili()     │
 * │  3.视频信息      │  GET /api/bilibili/video/:bvid │ bilibiliController.getVideoInfo() │
 * │                 │                      │  └─> bilibiliService.getVideoInfo()       │
 * │  4.音频流        │  GET /api/bilibili/audio/:bvid │ bilibiliController.getAudioStream()│
 * │                 │                      │  └─> bilibiliService.getAudioStream()     │
 * │  5.代理封面      │  GET /api/bilibili/proxy/image │ bilibiliController.proxyImage() │
 * │  6.代理音频      │  GET /api/bilibili/proxy/audio │ bilibiliController.proxyAudioStream() │
 * └─────────────────────────────────────────────────────────────────┘
 */

const http = require('http');

// ========== 配置 ==========
const API_BASE = 'http://localhost:3000';

// ========== 颜色输出 ==========
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
  gray: '\x1b[90m'
};

function log(color, text) {
  console.log(`${color}${text}${colors.reset}`);
}

// ========== HTTP 请求封装 ==========
function request(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE);
    const options = {
      hostname: url.hostname,
      port: url.port || 3000,
      path: url.pathname + url.search,
      method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = body ? JSON.parse(body) : {};
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(response);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${response.message || '请求失败'}`));
          }
        } catch (e) {
          resolve({ success: false, message: '响应解析失败', raw: body });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// ========== 格式化工具 ==========
function formatDuration(seconds) {
  if (!seconds) return '未知';
  const min = Math.floor(seconds / 60);
  const sec = seconds % 60;
  return `${min}:${sec.toString().padStart(2, '0')}`;
}

function formatNumber(num) {
  if (!num) return '0';
  if (num >= 10000) {
    return (num / 10000).toFixed(1) + '万';
  }
  return num.toString();
}

// 截断长URL用于显示
function truncateUrl(url, maxLength = 50) {
  if (!url || url === '无') return url;
  if (url.length <= maxLength) return url;
  return url.substring(0, maxLength) + '...';
}

// 将B站URL转换为代理URL
// 对应: bilibiliController.proxyImage() / proxyAudioStream()
function toProxyUrl(originalUrl, type = 'image') {
  if (!originalUrl || originalUrl === '无') return '无';
  return `${API_BASE}/api/bilibili/proxy/${type}?url=${encodeURIComponent(originalUrl)}`;
}

// ========== 步骤1: 检查服务器 ==========
// API: GET /health
// 实现: index.js (Express健康检查端点)
async function step1_CheckServer() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 1: 检查服务器状态                            ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, '→ 正在连接服务器...');
  log(colors.gray, '   API: GET /health');
  log(colors.gray, '   实现: index.js (Express健康检查)\n');

  try {
    const response = await request('GET', '/health');

    log(colors.green, '✓ 服务器运行正常!\n');

    log(colors.blue, '═══════════════════════════════════════════════════════════');
    log(colors.blue, '  服务器信息:');
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    console.log(`  状态      : ${colors.green}${response.message}${colors.reset}`);
    console.log(`  时间戳    : ${response.timestamp}`);
    console.log(`  运行时长  : ${Math.floor(response.uptime)} 秒`);
    console.log('');

    return true;
  } catch (error) {
    log(colors.red, `✗ 无法连接到服务器: ${error.message}\n`);
    log(colors.yellow, '请确保后端服务正在运行:');
    log(colors.gray, '  cd listen-vision_api && node index.js\n');
    return false;
  }
}

// ========== 步骤2: 搜索B站视频 ==========
// API: GET /api/bilibili/search?keyword={keyword}&pageSize={pageSize}
// 路由: routes/bilibili.js -> router.get('/search', ...)
// 控制器: bilibiliController.searchBilibili()
// 服务层: bilibiliService.searchBilibili()
//   └─> getWbiKey() + signWbi() (WBI签名)
//   └─> httpGet() + 解析结果
async function step2_SearchBilibili(keyword) {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 2: 搜索B站视频                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, `→ 搜索关键词: ${colors.magenta}${keyword}${colors.reset}`);
  log(colors.gray, '   API: GET /api/bilibili/search');
  log(colors.gray, '   实现: bilibiliService.searchBilibili()');
  log(colors.gray, '   功能: WBI签名 + 搜索API + 结果解析\n');

  try {
    const response = await request('GET', `/api/bilibili/search?keyword=${encodeURIComponent(keyword)}&pageSize=5`);

    if (!response.success || !response.data?.videos) {
      log(colors.red, '✗ 搜索失败或无结果');
      return null;
    }

    const videos = response.data.videos;
    log(colors.green, `✓ 找到 ${response.data.total || videos.length} 个结果\n`);

    log(colors.blue, '═══════════════════════════════════════════════════════════');
    log(colors.blue, '  搜索结果:');
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    console.log('');

    videos.forEach((video, index) => {
      console.log(`${colors.green}[${index + 1}]${colors.reset} ${video.title}`);
      console.log(`     BVID     : ${colors.cyan}${video.bvid}${colors.reset}`);
      console.log(`     UP主     : ${video.author || '未知'}`);
      console.log(`     时长     : ${video.duration || '未知'}`);
      console.log(`     播放     : ${formatNumber(video.play)} 次`);
      console.log(`     封面     : ${colors.gray}${truncateUrl(video.cover)}${colors.reset}`);
      console.log('');
    });

    return videos;  // 返回搜索结果供后续步骤使用
  } catch (error) {
    log(colors.red, `✗ 搜索失败: ${error.message}`);
    return null;
  }
}

// ========== 步骤3: 获取视频详细信息 ==========
// API: GET /api/bilibili/video/:bvid
// 路由: routes/bilibili.js -> router.get('/video/:bvid', ...)
// 控制器: bilibiliController.getVideoInfo()
// 服务层: bilibiliService.getVideoInfo()
//   └─> httpGet('https://api.bilibili.com/x/web-interface/view?bvid=...')
//   └─> 解析: title, pic, owner, stat, cid 等
async function step3_GetVideoInfo(bvid) {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 3: 获取视频详细信息                          ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, `→ 获取视频信息: ${colors.cyan}${bvid}${colors.reset}`);
  log(colors.gray, '   API: GET /api/bilibili/video/:bvid');
  log(colors.gray, '   实现: bilibiliService.getVideoInfo()');
  log(colors.gray, '   功能: 调用B站视频信息API，解析 title/cid/stat 等字段\n');

  try {
    const response = await request('GET', `/api/bilibili/video/${bvid}`);

    if (!response.success || !response.data) {
      log(colors.red, '✗ 获取视频信息失败');
      return null;
    }

    const video = response.data;
    log(colors.green, '✓ 视频信息获取成功!\n');

    log(colors.blue, '═══════════════════════════════════════════════════════════');
    log(colors.blue, '  视频详细信息:');
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    console.log('');
    console.log(`  标题      : ${colors.magenta}${video.title}${colors.reset}`);
    console.log(`  BVID      : ${colors.cyan}${video.bvid}${colors.reset}`);
    console.log(`  CID       : ${video.cid || 'N/A'} ${colors.gray}(用于获取音频流)${colors.reset}`);
    console.log('');
    console.log(`  UP主信息  :`);
    console.log(`    名称    : ${video.owner?.name || '未知'}`);
    console.log(`    MID      : ${video.owner?.mid || 'N/A'}`);
    console.log(`    Face     : ${colors.gray}${truncateUrl(video.owner?.face)}${colors.reset}`);
    console.log('');
    console.log(`  视频数据  :`);
    console.log(`    时长    : ${formatDuration(video.duration)}`);
    console.log(`    发布时间: ${video.pubdate ? new Date(video.pubdate * 1000).toLocaleString('zh-CN') : '未知'}`);
    console.log(`    简介    : ${video.desc?.substring(0, 100) || '无'}${video.desc?.length > 100 ? '...' : ''}`);
    console.log('');
    console.log(`  封面      : ${colors.gray}${truncateUrl(video.pic)}${colors.reset}`);
    console.log(`  封面代理  : ${colors.green}${toProxyUrl(video.pic)}${colors.reset}`);
    console.log(`             ${colors.gray}(解决B站防盗链)${colors.reset}`);
    console.log('');
    console.log(`  统计数据  :`);
    console.log(`    播放    : ${formatNumber(video.stat?.view)} 次`);
    console.log(`    点赞    : ${formatNumber(video.stat?.like)}`);
    console.log(`    投币    : ${formatNumber(video.stat?.coin)}`);
    console.log(`    收藏    : ${formatNumber(video.stat?.favorite)}`);
    console.log(`    分享    : ${formatNumber(video.stat?.share)}`);
    console.log(`    弹幕    : ${formatNumber(video.stat?.danmaku)}`);
    console.log('');

    return video;
  } catch (error) {
    log(colors.red, `✗ 获取视频信息失败: ${error.message}`);
    return null;
  }
}

// ========== 步骤4: 获取音频流 ==========
// API: GET /api/bilibili/audio/:bvid
// 路由: routes/bilibili.js -> router.get('/audio/:bvid', ...)
// 控制器: bilibiliController.getAudioStream()
// 服务层: bilibiliService.getAudioStream()
//   └─> getVideoInfo() (如果cid为空，先获取视频信息得到cid)
//   └─> httpGet('https://api.bilibili.com/x/player/playurl?bvid=...&cid=...&fnval=16')
//   └─> 解析 DASH 音频流，选择最高质量
async function step4_GetAudioStream(bvid, title) {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           步骤 4: 获取音频流                                ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  log(colors.yellow, `→ 获取音频流: ${colors.cyan}${bvid}${colors.reset}`);
  log(colors.gray, '   API: GET /api/bilibili/audio/:bvid');
  log(colors.gray, '   实现: bilibiliService.getAudioStream()');
  log(colors.gray, '   功能: fnval=16(仅音频) + DASH流解析 + 选择最高质量\n');

  try {
    const response = await request('GET', `/api/bilibili/audio/${bvid}`);

    if (!response.success || !response.data) {
      log(colors.red, '✗ 获取音频流失败');
      return null;
    }

    const audio = response.data;
    log(colors.green, '✓ 音频流获取成功!\n');

    const audioUrl = audio.baseUrl || audio.url;

    log(colors.blue, '═══════════════════════════════════════════════════════════');
    log(colors.blue, '  音频流信息:');
    log(colors.blue, '═══════════════════════════════════════════════════════════');
    console.log('');
    console.log(`  标题      : ${colors.magenta}${audio.title || title}${colors.reset}`);
    console.log(`  BVID      : ${colors.cyan}${audio.bvid}${colors.reset}`);
    console.log('');
    console.log(`  音频 URL  :`);
    console.log(`    ${colors.green}${truncateUrl(audioUrl, 60)}${colors.reset}`);
    console.log(`    ${colors.gray}(完整URL见下方使用提示)${colors.reset}`);
    console.log('');
    console.log(`  音频参数  :`);
    console.log(`    带宽    : ${audio.bandwidth ? (audio.bandwidth / 1000).toFixed(0) + ' kbps' : 'N/A'}`);
    console.log(`    编码    : ${audio.mimeType || audio.codecs || 'N/A'}`);
    console.log(`    时长    : ${formatDuration(audio.duration)}`);
    console.log('');

    const proxyAudioUrl = toProxyUrl(audioUrl, 'audio');

    log(colors.yellow, '═══════════════════════════════════════════════════════════');
    log(colors.yellow, '  💡 使用提示:');
    log(colors.yellow, '═══════════════════════════════════════════════════════════');
    console.log('  1. 使用代理URL（推荐，解决防盗链）:');
    console.log(`     API: GET /api/bilibili/proxy/audio?url=<音频URL>`);
    console.log(`     ${colors.green}浏览器打开: ${proxyAudioUrl}${colors.reset}`);
    console.log(`     ${colors.gray}curl -o audio.m4s "${proxyAudioUrl}"${colors.reset}`);
    console.log('');
    console.log('  2. 原始URL（需要设置Referer，可能403）:');
    console.log(`     ${colors.cyan}${truncateUrl(audioUrl, 60)}${colors.reset}`);
    console.log('');
    console.log('  3. 在 VLC、ffplay 等播放器中打开代理URL');
    console.log('');

    return audio;
  } catch (error) {
    log(colors.red, `✗ 获取音频流失败: ${error.message}`);
    return null;
  }
}

// ========== 交互式选择 ==========
async function selectVideo(videos) {
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(`\n${colors.yellow}选择一个视频 (输入序号 1-${videos.length}, 或 0 跳过): ${colors.reset}`, (answer) => {
      rl.close();
      const index = parseInt(answer.trim()) - 1;
      if (index >= 0 && index < videos.length) {
        resolve(videos[index]);
      } else {
        resolve(null);
      }
    });
  });
}

// ========== 主函数 ==========
async function main() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '║           B站音频功能测试程序                                ║');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝');
  log(colors.gray, '\n后端架构: routes/bilibili.js -> bilibiliController.js -> bilibiliService.js\n');

  // 步骤1: 检查服务器
  const serverOk = await step1_CheckServer();
  if (!serverOk) {
    process.exit(1);
  }

  // 默认搜索关键词
  const defaultKeyword = '音乐';
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const keyword = await new Promise((resolve) => {
    rl.question(`\n${colors.yellow}请输入搜索关键词 (直接回车使用"${defaultKeyword}"): ${colors.reset}`, (answer) => {
      rl.close();
      resolve(answer.trim() || defaultKeyword);
    });
  });

  // 步骤2: 搜索
  const videos = await step2_SearchBilibili(keyword);
  if (!videos || videos.length === 0) {
    log(colors.red, '\n✗ 没有找到视频，测试结束');
    process.exit(1);
  }

  // 选择视频
  const selectedVideo = await selectVideo(videos);
  if (!selectedVideo) {
    log(colors.yellow, '\n⚠️  已跳过详细信息和音频流测试');
    process.exit(0);
  }

  console.log('\n');

  // 步骤3: 获取视频详细信息
  const videoInfo = await step3_GetVideoInfo(selectedVideo.bvid);
  if (!videoInfo) {
    log(colors.red, '\n✗ 获取视频信息失败，测试结束');
    process.exit(1);
  }

  // 步骤4: 获取音频流
  const audioStream = await step4_GetAudioStream(selectedVideo.bvid, selectedVideo.title);
  if (!audioStream) {
    log(colors.red, '\n✗ 获取音频流失败，测试结束');
    process.exit(1);
  }

  // 测试完成
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '║           ✅ 所有测试完成!                                   ║');
  log(colors.cyan, '║                                                              ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');
}

// 运行
main().catch((error) => {
  log(colors.red, `\n✗ 程序出错: ${error.message}`);
  console.error(error);
  process.exit(1);
});
