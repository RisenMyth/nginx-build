# nginx-brotli slim image

[中文版本](./README.md)

This project provides a minimal `nginx` image based on `debian:bookworm-slim`. It uses a multi-stage build to compile and load the `ngx_brotli` module so Brotli compression is enabled in a slim runtime image.

## Features

- Uses a slim runtime base to keep the final image lightweight
- Builds `ngx_brotli` as dynamic Nginx modules in a multi-stage Docker build
- Enables `brotli on` and `brotli_static on` by default
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
http://localhost:8080
```

### 3. Stop the service

```bash
docker compose down
```

## Verify Brotli

Use the following command to verify Brotli compression is working:

```bash
curl -I -H "Accept-Encoding: br" http://localhost:8080
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

## Configuration Notes

### `Dockerfile`

- Downloads and compiles the specified `nginx` version in the builder stage
- Clones `google/ngx_brotli` and builds dynamic Brotli modules
- Copies only the required runtime artifacts into the final image

### `nginx.conf`

- Loads Brotli dynamic modules at startup
- Enables Brotli compression by default
- Includes common text and static asset MIME types for compression

### `conf.d/default.conf`

- Listens on port `80`
- Serves files from `/usr/share/nginx/html`

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

- The service is exposed on host port `8080`
- The container name is `nginx-brotli`
- The sample page is located at `html/index.html`

If you want, I can also add sections for `HTTPS`, reverse proxying, bind mounts, or production-oriented deployment notes.
