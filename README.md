# panel_tools

Self-hosting bundles, one per folder.

| Folder | What it is |
|---|---|
| [`s-ui-caddy/`](s-ui-caddy/) | s-ui (sing-box panel) behind Caddy with a decoy site and secret-path routing, plus an optional Komari agent, in one container |
| [`relay-komari/`](relay-komari/) | rust-ws-relay (VLESS / Shadowsocks over WebSocket) with a decoy site and subscription, plus an optional Komari agent, in one small container. No panel |
