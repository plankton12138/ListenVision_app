// 测试环境配置
// 在所有测试运行前执行

// 设置测试环境变量
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key-for-testing';
process.env.JWT_EXPIRES_IN = '1h';

// 抑制 console.log 输出（可选）
// global.console = {
//   ...console,
//   log: jest.fn(),
//   error: jest.fn(),
// };
