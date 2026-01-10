FROM alpine:latest

# libnatpmp: for Proton VPN port forwarding (natpmpc)
# python3: for your custom config script
RUN apk add --no-cache \
    bash \
    curl \
    python3 \
    iptables \
    wireguard-tools \
    libnatpmp \
    openresolv \
    ip6tables

ARG QBIT_VERSION=4.6.3
ARG QBIT_ARCH=x86_64-alpine-linux-musl
RUN curl -L "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QBIT_VERSION}_v1.2.19/${QBIT_ARCH}-qbittorrent-nox" -o /usr/bin/qbittorrent-nox \
    && chmod +x /usr/bin/qbittorrent-nox

RUN mkdir -p /config /data /scripts

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

ENV HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/config"

ENTRYPOINT ["/scripts/entrypoint.sh"]
