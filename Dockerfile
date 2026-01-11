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
  ip6tables \
  grep \
  sed

RUN sed -i '/src_valid_mark=1/d' /usr/bin/wg-quick

ARG QBIT_VERSION=5.1.4
ARG LIBT_VERSION=1.2.20
ARG QBIT_ARCH=x86_64
RUN curl -L "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QBIT_VERSION}_v${LIBT_VERSION}/${QBIT_ARCH}-qbittorrent-nox" -o /usr/bin/qbittorrent-nox \
  && chmod +x /usr/bin/qbittorrent-nox

RUN mkdir -p /config /data /scripts

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

ENV HOME="/config" \
  XDG_CONFIG_HOME="/config" \
  XDG_DATA_HOME="/config"

ENTRYPOINT ["/scripts/entrypoint.sh"]
