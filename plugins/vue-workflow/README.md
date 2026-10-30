# Vue 工作流

`vue-workflow` 面向 Vue、Vite 和 TypeScript 项目，自动识别 npm、pnpm、Yarn 或 Bun，提供工具报告、源码和配置发现、lockfile 检查、`vue-tsc`、ESLint、Vitest、依赖审计和 Vite 构建预览。

命令不会自动安装依赖、修改 `package.json`/lockfile、生成构建产物或发布站点。依赖审计可能访问包仓库，凭据继续由 npm/pnpm/Yarn 的已有配置管理。

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-vue-report` | 查看 Node、包管理器和前端工具 | 低 |
| `tergo-vue-files` | 发现 Vue、Vite、TypeScript 和 lockfile | 低 |
| `tergo-vue-lockfile` | 检查包管理器和锁定文件 | 低 |
| `tergo-vue-typecheck` | 运行 `vue-tsc --noEmit` | 中 |
| `tergo-vue-lint` | 运行 ESLint | 中 |
| `tergo-vue-test` | 运行 `vitest run` | 中 |
| `tergo-vue-audit` | 查询依赖漏洞 | 中 |
| `tergo-vue-build-preview` | 预览 `run build` | 低 |

包管理器选择顺序为 lockfile、项目 Wrapper/配置和 PATH；插件不保存 registry Token，不输出环境变量值。
