const { body, param, query, validationResult } = require('express-validator');
const { AppError } = require('./errorHandler');

/**
 * 请求验证中间件
 * 使用 express-validator 进行参数验证
 */

/**
 * 验证结果检查中间件
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path,
      message: err.msg,
      value: err.value
    }));

    throw new AppError(
      `参数验证失败: ${JSON.stringify(formattedErrors)}`,
      400
    );
  }

  next();
};

/**
 * 认证相关验证规则
 */
const authValidators = {
  // 注册验证
  register: [
    body('username')
      .trim()
      .isLength({ min: 3, max: 20 })
      .withMessage('用户名长度必须在 3-20 个字符之间')
      .matches(/^[a-zA-Z0-9_]+/)
      .withMessage('用户名只能包含字母、数字和下划线'),
    body('email')
      .trim()
      .isEmail()
      .withMessage('请输入有效的邮箱地址')
      .normalizeEmail(),
    body('password')
      .isLength({ min: 6 })
      .withMessage('密码长度至少为 6 位')
      .matches(/^(?=.*[a-zA-Z])(?=.*\d)/)
      .withMessage('密码必须包含字母和数字'),
    validate
  ],

  // 登录验证 - 支持 email 或 username
  login: [
    body('username')
      .trim()
      .notEmpty()
      .withMessage('用户名或邮箱不能为空')
      .optional({ checkFalsy: true }), // 允许为空，因为会检查 email
    body('email')
      .trim()
      .notEmpty()
      .withMessage('用户名或邮箱不能为空')
      .optional({ checkFalsy: true }), // 允许为空，因为会检查 username
    body('password')
      .notEmpty()
      .withMessage('密码不能为空'),
    // 自定义验证：至少提供 username 或 email
    (req, res, next) => {
      const username = req.body.username || req.body.email;
      if (!username || username.trim() === '') {
        return res.status(400).json({
          success: false,
          message: '用户名或邮箱不能为空',
          errors: [{ field: 'username', message: '用户名或邮箱不能为空' }]
        });
      }
      // 标准化：将 email 或 username 统一放到 username 字段供 controller 使用
      req.body.usernameOrEmail = username;
      next();
    }
  ],

  // 发送重置验证码
  sendResetCode: [
    body('username')
      .trim()
      .notEmpty()
      .withMessage('用户名不能为空'),
    validate
  ],

  // 重置密码
  resetPassword: [
    body('username')
      .trim()
      .notEmpty()
      .withMessage('用户名不能为空'),
    body('code')
      .trim()
      .isLength({ min: 6, max: 6 })
      .withMessage('验证码必须是 6 位数字')
      .isNumeric()
      .withMessage('验证码必须是数字'),
    body('newPassword')
      .isLength({ min: 6 })
      .withMessage('新密码长度至少为 6 位')
      .matches(/^(?=.*[a-zA-Z])(?=.*\d)/)
      .withMessage('密码必须包含字母和数字'),
    validate
  ]
};

/**
 * 用户相关验证规则
 */
const userValidators = {
  // 更新用户
  updateUser: [
    param('id')
      .isInt()
      .withMessage('用户 ID 必须是整数'),
    body('username')
      .optional()
      .trim()
      .isLength({ min: 3, max: 20 })
      .withMessage('用户名长度必须在 3-20 个字符之间'),
    body('email')
      .optional()
      .trim()
      .isEmail()
      .withMessage('请输入有效的邮箱地址')
      .normalizeEmail(),
    body('password')
      .optional()
      .isLength({ min: 6 })
      .withMessage('密码长度至少为 6 位'),
    validate
  ],

  // 获取用户
  getUser: [
    param('id')
      .isInt()
      .withMessage('用户 ID 必须是整数'),
    validate
  ]
};

/**
 * 收藏相关验证规则
 */
const favoriteValidators = {
  // 添加收藏
  addFavorite: [
    body('url')
      .trim()
      .isURL()
      .withMessage('请输入有效的 URL')
      .isLength({ max: 2048 })
      .withMessage('URL 长度不能超过 2048 个字符'),
    body('title')
      .trim()
      .notEmpty()
      .withMessage('标题不能为空')
      .isLength({ max: 255 })
      .withMessage('标题长度不能超过 255 个字符'),
    validate
  ],

  // 更新收藏
  updateFavorite: [
    param('id')
      .isInt()
      .withMessage('收藏 ID 必须是整数'),
    body('url')
      .optional()
      .trim()
      .isURL()
      .withMessage('请输入有效的 URL'),
    body('title')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('标题不能为空'),
    body('username')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('用户名不能为空'),
    validate
  ],

  // 获取收藏
  getFavorite: [
    param('id')
      .isInt()
      .withMessage('收藏 ID 必须是整数'),
    validate
  ]
};

module.exports = {
  authValidators,
  userValidators,
  favoriteValidators
};
