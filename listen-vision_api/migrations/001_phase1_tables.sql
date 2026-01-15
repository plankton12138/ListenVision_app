-- Phase 1: B站API集成与元数据服务
-- 创建日期: 2026-01-13
-- 说明: B站账号绑定、音频元数据缓存、搜索历史表

-- ============================================
-- 1. B站账号绑定表
-- ============================================
-- 用途: 存储用户绑定的B站账号信息
-- 安全: Cookie使用AES-256-CBC加密存储
CREATE TABLE IF NOT EXISTS bilibili_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL COMMENT '关联的用户ID',
  bili_user_id VARCHAR(20) COMMENT 'B站用户ID',
  bili_username VARCHAR(100) COMMENT 'B站用户名',
  cookie_encrypted TEXT NOT NULL COMMENT '加密后的Cookie数据',
  is_active BOOLEAN DEFAULT TRUE COMMENT '绑定状态',
  expires_at DATETIME COMMENT 'Cookie过期时间',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '绑定时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_active (user_id, is_active) COMMENT '每个用户只能有一个激活的B站账号',
  INDEX idx_user_id (user_id),
  INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B站账号绑定表';

-- ============================================
-- 2. 音频元数据缓存表
-- ============================================
-- 用途: 缓存B站视频/音频的元数据，减少重复请求
-- 策略: TTL 7天，过期后自动刷新
CREATE TABLE IF NOT EXISTS audio_metadata_cache (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bvid VARCHAR(20) UNIQUE NOT NULL COMMENT 'B站视频ID',
  cid VARCHAR(20) COMMENT 'B站视频分P ID',
  title VARCHAR(255) COMMENT '音频标题',
  artist VARCHAR(255) COMMENT 'UP主/艺术家',
  duration INT COMMENT '音频时长(秒)',
  cover_url TEXT COMMENT '封面图片URL',
  audio_url TEXT COMMENT '音频流URL',
  metadata JSON COMMENT '完整元数据(JSON格式)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '缓存创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '缓存更新时间',
  INDEX idx_bvid (bvid),
  INDEX idx_updated_at (updated_at) COMMENT '用于清理过期缓存'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='音频元数据缓存表';

-- ============================================
-- 3. 搜索历史表
-- ============================================
-- 用途: 记录用户搜索历史，用于搜索建议和统计
CREATE TABLE IF NOT EXISTS search_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT COMMENT '用户ID(NULL表示未登录用户)',
  keyword VARCHAR(100) NOT NULL COMMENT '搜索关键词',
  result_count INT DEFAULT 0 COMMENT '搜索结果数量',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '搜索时间',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_keyword (user_id, keyword),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='搜索历史表';

-- ============================================
-- 4. 搜索统计表(可选，用于热门搜索)
-- ============================================
CREATE TABLE IF NOT EXISTS search_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  keyword VARCHAR(100) NOT NULL UNIQUE COMMENT '搜索关键词',
  search_count INT DEFAULT 1 COMMENT '搜索次数',
  last_searched TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后搜索时间',
  INDEX idx_search_count (search_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='搜索统计表';
