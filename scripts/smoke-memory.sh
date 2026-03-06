#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Create .env from .env.example and set OPENAI_BASE_URL/OPENAI_API_KEY first." >&2
  exit 1
fi

./scripts/validate-env.sh
cleanup(){ docker compose -f compose.external.yml down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker compose -f compose.external.yml up -d

health_url="http://localhost:8082/health"
max_attempts=8
backoff=2
attempt=1
while [ "$attempt" -le "$max_attempts" ]; do
  if curl -fsS "$health_url" >/dev/null; then
    break
  fi
  if [ "$attempt" -eq "$max_attempts" ]; then
    echo "smoke-memory: health check failed after ${max_attempts} attempts" >&2
    docker compose -f compose.external.yml ps >&2 || true
    docker compose -f compose.external.yml logs --tail=120 store >&2 || true
    exit 1
  fi
  sleep "$backoff"
  backoff=$((backoff * 2))
  attempt=$((attempt + 1))
done

echo "smoke-memory: health OK"

echo "smoke-memory: write"
write_resp=$(curl -fsS -X POST http://localhost:8082/memory.write \
  -H 'content-type: application/json' \
  -d '{"user_id":"smoke","text":"My favorite drink is jasmine tea. I care about idempotency in APIs."}')
echo "$write_resp"

echo "smoke-memory: search"
search_resp=$(curl -fsS -X POST http://localhost:8082/memory.search \
  -H 'content-type: application/json' \
  -d '{"user_id":"smoke","query":"favorite drink","limit":5}')
echo "$search_resp"

if ! echo "$search_resp" | grep -qi "tea"; then
  echo "smoke-memory: expected retrieval signal missing" >&2
  exit 1
fi

mem_id=$(SEARCH_RESP="$search_resp" python3 - <<'PY'
import json, os
obj=json.loads(os.environ.get('SEARCH_RESP','{}'))
rows=obj.get('results') or []
print((rows[0] or {}).get('id','') if rows else '')
PY
)
if [ -z "$mem_id" ]; then
  echo "smoke-memory: could not extract memory id for delete check" >&2
  exit 1
fi

echo "smoke-memory: delete ($mem_id)"
delete_resp=$(curl -fsS -X DELETE "http://localhost:8082/v1/memories/$mem_id")
echo "$delete_resp"

echo "smoke-memory: error-path (get deleted id should 404)"
status=$(curl -s -o /tmp/smoke-memory-get.json -w "%{http_code}" "http://localhost:8082/v1/memories/$mem_id")
body=$(cat /tmp/smoke-memory-get.json)
echo "$body"
if [ "$status" -eq 404 ]; then
  :
elif [ "$status" -eq 200 ] && [ "$body" = "null" ]; then
  :
else
  echo "smoke-memory: expected 404 or 200+null after delete, got status=$status body=$body" >&2
  exit 1
fi

echo "smoke-memory: PASS"
