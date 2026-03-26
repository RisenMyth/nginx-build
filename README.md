# nginx-brotli alpine 精简镜像

[English Version](./README.en.md)

这是一个基于 `alpine:3.21` 的 `nginx` 精简镜像示例，使用多阶段构建方式编译并加载 `ngx_brotli` 模块，让镜像使用者可以按需在站点配置中启用 Brotli 压缩。

## 功能说明

- 基于 Alpine 运行时镜像，尽量减小体积
- 通过多阶段构建编译 `ngx_brotli` 动态模块
- 仅在 `nginx.conf` 中保留 Brotli 模块加载，运行时开关下放到 `conf.d/default.conf`
- 提供最小可用的 `nginx.conf` 与默认站点配置
- 通过 `docker-compose.yml` 快速构建和启动

## 目录结构

```text
.
├─ Dockerfile
├─ docker-compose.yml
├─ nginx.conf
├─ conf.d/
│  └─ default.conf
└─ html/
   └─ index.html
```

## 环境要求

- Docker
- Docker Compose（推荐使用 `docker compose`）

## 快速开始

### 1. 构建并启动

```bash
docker compose up -d --build
```

### 2. 访问服务

启动后访问：

```text
http://localhost
```

### 3. 停止服务

```bash
docker compose down
```

## GitHub Actions 构建并推送镜像

仓库内已经提供手动触发的 GitHub Actions 工作流：[`.github/workflows/manual-build-push.yml`](./.github/workflows/manual-build-push.yml)。
它会使用当前仓库中的 `Dockerfile` 构建镜像，并推送到你指定的镜像仓库。

### 1. 配置仓库变量与密钥

进入 GitHub 仓库的 `Settings` -> `Secrets and variables` -> `Actions`，按需配置以下项：

| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `REGISTRY` | Variable 或 Secret | 否 | 镜像仓库地址，只能是 `host[:port]`，例如 `ghcr.io`、`registry.example.com:5000`。也可以在运行 workflow 时临时填写。 |
| `REGISTRY_NAMESPACE` | Variable 或 Secret | 否 | 镜像命名空间，例如 `my-team`。不要和 `REGISTRY` 写在一起。 |
| `REGISTRY_USERNAME` | Variable 或 Secret | 是 | 镜像仓库登录用户名。 |
| `REGISTRY_PASSWORD` | Secret | 是 | 镜像仓库登录密码或 Access Token。建议只放在 Secret 中。 |

注意：

- `REGISTRY` 不能包含 `https://` 或 `http://`
- `REGISTRY` 不能包含命名空间路径，例如不能写成 `ghcr.io/my-team`
- 命名空间应单独放在 `REGISTRY_NAMESPACE`

### 2. 手动触发构建

进入仓库的 `Actions` 页面，选择 `Manual Docker Build And Push`，点击 `Run workflow` 后填写参数：

| 输入项 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `registry` | 否 | 空 | 当前次构建使用的 registry 地址。留空时回退到 `vars/secrets.REGISTRY`。 |
| `image_repository` | 是 | `nginx-brotli` | 镜像仓库名，不包含 registry，例如 `team/nginx-build`。 |
| `image_tag` | 是 | `latest` | 要推送的镜像标签。 |
| `nginx_version` | 是 | `1.27.4` | 透传给 `Dockerfile` 的 `NGINX_VERSION` 构建参数。 |
| `push_latest` | 否 | `false` | 当 `image_tag` 不是 `latest` 时，是否额外再推送一个 `latest` 标签。 |

### 3. 镜像命名规则

workflow 会按下面的格式组装最终镜像地址：

```text
<registry>/<registry_namespace>/<image_repository>:<image_tag>
```

其中 `registry_namespace` 为空时会自动省略。

例如：

- `REGISTRY=ghcr.io`
- `REGISTRY_NAMESPACE=my-org`
- `image_repository=nginx-build`
- `image_tag=1.27.4`

最终会推送：

