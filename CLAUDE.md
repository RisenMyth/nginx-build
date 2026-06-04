# 项目规范

## 提交规范（Conventional Commits）

本仓库使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范编写提交信息。

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 必填部分

- **type**：变更类型（见下表）
- **subject**：简明描述，不超过 72 字符，使用祈使句，首字母不大写，末尾不加句号

### 可选部分

- **scope**：影响范围，例如 `build`、`nginx`、`workflows`、`docker`、`docs`
- **body**：补充说明动机、与之前行为的对比，使用祈使句
- **footer**：破坏性变更标记 `BREAKING CHANGE:` 或 issue 引用

### 常用 type

| type       | 用途                                       |
| ---------- | ------------------------------------------ |
| `feat`     | 新增功能                                   |
| `fix`      | 修复 bug                                   |
| `docs`     | 仅文档变更                                 |
| `style`    | 不影响代码含义的格式调整（空格、分号等）   |
| `refactor` | 既非新增功能也非修复 bug 的代码变更        |
| `perf`     | 提升性能的代码变更                         |
| `test`     | 新增或修改测试                             |
| `build`    | 影响构建系统或外部依赖的变更（Dockerfile 等） |
| `ci`       | 更改 CI 配置文件或脚本（`.github/workflows` 等） |
| `chore`    | 其他不修改 src 或 test 文件的变更          |
| `revert`   | 撤销先前的提交                             |

### 示例

```
feat(nginx): 启用 HTTP/3 构建

chore(nginx): 修改访问日志文件名

ci(workflows): 移除手动触发的 registry 入参

feat!: 升级到 nginx 1.28

BREAKING CHANGE: 不再支持 nginx 1.24 及以下版本
```

### 注意事项

- 提交信息使用英文或中文均可，但需保持项目内一致；本仓库近期以中文 subject 为主。
- 同一提交只做一件事，避免混合无关变更。
- 在执行 `git commit` 前先确认变更范围与 type 匹配。
