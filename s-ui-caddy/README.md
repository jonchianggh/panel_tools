# s-ui-caddy

One container with the [s-ui](https://github.com/alireza0/s-ui) panel (sing-box core), a Caddy front door with a decoy site, and an optional [Komari](https://github.com/komari-monitor/komari-agent) agent. It's built for hosts that give you a single HTTP port behind a TLS-terminating edge.

Caddy owns that port and routes by path:

| Request | Goes to |
|---|---|
| `PANEL_PATH*` | s-ui panel (127.0.0.1:2095) |
| `SUB_PATH*` | s-ui subscription server (127.0.0.1:2096) |
| WebSocket upgrade on `/<WS_SECRET>/<port>[/...]`, port 10000-19999 | the inbound listening on 127.0.0.1:`<port>` |
| anything else | decoy site |

Inbounds are routed by the port in their path, so you can add, change or remove WebSocket/HTTPUpgrade inbounds in the panel without a redeploy.

## Image

Prebuilt for amd64 and arm64: `ghcr.io/jonchianggh/s-ui-caddy:latest`. Use it in place of `build: .` if you'd rather not build.

## Run

```sh
docker compose up -d --build
docker compose logs sui | grep '^start:'
```

`compose.yml` serves on port 3000 (`PORT`) and keeps `/data` on a volume. Every variable is optional (see `.env.example`). Anything unset is generated on first boot, saved to `/data/secrets.env`, and printed in the logs, including the admin password. Set `PUBLIC_HOST` to the hostname clients use, so the panel and subscription links are correct.

## Adding a WebSocket inbound

In s-ui, create e.g. a VLESS, VMess, Trojan or Shadowsocks inbound with:

- **Listen** `127.0.0.1`, **port** between 10000 and 19999 (say 10001)
- **Transport** WebSocket (or HTTPUpgrade), **path** `/<WS_SECRET>/10001`
- **TLS** off on the inbound (the edge in front terminates TLS)
- **Addresses** (what clients and subscriptions use): your public hostname, port 443, TLS on, SNI set to the hostname, uTLS fingerprint `chrome`

## UDP and raw TCP inbounds

Add the port to `compose.yml`, e.g. `"20000:20000/udp"`, and bind the inbound to `::` on that port. Hysteria2 and TUIC need their own certificate; self-signed plus pinning is simplest.

## Komari agent

The agent binary is built into the image (copied from `ghcr.io/komari-monitor/komari-agent`). Set `AGENT_ENDPOINT` and `AGENT_TOKEN` to run it; `AGENT_INTERVAL` and `AGENT_IGNORE_UNSAFE_CERT` pass through too. It only connects outbound, so it needs no port. Auto-update is always off. Web SSH stays off unless you set `AGENT_DISABLE_WEB_SSH=false`. Because it shares the container with sing-box, the network figures it reports are your proxy traffic.

## Decoy

The built-in decoy is in `decoy/`. To use your own without rebuilding, put a site in `/data/decoy` and restart.

## Notes

- Measured idle: s-ui about 64 MB RSS, Caddy about 45 MB.
- If s-ui, Caddy or the agent exits, the container exits so your restart policy brings it back.
- The `SUI_IMAGE` build arg pins an s-ui release, e.g. `alireza7/s-ui:v1.6.7`.
