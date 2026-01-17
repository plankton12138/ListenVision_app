---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*)
argument-hint: [message]
description: Create git commit with bilingual (CN/EN) message
---

# Git Commit with Bilingual Message

创建 git commit，使用**中英文对照**的提交信息。

## 当前 Git 状态

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`

## 你的任务

1. **分析变更内容** - 根据上述 git diff 了解本次修改
2. **生成中英文对照的 commit message** - 遵循以下格式

### Commit Message 格式

```
<中文描述>

<English description>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Commit Message 类型

| 类型 | 中文 | English |
|------|------|---------|
| 新功能 | feat: 添加... | feat: add... |
| 修复 | fix: 修复... | fix: ... |
| 文档 | docs: 更新... | docs: update... |
| 重构 | refactor: 重构... | refactor: ... |
| 样式 | style: 调整... | style: adjust... |
| 测试 | test: 添加... | test: add... |
| 配置 | chore: 更新... | chore: update... |

3. **执行 git commit**
   - 先 `git add` 相关文件（如果未 staged）
   - 然后创建 commit

## 参数

- `$ARGUMENTS` - 可选的提交说明（如不提供则自动分析变更生成）

---

**示例**：
```
用户输入: /commit 添加 Cookie 加密功能

输出 commit:
feat(backend): 添加 Cookie AES-256-CBC 加密存储

feat(backend): add Cookie AES-256-CBC encryption storage

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```
