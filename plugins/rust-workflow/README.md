# Rust 工作流

`rust-workflow` 复用当前项目的 Rust/Cargo 工具链，提供工具链报告、Cargo 文件发现、check、test、Clippy、格式检查、cargo-audit、依赖更新查询和构建预览。

命令不会自动安装 Rust toolchain、依赖、crate，也不会发布包。`tergo-rust-outdated` 可能访问 crates.io；请确认当前 Cargo registry 的网络和认证配置。

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-rust-report` | 查看 Rust、Cargo 和项目状态 | 低 |
| `tergo-rust-files` | 发现 Cargo 清单、锁定文件和源码 | 低 |
| `tergo-rust-check` | 运行 `cargo check` | 中 |
| `tergo-rust-test` | 运行 Cargo 测试 | 中 |
| `tergo-rust-clippy` | 运行 Clippy | 中 |
| `tergo-rust-fmt-check` | 检查格式，不写回文件 | 低 |
| `tergo-rust-audit` | 扫描依赖漏洞 | 中 |
| `tergo-rust-outdated` | 查询依赖更新 | 中 |
| `tergo-rust-build-preview` | 预览 release 构建命令 | 低 |

插件只读取当前 PATH、Cargo 配置和项目文件，不保存 registry 凭据；请勿把包含私有 registry 信息的输出直接发布到公共日志。
