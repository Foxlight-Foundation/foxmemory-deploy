#!/usr/bin/env bash
set -euo pipefail

# End-to-end acceptance checks for R720 self-hosted foxmemory stack.
# Usage:
#   BASE_URL=http://<r720-lan-ip>:8082 DO_RESTART=0 bash scripts/r720-acceptance.sh

BASE_URL="${BASE_URL:-http://localhost:8082}"
USER_ID="${USER_ID:-r720-acceptance}"
MARKER="r720-acceptance-marker-$(date +%s)"
COMPOSE_FILE="${COMPOSE_FILE:-compose.external.yml}"

# Auto: only do local docker restart when targeting localhost.
if [[ -z "${DO_RESTART:-}" ]]; then
  if [[ "$BASE_URL" == http://localhost* || "$BASE_URL" == http://127.0.0.1* ]]; then
    DO_RESTART=1
  else
    DO_RESTART=0
  fi
fi

jfail() {
  echo "[FAIL] $*" >&2
  exit 1
}

echo "[1/6] health"
curl -fsS "$BASE_URL/health" >/dev/null || jfail "health endpoint unavailable"

echo "[2/6] write marker memory via /v1/memories"
MEMORY_IDS=""
for attempt in 1 2 3; do
  FACT_TEXT="For acceptance test attempt $attempt: My unique marker is $MARKER and my favorite tea is oolong."
  ADD_PAYLOAD=$(cat <<JSON
{"user_id":"$USER_ID","messages":[{"role":"user","content":"$FACT_TEXT"}]}
JSON
)
  ADD_OUT=$(curl -fsS -X POST "$BASE_URL/v1/memories" -H 'content-type: application/json' -d "$ADD_PAYLOAD") || jfail "v1 memory add failed"
  MEMORY_IDS=$(echo "$ADD_OUT" | python3 -c 'import sys,json; data=json.load(sys.stdin); print(" ".join([r.get("id","") for r in data.get("results",[]) if r.get("id")]))' 2>/dev/null || true)
  [[ -n "$MEMORY_IDS" ]] && break
  sleep 1
done
[[ -n "$MEMORY_IDS" ]] || jfail "no memory ids returned by add response after retries"

echo "[3/6] verify created memory ids are readable"
for id in $MEMORY_IDS; do
  curl -fsS "$BASE_URL/v1/memories/$id" >/dev/null || jfail "memory id unreadable before restart: $id"
done

echo "[4/6] restart stack (or external restart check)"
if [[ "$DO_RESTART" == "1" ]]; then
  docker compose -f "$COMPOSE_FILE" restart >/dev/null || jfail "compose restart failed"
  sleep 5
  curl -fsS "$BASE_URL/health" >/dev/null || jfail "health failed after restart"
else
  echo "[info] DO_RESTART=0 (BASE_URL=$BASE_URL). Skipping local docker restart; expecting external stack continuity check only."
fi

echo "[5/6] verify memory ids persist after restart"
for id in $MEMORY_IDS; do
  curl -fsS "$BASE_URL/v1/memories/$id" >/dev/null || jfail "memory id missing after restart: $id"
done

echo "[6/6] cleanup marker memory (best-effort)"
for id in $MEMORY_IDS; do
  curl -fsS -X DELETE "$BASE_URL/v1/memories/$id" >/dev/null || true
done

echo "r720-acceptance: PASS"
