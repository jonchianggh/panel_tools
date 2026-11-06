#!/bin/bash
# Write a relay config on first boot (kept on the volume), then run the relay
# and, when configured, the Komari agent. If either exits, the container exits.
set -euo pipefail

DATA="${DATA_DIR:-/data}"
CONFIG="${RELAY_CONFIG:-$DATA/config.toml}"
PORT="${PORT:-3000}"
PUBLIC_HOST="${PUBLIC_HOST:-localhost}"
mkdir -p "$DATA"

gen() { tr -dc 'a-z0-9' </dev/urandom | head -c "${1:-16}" || true; }

# Decoy: your own site in /data/decoy wins; otherwise a random one generated on
# first boot (DECOY_RANDOM=false uses the relay's built-in page).
DECOY_DIR="$DATA/decoy"
DECOY_MODE=static
if [ ! -d "$DECOY_DIR" ]; then
  case "${DECOY_RANDOM:-true}" in
    false|0|no) DECOY_MODE=builtin ;;
    *) DECOY_DIR="$DATA/decoy-gen"
       [ -f "$DECOY_DIR/index.html" ] || decoy-gen "$DECOY_DIR" >/dev/null ;;
  esac
fi

if [ ! -f "$CONFIG" ]; then
  WS_SECRET="${WS_SECRET:-$(gen 12)}"; WS_SECRET="${WS_SECRET//\//}"
  SUB_PATH="${SUB_PATH:-$(gen 16)}"; SUB_PATH="/${SUB_PATH#/}"; SUB_PATH="${SUB_PATH%/}"
  UUID="${VLESS_UUID:-$(cat /proc/sys/kernel/random/uuid)}"
  SS_KEY="${SS_PASSWORD:-$(head -c 32 /dev/urandom | base64)}"
  {
    echo "listen = \"0.0.0.0:$PORT\""
    echo "domain = \"$PUBLIC_HOST\""
    echo "handshake_timeout_secs = 10"
    echo "idle_timeout_secs = 300"
    echo "block_private_addresses = true"
    echo
    echo "[udp]"
    echo "enabled = true"
    echo "dns_upstream = \"${DNS_UPSTREAM:-1.1.1.1:53}\""
    echo "dns_only = false"
    echo "idle_timeout_secs = 60"
    echo
    echo "[subscription]"
    echo "path = \"$SUB_PATH\""
    echo "name = \"${SUB_NAME:-$PUBLIC_HOST}\""
    echo "update_interval_hours = 24"
    echo
    echo "[decoy]"
    echo "mode = \"$DECOY_MODE\""
    [ "$DECOY_MODE" = static ] && echo "dir = \"$DECOY_DIR\""
    echo
    echo "[[inbounds]]"
    echo "path = \"/$WS_SECRET/vless\""
    echo "protocol = \"vless\""
    echo "uuid = \"$UUID\""
    echo
    echo "[[inbounds]]"
    echo "path = \"/$WS_SECRET/ss\""
    echo "protocol = \"shadowsocks\""
    echo "method = \"2022-blake3-aes-256-gcm\""
    echo "password = \"$SS_KEY\""
  } >"$CONFIG"
  chmod 600 "$CONFIG"
  echo "start: wrote $CONFIG (edit it and restart to change inbounds)"
fi

SUB=$(sed -n '/^\[subscription\]/,/^\[/{s/^path *= *"\(.*\)"/\1/p}' "$CONFIG" | head -1)
[ -n "$SUB" ] && echo "start: subscription https://$PUBLIC_HOST$SUB"

pids=()
rust-ws-relay run -c "$CONFIG" & pids+=($!)

if [ -n "${AGENT_ENDPOINT:-}" ] && [ -n "${AGENT_TOKEN:-}" ]; then
  export AGENT_DISABLE_AUTO_UPDATE=true
  export AGENT_DISABLE_WEB_SSH="${AGENT_DISABLE_WEB_SSH:-false}"
  komari-agent & pids+=($!)
  echo "start: komari agent reporting to $AGENT_ENDPOINT"
fi

trap 'kill -TERM "${pids[@]}" 2>/dev/null' TERM INT
set +e
wait -n "${pids[@]}"
code=$?
echo "start: a process exited ($code); stopping the rest"
kill -TERM "${pids[@]}" 2>/dev/null
wait
exit "$code"
