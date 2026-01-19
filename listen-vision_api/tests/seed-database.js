/**
 * 数据库测试数据填充脚本
 *
 * 用途: 为开发和测试提供初始数据
 * 运行: node tests/seed-database.js
 */

const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs'); // 使用 bcryptjs 而不是 bcrypt（纯 JS 实现）
const path = require('path');
const fs = require('fs');

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

// 数据库路径
const dbPath = path.join(__dirname, '../data/listenvision.db');

// 测试用户数据
const testUsers = [
  { username: 'testuser', email: 'test@example.com', password: 'password123' },
  { username: 'musicfan', email: 'music@example.com', password: 'music456' },
  { username: 'admin', email: 'admin@example.com', password: 'admin888' }
];

// 测试音频数据 (模拟B站音频)
const testAudios = [
  {
    bvid: 'BV1xx411c7mD',
    title: '【治愈系】温柔的钢琴曲，适合睡前聆听',
    artist: '音乐UP主A',
    duration: 245,
    cover: 'https://example.com/covers/cover1.jpg'
  },
  {
    bvid: 'BV1yy411c7mE',
    title: '流行音乐精选 Top 50',
    artist: '音乐推荐官',
    duration: 3200,
    cover: 'https://example.com/covers/cover2.jpg'
  },
  {
    bvid: 'BV1zz411c7mF',
    title: '经典老歌翻唱 - 怀旧系列',
    artist: '怀旧音乐人',
    duration: 180,
    cover: 'https://example.com/covers/cover3.jpg'
  },
  {
    bvid: 'BV1aa411c7mG',
    title: '轻音乐合集 - 工作学习背景音',
    artist: '专注力音乐',
    duration: 5400,
    cover: 'https://example.com/covers/cover4.jpg'
  },
  {
    bvid: 'BV1bb411c7mH',
    title: '电子音乐 EDM Mix 2024',
    artist: 'DJ Max',
    duration: 420,
    cover: 'https://example.com/covers/cover5.jpg'
  },
  {
    bvid: 'BV1cc411c7mI',
    title: '古风音乐精选 - 传统文化之美',
    artist: '古风音乐社',
    duration: 380,
    cover: 'https://example.com/covers/cover6.jpg'
  },
  {
    bvid: 'BV1dd411c7mJ',
    title: '动漫主题曲合集 唤起童年回忆',
    artist: 'ACG音乐屋',
    duration: 7200,
    cover: 'https://example.com/covers/cover7.jpg'
  },
  {
    bvid: 'BV1ee411c7mK',
    title: '民谣吉他弹唱 安静的午后',
    artist: '吉他手小王',
    duration: 210,
    cover: 'https://example.com/covers/cover8.jpg'
  }
];

// 测试歌单数据
const testPlaylists = [
  { name: '我喜欢的音乐', description: '收藏的优质音乐' },
  { name: '工作学习', description: '适合专注的背景音乐' },
  { name: '运动健身', description: '节奏感强的运动音乐' },
  { name: '睡前助眠', description: '安静舒缓的助眠音乐' },
  { name: '怀旧经典', description: '经典老歌收藏' },
  { name: '二次元', description: '动漫游戏相关音乐' }
];

// 测试播放历史
const testHistory = [
  { bvid: 'BV1xx411c7mD', progress: 120 },
  { bvid: 'BV1yy411c7mE', progress: 45 },
  { bvid: 'BV1zz411c7mF', progress: 180 },
  { bvid: 'BV1aa411c7mG', progress: 3200 },
  { bvid: 'BV1bb411c7mH', progress: 0 }
];

