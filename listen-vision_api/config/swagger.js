const swaggerJsdoc = require('swagger-jsdoc');

/**
 * Swagger API 文档配置
 * 访问地址: http://localhost:3000/api-docs
 */

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'ListenVision API',
      version: '1.0.0',
      description: `
        ListenVision 后端 API 文档

        ## 认证说明

        大部分 API 需要 JWT Bearer Token 认证。

        **获取 Token:**
        1. 注册账号: \`POST /api/auth/register\`
        2. 登录: \`POST /api/auth/login\`
        3. 复制返回的 \`token\` 字段

        **使用 Token:**
        在请求头中添加:
        \`\`\`
        Authorization: Bearer <your_token_here>
        \`\`\`

        ## 响应格式

        所有 API 返回统一的 JSON 格式:

        **成功响应:**
        \`\`\`json
        {
          "success": true,
          "message": "操作成功",
          "data": { ... }
        }
        \`\`\`

        **错误响应:**
        \`\`\`json
        {
          "success": false,
          "error": "错误信息"
        }
        \`\`\`
      `,
      contact: {
        name: 'ListenVision Team',
        email: 'support@listenvision.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: '开发服务器'
      },
      {
        url: 'https://api.listenvision.com',
        description: '生产服务器'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            error: {
              type: 'string',
              example: '错误信息'
            }
          }
        },
        Success: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              example: '操作成功'
            },
            data: {
              type: 'object'
            }
          }
        },
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            username: {
              type: 'string',
              example: 'testuser'
            },
            email: {
              type: 'string',
              example: 'test@example.com',
              format: 'email'
            },
            created_at: {
              type: 'string',
              example: '2026-01-12T10:00:00.000Z'
            }
          }
        },
        LoginResponse: {
          type: 'object',
          properties: {
            token: {
              type: 'string',
              example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
            },
            user: {
              $ref: '#/components/schemas/User'
            }
          }
        },
        Favorite: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            url: {
              type: 'string',
              example: 'https://example.com/audio.mp3'
            },
            title: {
              type: 'string',
              example: '测试音频'
            },
            username: {
              type: 'string',
              example: 'testuser'
            }
          }
        }
      }
    }
  },
  apis: ['./routes/*.js', './controllers/*.js']
};

const specs = swaggerJsdoc(options);

module.exports = specs;
