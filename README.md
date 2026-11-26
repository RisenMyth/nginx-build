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
| `image_repository` | 是 | `nginx-brotli` | 镜像仓库名，不包含 registry，例如 `team/nginx-build`。 |
| `nginx_version` | 否 | 空（取 `Dockerfile` 中 `NGINX_VERSION` 的默认值） | NGINX 版本，例如 `1.31.10`。同时作为镜像标签，并透传为 `Dockerfile` 的 `NGINX_VERSION` 构建参数。 |

### 3. 镜像命名规则

镜像标签直接跟随 `nginx_version`，workflow 会按下面的格式组装最终镜像地址：

```text
<registry>/<registry_namespace>/<image_repository>:<nginx_version>
<registry>/<registry_namespace>/<image_repository>:latest
```

其中 `registry_namespace` 为空时会自动省略；两个标签一次推送完成，`latest` 始终同步为最新一次构建的内容。

例如：

- `REGISTRY=registry.cn-shanghai.aliyuncs.com`
- `REGISTRY_NAMESPACE=rishchen`
- `image_repository=nginx-brotli`
- `nginx_version=1.31.10`

最终会推送：

```text
registry.cn-shanghai.aliyuncs.com/rishchen/nginx-brotli:1.31.10
registry.cn-shanghai.aliyuncs.com/rishchen/nginx-brotli:latest
```

> 版本号会做一次规整：去掉首尾空白和前导 `v`（`v1.31.10` 会被规范成 `1.31.10`），并且必须是 `x.y.z` 形式，否则 workflow 会在构建前直接失败。

### 4. 一个推荐用法

如果你希望大部分情况下只在页面上填写版本号，可以这样配置：

- 仓库 Variable: `REGISTRY=ghcr.io`
- 仓库 Variable: `REGISTRY_NAMESPACE=my-org`
- 仓库 Variable: `REGISTRY_USERNAME=<你的 GitHub 用户名或仓库机器人账号>`
- 仓库 Secret: `REGISTRY_PASSWORD=<你的 PAT 或仓库令牌>`

之后每次只需在 `Run workflow` 时填写：

- `image_repository=nginx-brotli`
- `nginx_version=1.31.10`

就会同时产出 `nginx-brotli:1.31.10` 和 `nginx-brotli:latest`。

### 5. 工作流行为说明

- 工作流使用 `docker/build-push-action@v6` 构建并推送镜像
- 镜像标签跟随 `nginx_version`，并同步推送 `latest`
- 已关闭 `provenance` / `sbom`：阿里云 ACR 等仓库不支持 OCI 1.1 attestation（`application/vnd.oci.empty.v1+json`），否则推送会报 `denied: unknown manifest class`
- 推送完成后会用 `docker buildx imagetools inspect` 校验索引里没有 `unknown/unknown` 平台
- 已启用 GitHub Actions 缓存：`cache-from/cache-to: type=gha`（缓存读写失败不会导致任务失败）
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
