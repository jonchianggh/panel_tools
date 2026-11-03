#!/bin/bash
# Configure s-ui from env, then run s-ui, Caddy and (optionally) the Komari
# agent. If any of them exits, the container exits so the platform restarts it.
set -euo pipefail

DATA="${DATA_DIR:-/data}"
DB_DIR="${SUI_DB_FOLDER:-$DATA/db}"
DB="$DB_DIR/s-ui.db"
SAVED="$DATA/secrets.env"
mkdir -p "$DB_DIR"

gen() { tr -dc 'a-z0-9' </dev/urandom | head -c "${1:-16}" || true; }
slashes() { local p="/${1#/}"; echo "${p%/}/"; }   # -> /x/y/

# Secrets: env wins; otherwise reuse what an earlier boot generated; otherwise
# generate once and keep it on the volume so links survive restarts.
[ -f "$SAVED" ] && . "$SAVED"
PANEL_PATH="$(slashes "${PANEL_PATH:-${SAVED_PANEL_PATH:-$(gen 16)}}")"
SUB_PATH="$(slashes "${SUB_PATH:-${SAVED_SUB_PATH:-$(gen 16)}}")"
WS_SECRET="${WS_SECRET:-${SAVED_WS_SECRET:-$(gen 12)}}"
WS_SECRET="${WS_SECRET//\//}"
cat >"$SAVED" <<SAVE
SAVED_PANEL_PATH='$PANEL_PATH'
SAVED_SUB_PATH='$SUB_PATH'
SAVED_WS_SECRET='$WS_SECRET'
SAVE
chmod 600 "$SAVED"

PUBLIC_HOST="${PUBLIC_HOST:-localhost}"
PORT="${PORT:-3000}"
DECOY_DIR="$DATA/decoy"
[ -d "$DECOY_DIR" ] || DECOY_DIR="${DEFAULT_DECOY:-/srv/decoy}"
PANEL_BASE="${PANEL_PATH%/}"
SUB_BASE="${SUB_PATH%/}"
export PANEL_BASE SUB_BASE PORT PANEL_PATH SUB_PATH WS_SECRET DECOY_DIR

cd "${APP_DIR:-/app}"
NEW_DB=0
if [ -f "$DB" ]; then ./sui migrate >/dev/null; else NEW_DB=1; fi

# Panel and sub servers listen on loopback only; Caddy is the way in.
./sui setting -port 2095 -path "$PANEL_PATH" -subPort 2096 -subPath "$SUB_PATH" >/dev/null
sqlite3 "$DB" <<SQL
DELETE FROM settings WHERE key IN ('webListen','subListen','subURI','webURI','webDomain','subDomain');
INSERT INTO settings(key, value) VALUES
  ('webListen', '127.0.0.1'),
  ('subListen', '127.0.0.1'),
  ('webURI', 'https://$PUBLIC_HOST$PANEL_PATH'),
  ('subURI', 'https://$PUBLIC_HOST$SUB_PATH');
SQL

if [ -n "${ADMIN_PASSWORD:-}" ]; then
  ./sui admin -username "${ADMIN_USER:-admin}" -password "$ADMIN_PASSWORD" >/dev/null
elif [ "$NEW_DB" = 1 ]; then
  ADMIN_PASSWORD="$(gen 20)"
  ./sui admin -username "${ADMIN_USER:-admin}" -password "$ADMIN_PASSWORD" >/dev/null
  echo "start: generated admin login ${ADMIN_USER:-admin} / $ADMIN_PASSWORD (set ADMIN_PASSWORD to choose your own)"
fi

echo "start: panel      https://$PUBLIC_HOST$PANEL_PATH"
echo "start: sub base   https://$PUBLIC_HOST$SUB_PATH"
echo "start: ws inbound listen 127.0.0.1:<10000-19999>, path /$WS_SECRET/<port>"

pids=()
./sui & pids+=($!)
caddy run --config "${CADDYFILE:-/etc/caddy/Caddyfile}" --adapter caddyfile & pids+=($!)

if [ -n "${AGENT_ENDPOINT:-}" ] && [ -n "${AGENT_TOKEN:-}" ]; then
  export AGENT_DISABLE_AUTO_UPDATE=true
  export AGENT_DISABLE_WEB_SSH="${AGENT_DISABLE_WEB_SSH:-true}"
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
