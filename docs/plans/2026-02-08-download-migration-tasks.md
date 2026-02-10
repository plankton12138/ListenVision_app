# 下载功能迁移任务清单

**基于文档**: `docs/plans/2026-02-08-download-migration-plan.md`  (版本 2.0)
**创建日期**: 2026-02-08

---

## 目标 (完成标准) ✅
- 前端实现零转换下载：`BilibiliDownloader` + `MetadataWriter` 已上线并在主要平台（Windows/Android/iOS）验证通过。
- 后端移除所有与 FFmpeg/服务器端下载相关的代码、路由与依赖。
- 完整的单元测试与集成测试覆盖关键逻辑（元数据写入、下载流程、断点回退）。
- 文档与 CI 更新完成，PR 模板包含验收检查项。

---

## 优先任务列表（按优先级排序）

1. [ ] 后端清理：删除 `listen-vision_api/services/audio/conversionService.js` 并移除在 `listen-vision_api/services/audio/index.js` 中的导出
   - 优先级: 高
   - 估时: 0.5 天
   - 验收标准: 文件已删除，`npm test`/`node` 启动无错误，`package.json` 中移除 `fluent-ffmpeg`/`ffmpeg-static`（若已移除则确认）

2. [ ] 测试覆盖：新增单元与集成测试
   - 单元: `frontend_flutter/test/services/metadata_writer_test.dart`
   - 集成: `frontend_flutter/integration_test/download_flow_test.dart`（模拟下载与元数据写入）
   - 优先级: 高
   - 估时: 1 天

3. [ ] 文档清理与收尾
   - 清理 `docs/plans/2026-02-08-download-migration-plan.md` 中的旧版/重复内容，保留最终方案与变更记录
   - 在 `README.md` 和 `frontend_flutter/README.md` 更新迁移说明与已完成项
   - 优先级: 中
   - 估时: 0.5 天

4. [ ] CI/验证
   - 在 CI 中加入相关 test job（Flutter 单元/集成测试、Node 后端 lint/test）
   - 在 PR 合并前强制通过
   - 优先级: 中
   - 估时: 0.5 天

5. [ ] 平台验证与回归测试
   - 手动/自动在 Windows/Android/iOS 上验证播放与元数据（特别是 M4A 封面与标签）
   - 优先级: 中
   - 估时: 0.5 天

6. [ ] 回退方案校验
   - 确认 `MetadataWriter` 在 Web 环境降级到“仅重命名”策略，并在文档中注明
   - 优先级: 低
   - 估时: 0.25 天

---

## 额外事项
- 如果 `conversionService.js` 被删除，请检查 `listen-vision_api/routes`、`controllers` 是否还有引用（搜索 `convertWithMetadata`/`proxyAndConvert` 等）。
- 在删除 FFmpeg 后，建议运行一次依赖清理并提交更新的 `package.json`/`pnpm-lock.yaml`。

---

## 负责人 & 备注
- 负责人: @TODO (请在开始前分配)
- 备注: 如果你希望我代为提交 PR，我可以先实现第 1 项并创建草稿 PR 供你 Review。
