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
| `image_repository` | Yes | `nginx-brotli` | Image repository name without the registry, for example `team/nginx-build`. |
| `nginx_version` | No | empty (falls back to the `NGINX_VERSION` default in the `Dockerfile`) | NGINX version, for example `1.31.10`. It is used as the image tag and passed to the `Dockerfile` as the `NGINX_VERSION` build arg. |

### 3. Image naming rule

The image tag follows `nginx_version` directly, and the workflow assembles the final references as:

```text
<registry>/<registry_namespace>/<image_repository>:<nginx_version>
<registry>/<registry_namespace>/<image_repository>:latest
```

If `registry_namespace` is empty, that segment is omitted automatically. Both tags are pushed in the same build, so `latest` always mirrors the most recent build.

Example:

- `REGISTRY=ghcr.io`
- `REGISTRY_NAMESPACE=my-org`
- `image_repository=nginx-build`
- `nginx_version=1.31.10`

The pushed images will be:

```text
ghcr.io/my-org/nginx-build:1.31.10
ghcr.io/my-org/nginx-build:latest
```

> The version is normalized before use: surrounding whitespace and a leading `v` are stripped (`v1.31.10` becomes `1.31.10`), and it must match `x.y.z`. Otherwise the workflow fails before building.

### 4. Recommended setup

If you want most runs to require only a version change in the UI, a practical setup is:

- Repository Variable: `REGISTRY=ghcr.io`
- Repository Variable: `REGISTRY_NAMESPACE=my-org`
- Repository Variable: `REGISTRY_USERNAME=<your GitHub username or bot account>`
- Repository Secret: `REGISTRY_PASSWORD=<your PAT or registry token>`

Then for each manual run you only need to provide:

- `image_repository=nginx-brotli`
- `nginx_version=1.31.10`

That produces both `nginx-brotli:1.31.10` and `nginx-brotli:latest`.

### 5. Workflow behavior

- Uses `docker/build-push-action@v6` to build and push the image
- Image tag follows `nginx_version` and `latest` is pushed alongside it
- `provenance` / `sbom` are disabled: registries such as Aliyun ACR do not support OCI 1.1 attestations (`application/vnd.oci.empty.v1+json`) and reject the push with `denied: unknown manifest class`
- After the push, `docker buildx imagetools inspect` verifies the index has no `unknown/unknown` platform
- Enables GitHub Actions cache via `cache-from/cache-to: type=gha` (cache read/write failures do not fail the job)
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
