# 在线插件开发约定

## 本地验证

在仓库根目录执行：

```sh
./scripts/validate-plugin.sh
./scripts/update-catalog.sh
./scripts/smoke-test.sh
./scripts/build-site.sh
```

`validate-plugin.sh` 会解析清单、检查入口路径、校验命令参数模板，并运行 zsh/bash 语法检查。`update-catalog.sh` 会清理旧的生成包，重新打包全部插件，生成 `dist/*.tergo-plugin` 和 `catalog/index.json`。`smoke-test.sh` 会在当前 Git 项目中用 zsh 和 bash 运行代表性命令；可以通过 `TERGO_SMOKE_PROJECT_ROOT` 指定其他测试项目。
`build-site.sh` 会生成 GitHub Pages 所需的 `site/catalog/index.json` 和 `site/packages/`，默认使用 `https://wfu-work.github.io/tergo-plugins/packages` 作为插件包地址。

## 提交前要求

- 每个插件同时提供 `init.zsh` 和 `init.bash`；
- 只把必要的外部命令列入 `requiredCommands`，可选工具在运行时回退；
- 所有用户输入都通过 manifest 参数模板或单个 Shell 参数传递；
- 写操作必须使用 `medium`、`high` 或 `critical` 风险等级，并提供预览或 dry-run；
- 不读取或输出 Token、密码、Cookie、私钥和完整连接串；
- 版本遵循 SemVer，发布包必须能被 Tergo 原子安装和回滚；
- 更新目录前先重新生成包并校验 SHA-256。

## 包内容

打包脚本只会写入 `manifest.json`、manifest 声明的入口脚本，以及可选的 `README.md` 和 `LICENSE`。临时文件、测试夹具和源码目录不会进入插件包。
