# rust-ws-relay (VLESS / Shadowsocks over WebSocket, decoy site, subscription)
# plus an optional Komari agent, in one small container.
FROM ghcr.io/komari-monitor/komari-agent:latest AS komari

FROM alpine:3.20 AS relay
ARG RELAY_VERSION=v0.4.2
ARG TARGETARCH
WORKDIR /tmp/relay
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) T=x86_64 ;; arm64) T=aarch64 ;; *) echo "unsupported arch $TARGETARCH"; exit 1 ;; \
    esac; \
    F="rust-ws-relay-$T-unknown-linux-musl.tar.gz"; \
    U="https://github.com/jonchianggh/rust-ws-relay/releases/download/$RELAY_VERSION"; \
    wget -q "$U/$F" "$U/$F.sha256"; \
    sha256sum -c "$F.sha256"; \
    tar xzf "$F"; \
    install -m 755 rust-ws-relay /usr/local/bin/rust-ws-relay

FROM alpine:3.20
RUN apk add --no-cache bash tini ca-certificates
COPY --from=relay /usr/local/bin/rust-ws-relay /usr/local/bin/rust-ws-relay
COPY --from=komari /app/komari-agent /usr/local/bin/komari-agent
COPY decoy-gen.sh /usr/local/bin/decoy-gen
COPY start.sh /start.sh
RUN chmod 755 /start.sh /usr/local/bin/decoy-gen

ENV PORT=3000 TZ=UTC
VOLUME /data
EXPOSE 3000

HEALTHCHECK --interval=60s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null "http://127.0.0.1:${PORT}/" || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
