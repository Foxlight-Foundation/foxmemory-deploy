#!/usr/bin/env bash
set -euo pipefail

# Phase-1 Watchtower rollout: monitor-only, label-scoped, no startup noise.
# Usage:
#   SSH_TARGET=r720-vm bash scripts/r720-watchtower-phase1.sh
# Optional:
#   WATCHTOWER_INTERVAL=300      # default 300s during validation window
#   WATCHTOWER_NAME=watchtower-phase1

: "${SSH_TARGET:?Set SSH_TARGET (for example: r720-vm or user@host)}"
WATCHTOWER_INTERVAL="${WATCHTOWER_INTERVAL:-300}"
WATCHTOWER_NAME="${WATCHTOWER_NAME:-watchtower-phase1}"

read -r -d '' REMOTE <<'EOS' || true
set -euo pipefail
WATCHTOWER_INTERVAL="${WATCHTOWER_INTERVAL}"
WATCHTOWER_NAME="${WATCHTOWER_NAME}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found on remote host" >&2
  exit 2
fi

# idempotent replace
if docker ps -a --format '{{.Names}}' | grep -qx "$WATCHTOWER_NAME"; then
  docker rm -f "$WATCHTOWER_NAME" >/dev/null
fi

docker run -d \
  --name "$WATCHTOWER_NAME" \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e TZ=America/Chicago \
  -e WATCHTOWER_LABEL_ENABLE=true \
  -e WATCHTOWER_MONITOR_ONLY=true \
  containrrr/watchtower:latest \
  --interval "$WATCHTOWER_INTERVAL" \
  --no-startup-message

echo "started:$WATCHTOWER_NAME"
docker ps --filter "name=$WATCHTOWER_NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker logs --tail 60 "$WATCHTOWER_NAME" || true
EOS

ssh "$SSH_TARGET" WATCHTOWER_INTERVAL="$WATCHTOWER_INTERVAL" WATCHTOWER_NAME="$WATCHTOWER_NAME" bash -s <<<"$REMOTE"
