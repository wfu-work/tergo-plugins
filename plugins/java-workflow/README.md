# Java 工作流

`java-workflow` 会自动识别当前项目使用 Maven 还是 Gradle，并复用项目 Wrapper 或系统 CLI，提供 JDK 报告、源码发现、依赖树、测试、编译检查、依赖更新预览和构建预览。

命令不会自动安装 JDK、下载构建工具、修改 `pom.xml`/Gradle 文件或发布构件。依赖树和更新查询可能访问远程仓库；凭据继续由 Maven/Gradle 自身配置管理。

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-java-report` | 查看 JDK、Maven、Gradle 和构建系统 | 低 |
| `tergo-java-files` | 发现 Java、Maven 和 Gradle 文件 | 低 |
| `tergo-java-dependencies` | 查看依赖树 | 中 |
| `tergo-java-test` | 运行项目测试 | 中 |
| `tergo-java-check` | 执行 compile/check 检查 | 中 |
| `tergo-java-updates` | 预览依赖更新 | 中 |
| `tergo-java-build-preview` | 预览 package/build 命令 | 低 |

优先使用项目中的 `mvnw` 或 `gradlew`；没有 Wrapper 时才使用 PATH 中的 `mvn` 或 `gradle`。插件不保存仓库、签名或环境凭据。
