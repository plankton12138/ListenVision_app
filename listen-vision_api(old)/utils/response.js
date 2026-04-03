/**
 * 统一响应格式工具
 *
 * 使用示例:
 * successResponse(res, { id: 1, name: 'test' }, '获取成功');
 * errorResponse(res, '用户不存在', 404);
 */

/**
 * 成功响应
 * @param {Object} res - Express response 对象
 * @param {Object} data - 返回的数据
 * @param {String} message - 成功消息
 * @param {Number} statusCode - HTTP 状态码（默认 200）
 */
const successResponse = (res, data = null, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

/**
 * 错误响应
 * @param {Object} res - Express response 对象
 * @param {String} error - 错误消息
 * @param {Number} statusCode - HTTP 状态码（默认 500）
 */
const errorResponse = (res, error = 'Internal Server Error', statusCode = 500) => {
  return res.status(statusCode).json({
    success: false,
    error
  });
};

/**
 * 分页响应
 * @param {Object} res - Express response 对象
 * @param {Array} items - 数据列表
 * @param {Number} total - 总数
 * @param {Number} page - 当前页码
 * @param {Number} pageSize - 每页大小
 */
const paginatedResponse = (res, items, total, page, pageSize) => {
  return res.json({
    success: true,
    data: items,
    pagination: {
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize)
    }
  });
};

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse
};
