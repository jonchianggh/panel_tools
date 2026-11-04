# s-ui (sing-box panel) + Caddy front + Komari agent, in one container.
# Caddy owns the single public port: secret paths reach the panel, the
# subscription server and the WebSocket inbounds; everything else is a decoy.
ARG SUI_IMAGE=alireza7/s-ui:latest

FROM caddy:2-alpine AS caddy
FROM ghcr.io/komari-monitor/komari-agent:latest AS komari

FROM ${SUI_IMAGE}
RUN apk add --no-cache tini sqlite
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY --from=komari /app/komari-agent /usr/local/bin/komari-agent
COPY Caddyfile /etc/caddy/Caddyfile
COPY decoy/ /srv/decoy/
COPY decoy-gen.sh /usr/local/bin/decoy-gen
COPY start.sh /start.sh
RUN chmod 755 /start.sh /usr/local/bin/decoy-gen

ENV PORT=3000 \
    SUI_DB_FOLDER=/data/db \
    TZ=UTC
VOLUME /data
EXPOSE 3000

# The base image checks the panel; Caddy is the public face, so check that too.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ./sui healthcheck >/dev/null && wget -q -O /dev/null "http://127.0.0.1:${PORT}/" || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
