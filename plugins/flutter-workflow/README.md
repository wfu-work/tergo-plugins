# Flutter 工作流

`flutter-workflow` 面向 Flutter 项目提供环境检查、设备查看、代码分析、测试、依赖检查和构建预览。它不会安装 Flutter、修改用户 Shell 配置或执行发布操作。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-flutter-report` | 查看 Flutter、Dart 和项目状态 | 低 |
| `tergo-flutter-doctor` | 检查 Flutter 环境 | 低 |
| `tergo-flutter-devices` | 查看可用设备 | 低 |
| `tergo-flutter-analyze` | 运行静态分析 | 中 |
| `tergo-flutter-test` | 运行项目测试 | 中 |
| `tergo-flutter-pub-outdated` | 检查依赖更新 | 中 |
| `tergo-flutter-build-preview <target>` | 预览构建命令，不执行构建 | 低 |

Flutter SDK 是按需检查的可选依赖。缺少 SDK 时插件仍然可以加载，命令会给出安装提示；依赖检查命令可能访问 pub.dev，但不会自动修改依赖文件。