async function main() {
  log(colors.cyan, '\n╔════════════════════════════════════════════════════════════╗');
  log(colors.cyan, '║           数据库测试数据填充脚本                            ║');
  log(colors.cyan, '╚════════════════════════════════════════════════════════════╝\n');

  // 检查数据库文件是否存在
  if (!fs.existsSync(dbPath)) {
    log(colors.red, '✗ 数据库文件不存在，请先启动服务器创建数据库');
    log(colors.yellow, '  运行: node index.js');
    process.exit(1);
  }

  // 打开数据库
  log(colors.yellow, '→ 正在打开数据库...');
  const db = new Database(dbPath);
  log(colors.green, '✓ 数据库已打开\n');

  try {
    // ==================== 步骤1: 清理旧数据 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 1: 清理旧测试数据');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const confirmClean = await question('是否清理旧数据? (y/n): ');
    if (confirmClean.toLowerCase() === 'y') {
      db.prepare('DELETE FROM playlist_items').run();
      db.prepare('DELETE FROM playlists').run();
      db.prepare('DELETE FROM play_history').run();
      db.prepare('DELETE FROM users WHERE username IN (?,?,?)').bind(...testUsers.map(u => u.username)).run();
      log(colors.green, '✓ 旧数据已清理\n');
    } else {
      log(colors.yellow, '⚠ 跳过清理\n');
    }

    // ==================== 步骤2: 创建测试用户 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 2: 创建测试用户');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const userInsert = db.prepare(`
      INSERT INTO users (username, email, password)
      VALUES (?, ?, ?)
    `);

    const userIds = [];

    for (const user of testUsers) {
      try {
        const hashedPassword = await bcrypt.hash(user.password, 10);
        const result = userInsert.run(user.username, user.email, hashedPassword);
        userIds.push(result.lastInsertRowid);
        log(colors.green, `  ✓ 创建用户: ${user.username} (ID: ${result.lastInsertRowid})`);
      } catch (error) {
        if (error.message.includes('UNIQUE')) {
          log(colors.yellow, `  ⚠ 用户已存在: ${user.username}`);
          // 获取已存在用户的ID
          const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(user.username);
          userIds.push(existing.id);
        } else {
          log(colors.red, `  ✗ 创建用户失败: ${user.username} - ${error.message}`);
        }
      }
    }
    console.log('');

    // 使用第一个测试用户
    const testUserId = userIds[0];
    log(colors.blue, `  → 使用测试用户ID: ${testUserId}\n`);

    // ==================== 步骤3: 创建系统歌单 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 3: 创建系统歌单 (我喜欢、正在播放)');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const playlistInsert = db.prepare(`
      INSERT INTO playlists (user_id, name, description, type, system_type, is_public, play_count)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    // 创建"我喜欢"系统歌单
    try {
      const favoritesResult = playlistInsert.run(
        testUserId, '我喜欢', '我收藏的优质音乐', 'system', 'favorites', 0, 0
      );
      log(colors.green, `  ✓ 创建系统歌单: 我喜欢 (ID: ${favoritesResult.lastInsertRowid})`);
      const favoritesId = favoritesResult.lastInsertRowid;
    } catch (error) {
      const existing = db.prepare('SELECT id FROM playlists WHERE user_id = ? AND system_type = ?').get(testUserId, 'favorites');
      log(colors.yellow, `  ⚠ 我喜欢歌单已存在 (ID: ${existing.id})`);
      var favoritesId = existing.id;
    }

    // 创建"正在播放"系统歌单
    try {
      const nowPlayingResult = playlistInsert.run(
        testUserId, '正在播放', '当前播放队列', 'system', 'now_playing', 0, 0
      );
      log(colors.green, `  ✓ 创建系统歌单: 正在播放 (ID: ${nowPlayingResult.lastInsertRowid})`);
    } catch (error) {
      const existing = db.prepare('SELECT id FROM playlists WHERE user_id = ? AND system_type = ?').get(testUserId, 'now_playing');
      log(colors.yellow, `  ⚠ 正在播放歌单已存在 (ID: ${existing.id})`);
    }
    console.log('');

    // ==================== 步骤4: 创建用户歌单 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 4: 创建用户歌单');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const userPlaylistIds = [];

    for (const playlist of testPlaylists) {
      try {
        const result = playlistInsert.run(
          testUserId, playlist.name, playlist.description, 'user', null, 0, 0
        );
        userPlaylistIds.push(result.lastInsertRowid);
        log(colors.green, `  ✓ 创建歌单: ${playlist.name} (ID: ${result.lastInsertRowid})`);
      } catch (error) {
        if (error.message.includes('UNIQUE')) {
          log(colors.yellow, `  ⚠ 歌单已存在: ${playlist.name}`);
        } else {
          log(colors.red, `  ✗ 创建歌单失败: ${playlist.name} - ${error.message}`);
        }
      }
    }
    console.log('');

    // ==================== 步骤5: 添加音频到歌单 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 5: 添加音频到歌单');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const itemInsert = db.prepare(`
      INSERT INTO playlist_items (playlist_id, bvid, title, artist, duration, cover_url, position)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    // "我喜欢" 歌单添加前5首
    log(colors.blue, '  → 添加到"我喜欢":');
    for (let i = 0; i < 5; i++) {
      const audio = testAudios[i];
      try {
        itemInsert.run(favoritesId, audio.bvid, audio.title, audio.artist, audio.duration, audio.cover, i);
        log(colors.green, `    ✓ ${audio.title.substring(0, 20)}...`);
      } catch (error) {
        log(colors.yellow, `    ⚠ ${audio.bvid} 可能已存在`);
      }
    }
    console.log('');

    // "工作学习" 添加轻音乐
    const workPlaylistId = userPlaylistIds[0]; // 工作学习
    if (workPlaylistId) {
      log(colors.blue, '  → 添加到"工作学习":');
      const workAudios = [0, 3, 7]; // 索引
      for (let i = 0; i < workAudios.length; i++) {
        const audio = testAudios[workAudios[i]];
        try {
          itemInsert.run(workPlaylistId, audio.bvid, audio.title, audio.artist, audio.duration, audio.cover, i);
          log(colors.green, `    ✓ ${audio.title.substring(0, 20)}...`);
        } catch (error) {
          log(colors.yellow, `    ⚠ ${audio.bvid} 可能已存在`);
        }
      }
      console.log('');
    }

    // "睡前助眠" 添加舒缓音乐
    const sleepPlaylistId = userPlaylistIds[3]; // 睡前助眠
    if (sleepPlaylistId) {
      log(colors.blue, '  → 添加到"睡前助眠":');
      const sleepAudios = [0, 2, 7]; // 索引
      for (let i = 0; i < sleepAudios.length; i++) {
        const audio = testAudios[sleepAudios[i]];
        try {
          itemInsert.run(sleepPlaylistId, audio.bvid, audio.title, audio.artist, audio.duration, audio.cover, i);
          log(colors.green, `    ✓ ${audio.title.substring(0, 20)}...`);
        } catch (error) {
          log(colors.yellow, `    ⚠ ${audio.bvid} 可能已存在`);
        }
      }
      console.log('');
    }

    // ==================== 步骤6: 添加播放历史 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 6: 添加播放历史');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const historyInsert = db.prepare(`
      INSERT INTO play_history (user_id, bvid, title, artist, duration, cover_url, played_at, progress)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const now = new Date();
    for (let i = 0; i < testHistory.length; i++) {
      const item = testHistory[i];
      const audio = testAudios.find(a => a.bvid === item.bvid) || testAudios[0];

      // 生成不同的播放时间（最近几天）
      const playedAt = new Date(now.getTime() - i * 3600000); // 每条间隔1小时

      try {
        historyInsert.run(
          testUserId,
          item.bvid,
          audio.title,
          audio.artist,
          audio.duration,
          audio.cover,
          playedAt.toISOString(),
          item.progress
        );
        log(colors.green, `  ✓ ${audio.title.substring(0, 25)}... (进度: ${Math.floor(item.progress / audio.duration * 100)}%)`);
      } catch (error) {
        log(colors.yellow, `  ⚠ ${item.bvid} 可能已存在`);
      }
    }
    console.log('');

    // ==================== 步骤7: 统计信息 ====================
    log(colors.cyan, '═══════════════════════════════════════════════════════════');
    log(colors.cyan, '  步骤 7: 数据统计');
    log(colors.cyan, '═══════════════════════════════════════════════════════════\n');

    const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get();
    const playlistCount = db.prepare('SELECT COUNT(*) as count FROM playlists').get();
    const itemCount = db.prepare('SELECT COUNT(*) as count FROM playlist_items').get();
    const historyCount = db.prepare('SELECT COUNT(*) as count FROM play_history').get();

    log(colors.blue, '  当前数据库状态:');
    console.log(`    用户数:      ${colors.green}${userCount.count}${colors.reset}`);
    console.log(`    歌单数:      ${colors.green}${playlistCount.count}${colors.reset}`);
    console.log(`    歌单项数:    ${colors.green}${itemCount.count}${colors.reset}`);
    console.log(`    播放历史数:  ${colors.green}${historyCount.count}${colors.reset}`);
    console.log('');

    // ==================== 完成 ====================
    log(colors.green, '╔════════════════════════════════════════════════════════════╗');
    log(colors.green, '║                   测试数据填充完成!                        ║');
    log(colors.green, '╚════════════════════════════════════════════════════════════╝\n');

    log(colors.yellow, '  测试账号信息:');
    console.log('');
    for (const user of testUsers) {
      console.log(`    ${colors.cyan}用户名:${colors.reset} ${user.username}`);
      console.log(`    ${colors.cyan}密码:${colors.reset}   ${user.password}`);
      console.log('');
    }

    log(colors.yellow, '  现在可以运行测试程序:');
    log(colors.blue, '    node tests/test-phase2-interactive.js\n');

  } catch (error) {
    log(colors.red, `✗ 发生错误: ${error.message}`);
    console.error(error);
  } finally {
    db.close();
    log(colors.yellow, '→ 数据库连接已关闭\n');
  }
}

// readline 问题包装
function question(prompt) {
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(`${colors.cyan}${prompt}${colors.reset}`, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// 运行
main();
