#!/usr/bin/env bash
set -euo pipefail

# Collect remote runtime evidence for foxmemory-store write->search failures.
# Usage:
#   SSH_TARGET=kite@192.168.0.118 BASE_URL=http://192.168.0.118:8082 ./scripts/r720-debug-collect.sh

SSH_TARGET="${SSH_TARGET:-}"
BASE_URL="${BASE_URL:-http://192.168.0.118:8082}"
STORE_CONTAINER="${STORE_CONTAINER:-foxmemory-store}"
VECTOR_CONTAINER="${VECTOR_CONTAINER:-qdrant}"
ART_ROOT="${ART_ROOT:-artifacts/r720}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${ART_ROOT}/debug-${TS}"

mkdir -p "$OUT_DIR"

if [[ -z "$SSH_TARGET" ]]; then
  echo "ERROR: SSH_TARGET is required (e.g. kite@192.168.0.118 or ssh alias)." >&2
  exit 2
fi

MARKER="foxprobe-${TS}"

{
  echo "timestamp=$(date -Iseconds)"
  echo "ssh_target=${SSH_TARGET}"
  echo "base_url=${BASE_URL}"
  echo "store_container=${STORE_CONTAINER}"
  echo "vector_container=${VECTOR_CONTAINER}"
  echo "marker=${MARKER}"
} > "${OUT_DIR}/context.env"

# 1) Remote logs
ssh "$SSH_TARGET" "docker logs --since 15m ${STORE_CONTAINER} 2>&1 | tail -n 500" > "${OUT_DIR}/store.log" || true
ssh "$SSH_TARGET" "docker logs --since 15m ${VECTOR_CONTAINER} 2>&1 | tail -n 500" > "${OUT_DIR}/vector.log" || true
ssh "$SSH_TARGET" "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" > "${OUT_DIR}/docker-ps.txt" || true

# 2) Probe write/search path against live endpoint
curl -sS "${BASE_URL}/health" > "${OUT_DIR}/health.json" || true

curl -sS -X POST "${BASE_URL}/memory.write" \
  -H 'content-type: application/json' \
  -d "{\"messages\":[{\"role\":\"user\",\"content\":\"${MARKER}\"}],\"user_id\":\"r720-acceptance\"}" \
  > "${OUT_DIR}/write.json" || true

curl -sS -X POST "${BASE_URL}/memory.search" \
  -H 'content-type: application/json' \
  -d "{\"query\":\"${MARKER}\",\"user_id\":\"r720-acceptance\"}" \
  > "${OUT_DIR}/search.json" || true

# 3) Run acceptance capture (remote-target mode)
BASE_URL="$BASE_URL" DO_RESTART=0 bash scripts/r720-capture-acceptance.sh > "${OUT_DIR}/acceptance-wrapper.log" 2>&1 || true

echo "DEBUG_ARTIFACTS=${OUT_DIR}"
