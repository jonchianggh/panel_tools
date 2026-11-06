# relay-komari

[rust-ws-relay](https://github.com/jonchianggh/rust-ws-relay) plus an optional
[Komari](https://github.com/komari-monitor/komari) agent in one small container.
A lighter alternative to `s-ui-caddy` when you don't need a web panel: one
static binary serves the WebSocket inbounds, a decoy site and a subscription
URL on a single port, with TLS terminated in front (a PaaS, a CDN, a reverse proxy).

Image: `ghcr.io/jonchianggh/relay-komari:latest` (amd64, arm64).

## First boot

With no `/data/config.toml`, `start.sh` writes one:

| Inbound | Path |
|---|---|
| VLESS (WS) | `/<WS_SECRET>/vless` |
| Shadowsocks 2022 (`2022-blake3-aes-256-gcm`, WS) | `/<WS_SECRET>/ss` |

Secrets are random unless set in the env (`WS_SECRET`, `SUB_PATH`, `VLESS_UUID`,
`SS_PASSWORD`). The log prints the subscription URL
(`https://<PUBLIC_HOST><SUB_PATH>`), which serves every inbound as a Clash/mihomo,
sing-box or base64 profile.

After that the config file is the source of truth: edit `/data/config.toml`
(see the relay's `config.example.toml`) and restart. Env changes to the
first-boot variables have no effect once the file exists.

## Decoy

Everything that isn't a valid handshake on a secret path gets a decoy site.
Your own site in `/data/decoy` wins; otherwise a random one is generated on first
boot into `/data/decoy-gen`. `DECOY_RANDOM=false` uses the relay's built-in page.

## Komari

Set `AGENT_ENDPOINT` and `AGENT_TOKEN` to start the agent; `AGENT_INTERVAL`
(seconds) sets the report rate. Auto-update is off; web SSH is on unless
`AGENT_DISABLE_WEB_SSH=true`.

## Compared with s-ui-caddy

No panel: inbound changes mean editing the config and restarting. No VLESS
mux/XUDP. Idle footprint is a few MB of RAM and near-zero CPU.
