# nginx-brotli alpine minimal image

[中文版本](./README.md)

This project provides a minimal `nginx` image based on `alpine:3.21`. It uses a multi-stage build to compile and load the `ngx_brotli` module so image consumers can decide whether to enable Brotli in their site configuration.

## Features

- Uses an Alpine runtime base to keep the final image lightweight
- Builds `ngx_brotli` as dynamic Nginx modules in a multi-stage Docker build
- Keeps Brotli module loading in `nginx.conf` while moving runtime switches into `conf.d/default.conf`
- Includes a minimal `nginx.conf` and default site config
- Provides a ready-to-run `docker-compose.yml`

## Project Structure

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

## Requirements

- Docker
- Docker Compose (recommended via `docker compose`)

## Quick Start

### 1. Build and start

```bash
docker compose up -d --build
```

### 2. Open the site

After startup, visit:

```text
http://localhost
```

### 3. Stop the service

```bash
docker compose down
```

## Build And Push With GitHub Actions

The repository already includes a manually triggered workflow at [`.github/workflows/manual-build-push.yml`](./.github/workflows/manual-build-push.yml).
It builds the image from the current repository `Dockerfile` and pushes it to the registry you specify.

### 1. Configure repository variables and secrets

Open your GitHub repository and go to `Settings` -> `Secrets and variables` -> `Actions`, then configure these entries as needed:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `REGISTRY` | Variable or Secret | No | Registry host, `host[:port]` only, for example `ghcr.io` or `registry.example.com:5000`. You can also provide it at workflow runtime. |
| `REGISTRY_NAMESPACE` | Variable or Secret | No | Registry namespace such as `my-team`. Do not combine it with `REGISTRY`. |
| `REGISTRY_USERNAME` | Variable or Secret | Yes | Registry login username. |
| `REGISTRY_PASSWORD` | Secret | Yes | Registry password or access token. Prefer storing this only as a Secret. |

Notes:

- `REGISTRY` must not include `https://` or `http://`
- `REGISTRY` must not include a namespace path such as `ghcr.io/my-team`
- Put the namespace in `REGISTRY_NAMESPACE` instead

### 2. Run the workflow manually

Open the repository `Actions` tab, choose `Manual Docker Build And Push`, click `Run workflow`, and fill in these inputs:

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `registry` | No | empty | Registry host for this run. If blank, it falls back to `vars/secrets.REGISTRY`. |
| `image_repository` | Yes | `nginx-brotli` | Image repository name without the registry, for example `team/nginx-build`. |
| `image_tag` | Yes | `latest` | Image tag to push. |
| `nginx_version` | Yes | `1.27.4` | Passed to the `Dockerfile` as the `NGINX_VERSION` build arg. |
| `push_latest` | No | `false` | When `image_tag` is not `latest`, also push an additional `latest` tag. |

### 3. Image naming rule

The workflow assembles the final image reference in this format:

```text
<registry>/<registry_namespace>/<image_repository>:<image_tag>
```

If `registry_namespace` is empty, that segment is omitted automatically.

Example:

- `REGISTRY=ghcr.io`
- `REGISTRY_NAMESPACE=my-org`
- `image_repository=nginx-build`
- `image_tag=1.27.4`

The pushed image will be:

```text
ghcr.io/my-org/nginx-build:1.27.4
```

If `push_latest=true` and `image_tag` is not `latest`, the workflow also pushes:

```text
ghcr.io/my-org/nginx-build:latest
```

### 4. Recommended setup

If you want most runs to require only a version change in the UI, a practical setup is:

- Repository Variable: `REGISTRY=ghcr.io`
- Repository Variable: `REGISTRY_NAMESPACE=my-org`
- Repository Variable: `REGISTRY_USERNAME=<your GitHub username or bot account>`
- Repository Secret: `REGISTRY_PASSWORD=<your PAT or registry token>`

Then for each manual run you only need to provide:

- `image_repository=nginx-brotli`
- `image_tag=1.27.4-alpine`
- `nginx_version=1.27.4`
- `push_latest=true`

### 5. Workflow behavior

- Uses `docker/build-push-action@v6` to build and push the image
- Enables GitHub Actions cache via `cache-from/cache-to: type=gha`
- Supports manual triggering only; it does not auto-publish on `push` or `tag`
- Uses the repository root as build context and the current branch `Dockerfile`

## Verify Brotli

The sample site enables Brotli in `conf.d/default.conf` by default. Use the following command to verify Brotli compression is working:

```bash
curl -I -H "Accept-Encoding: br" http://localhost
```

If the response headers include the following, Brotli is active:

```text
Content-Encoding: br
```

## Customization

### Change the Nginx version

The version is controlled by a build arg in `docker-compose.yml`:

```yaml
args:
  NGINX_VERSION: 1.27.4
```

Update the version and rebuild if needed:

```bash
docker compose up -d --build
```

### Adjust the Brotli policy

The image only loads the Brotli dynamic modules in `nginx.conf`. Whether Brotli is enabled, plus its compression level and MIME type settings, is controlled by `conf.d/default.conf`.

If you want to disable or redefine Brotli behavior as an image consumer, replace or edit `conf.d/default.conf`.

## Configuration Notes

### `Dockerfile`

- Downloads and compiles the specified `nginx` version in the builder stage
- Clones `google/ngx_brotli` and builds dynamic Brotli modules
- Copies only the required runtime artifacts into the final image

### `nginx.conf`

- Loads Brotli dynamic modules at startup
- Provides global HTTP baseline settings
- Includes `/etc/nginx/conf.d/*.conf`

### `conf.d/default.conf`

- Listens on port `80` by default
- Contains the default Brotli runtime settings and can be customized by image consumers
- Serves files from `/usr/share/nginx/html`
- Although the image is built with HTTP/3 support, the sample config does not enable HTTP/3 listeners by default; image consumers need to add the relevant `listen ... quic` and TLS settings themselves

## Common Commands

### View logs

```bash
docker compose logs -f
```

### Enter the container

```bash
docker exec -it nginx-brotli sh
```

### Validate Nginx configuration

```bash
docker exec -it nginx-brotli nginx -t
```

## Notes

- The image exposes container ports `80` and `443`
- The sample site listens on port `80`; port `443` is mapped for your own HTTPS/TLS server configuration
- Nginx starts as root to bind privileged ports, and worker processes run as `nginx` via `nginx.conf`
- The `docker-compose.yml` example maps host ports `80` and `443` to container ports `80` and `443`
- The container name is `nginx-brotli`
- The sample page is located at `html/index.html`

If you want, I can also add sections for `HTTPS`, reverse proxying, bind mounts, or production-oriented deployment notes.
