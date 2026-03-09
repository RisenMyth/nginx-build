# nginx-brotli slim 镜像

[English Version](./README.en.md)

这是一个基于 `debian:bookworm-slim` 的 `nginx` 精简镜像示例，使用多阶段构建方式编译并加载 `ngx_brotli` 模块，让镜像使用者可以按需在站点配置中启用 Brotli 压缩。

## 功能说明

- 基于 `slim` 运行时镜像，尽量减小体积
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
http://localhost:8080
```

### 3. 停止服务

```bash
docker compose down
```

## Brotli 验证

默认示例站点会在 `conf.d/default.conf` 中启用 Brotli。可以通过以下命令检查响应是否启用了 Brotli：

```bash
curl -I -H "Accept-Encoding: br" http://localhost:8080
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

- 监听 `80` 端口
- 包含 Brotli 的默认运行时配置，可由镜像使用者自行调整
- 默认站点根目录为 `/usr/share/nginx/html`

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

- 当前默认对外暴露端口为 `8080`
- 容器名称为 `nginx-brotli`
- 示例页面位于 `html/index.html`

如果你后续还想补充 `HTTPS`、反向代理、挂载自定义站点目录或生产环境配置，我可以继续帮你整理。
