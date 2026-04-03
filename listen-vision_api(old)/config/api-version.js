/**
 * API 版本配置
 *
 * 支持多版本 API 并存，便于平滑升级
 * 当前版本: v1
 */

const apiVersions = {
  v1: {
    prefix: '/api/v1',
    description: '当前稳定版本',
    deprecated: false,
    introducedAt: '2024-01-01',
  },
  v2: {
    prefix: '/api/v2',
    description: '未来版本（预留）',
    deprecated: false,
    introducedAt: '2025-01-01',
  },
};

/**
 * 获取指定版本的 API 前缀
 * @param {string} version - 版本号 (v1, v2)
 * @returns {string} API 前缀
 */
function getApiPrefix(version = 'v1') {
  return apiVersions[version]?.prefix || '/api/v1';
}

/**
 * 获取所有支持的版本
 * @returns {Array} 版本列表
 */
function getSupportedVersions() {
  return Object.keys(apiVersions).filter(v => !apiVersions[v].deprecated);
}

/**
 * 检查版本是否被弃用
 * @param {string} version - 版本号
 * @returns {boolean}
 */
function isDeprecated(version) {
  return apiVersions[version]?.deprecated || false;
}

/**
 * 获取版本信息
 * @param {string} version - 版本号
 * @returns {Object|null}
 */
function getVersionInfo(version) {
  return apiVersions[version] || null;
}

/**
 * 版本中间件 - 从请求头或查询参数获取版本
 * 默认使用 v1
 */
function versionMiddleware(req, res, next) {
  // 1. 从查询参数获取
  let version = req.query.version || req.query.v;

  // 2. 从请求头获取
  if (!version) {
    version = req.headers['x-api-version'] || req.headers['api-version'];
  }

  // 3. 使用默认版本
  if (!version) {
    version = 'v1';
  }

  // 验证版本
  if (!apiVersions[version]) {
    return res.status(400).json({
      success: false,
      error: `不支持的 API 版本: ${version}。支持的版本: ${getSupportedVersions().join(', ')}`
    });
  }

  // 检查是否弃用
  if (isDeprecated(version)) {
    res.setHeader('X-API-Deprecated', 'true');
    res.setHeader('X-API-Supported-Version', 'v1');
  }

  // 设置版本到请求对象
  req.apiVersion = version;
  res.setHeader('X-API-Version', version);

  next();
}

module.exports = {
  getApiPrefix,
  getSupportedVersions,
  isDeprecated,
  getVersionInfo,
  versionMiddleware,
  apiVersions,
};