```text
ghcr.io/my-org/nginx-build:1.27.4
```

如果同时开启 `push_latest=true`，并且 `image_tag` 不是 `latest`，还会额外推送：

```text
ghcr.io/my-org/nginx-build:latest
```

### 4. 一个推荐用法

如果你希望大部分情况下只在页面上填写版本号，可以这样配置：

- 仓库 Variable: `REGISTRY=ghcr.io`
- 仓库 Variable: `REGISTRY_NAMESPACE=my-org`
- 仓库 Variable: `REGISTRY_USERNAME=<你的 GitHub 用户名或仓库机器人账号>`
- 仓库 Secret: `REGISTRY_PASSWORD=<你的 PAT 或仓库令牌>`

之后每次只需在 `Run workflow` 时填写：

- `image_repository=nginx-brotli`
- `image_tag=1.27.4-alpine`
- `nginx_version=1.27.4`
- `push_latest=true`

### 5. 工作流行为说明

- 工作流使用 `docker/build-push-action@v6` 构建并推送镜像
- 已启用 GitHub Actions 缓存：`cache-from/cache-to: type=gha`
- 当前 workflow 仅支持手动触发，不会在 `push` 或 `tag` 时自动发布
- 构建上下文为仓库根目录，实际使用的是当前分支上的 `Dockerfile`

## Brotli 验证

默认示例站点会在 `conf.d/default.conf` 中启用 Brotli。可以通过以下命令检查响应是否启用了 Brotli：

```bash
curl -I -H "Accept-Encoding: br" http://localhost
```

如果响应头中包含以下内容，则表示 Brotli 已生效：

```text
Content-Encoding: br
```

## 可调整项

### 修改 nginx 版本

当前 `docker-compose.yml` 中通过构建参数指定版本：

```yaml
args:
  NGINX_VERSION: 1.27.4
```

如果需要其他版本，可直接修改该值后重新构建：

```bash
docker compose up -d --build
```

### 调整 Brotli 策略

镜像只在 `nginx.conf` 中负责加载 Brotli 动态模块，是否启用以及压缩级别、类型等运行时配置由 `conf.d/default.conf` 决定。

如果你作为镜像使用者希望关闭或改写 Brotli，直接修改或挂载自己的 `conf.d/default.conf` 即可。

## 配置说明

### `Dockerfile`

- 第一阶段下载并编译指定版本 `nginx`
- 拉取 `google/ngx_brotli` 并编译为动态模块
- 第二阶段只保留运行所需文件和依赖

### `nginx.conf`

- 启动时加载 Brotli 动态模块
- 提供全局 HTTP 基础配置
- 统一包含 `/etc/nginx/conf.d/*.conf`

### `conf.d/default.conf`

- 默认监听 `80` 端口
- 包含 Brotli 的默认运行时配置，可由镜像使用者自行调整
- 默认站点根目录为 `/usr/share/nginx/html`
- 虽然镜像已编译 HTTP/3 支持，但默认示例配置未启用 HTTP/3 监听，需由使用者自行补充相关 `listen ... quic` 与 TLS 配置

## 常用命令

### 查看日志

```bash
docker compose logs -f
```

### 进入容器

```bash
docker exec -it nginx-brotli sh
```

### 检查 Nginx 配置

```bash
docker exec -it nginx-brotli nginx -t
```

## 说明

- 镜像默认暴露容器端口 `80` 和 `443`
- 默认示例站点监听 `80` 端口；`443` 端口预留给你自定义 HTTPS/TLS 配置
- Nginx 以 root 启动以绑定特权端口，worker 进程通过 `nginx.conf` 里的 `user nginx;` 降权运行
- `docker-compose.yml` 示例默认映射宿主机 `80/443` 到容器 `80/443`
- 容器名称为 `nginx-brotli`
- 示例页面位于 `html/index.html`

如果你后续还想补充 `HTTPS`、反向代理、挂载自定义站点目录或生产环境配置，我可以继续帮你整理。
