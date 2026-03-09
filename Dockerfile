ARG NGINX_VERSION=1.27.4
ARG ALPINE_VERSION=3.21

FROM alpine:${ALPINE_VERSION} AS builder

ARG NGINX_VERSION

RUN apk add --no-cache \
        build-base \
        ca-certificates \
        cmake \
        curl \
        git \
        linux-headers \
        openssl-dev \
        pcre2-dev \
        zlib-dev

WORKDIR /usr/src

RUN curl -fsSLO "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
    && tar -xzf "nginx-${NGINX_VERSION}.tar.gz" \
    && git clone --depth 1 --recursive --shallow-submodules https://github.com/google/ngx_brotli.git

WORKDIR /usr/src/nginx-${NGINX_VERSION}

RUN ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-compat \
        --with-file-aio \
        --with-http_gzip_static_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_v2_module \
        --with-pcre-jit \
        --with-threads \
        --add-dynamic-module=/usr/src/ngx_brotli \
    && cd /usr/src/ngx_brotli/deps/brotli \
    && mkdir -p out \
    && cd out \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS="-O2" -DCMAKE_C_FLAGS="-O2" -DCMAKE_INSTALL_PREFIX=./installed .. \
    && cmake --build . --config Release -j"$(getconf _NPROCESSORS_ONLN)" \
    && cd /usr/src/nginx-${NGINX_VERSION} \
    && make -j"$(getconf _NPROCESSORS_ONLN)" \
    && mkdir -p /usr/lib/nginx/modules \
    && cp objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/ \
    && cp objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/ \
    && make install \
    && strip /usr/sbin/nginx /usr/lib/nginx/modules/*.so

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
        libstdc++ \
        libcrypto3 \
        libssl3 \
        pcre2 \
        zlib \
    && addgroup -S nginx \
    && adduser -S -D -H -G nginx nginx \
    && install -d -o nginx -g nginx \
        /var/cache/nginx/client_temp \
        /var/cache/nginx/proxy_temp \
        /var/cache/nginx/fastcgi_temp \
        /var/cache/nginx/uwsgi_temp \
        /var/cache/nginx/scgi_temp

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=builder /usr/lib/nginx/modules /usr/lib/nginx/modules

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --chown=nginx:nginx html/ /usr/share/nginx/html/

EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
