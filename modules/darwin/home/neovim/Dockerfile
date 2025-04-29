FROM alpine:3.19

RUN apk add --no-cache \
    neovim \
    git \
    curl \
    build-base \
    python3 \
    npm \
    ripgrep \
    alpine-sdk \
    bash

WORKDIR /config
ENV XDG_DATA_HOME=/data
ENV XDG_CONFIG_HOME=/config
ENV XDG_STATE_HOME=/state
ENV XDG_CACHE_HOME=/cache
ENV NVIM_APPNAME=nvim-test

CMD ["nvim"]
