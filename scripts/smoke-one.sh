#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cp -f .env.example .env
cleanup(){ docker compose -f compose.one.yml down -v >/dev/null 2>&1 || true; rm -f .env; }
trap cleanup EXIT

docker compose -f compose.one.yml up -d
sleep 8
curl -fsS http://localhost:8082/health >/dev/null
curl -fsS -X POST http://localhost:8082/v1/memories -H 'content-type: application/json' -d '{"user_id":"smoke","messages":[{"role":"user","content":"remember I like tea"}]}' >/dev/null
curl -fsS -X POST http://localhost:8082/v1/memories/search -H 'content-type: application/json' -d '{"user_id":"smoke","query":"tea","top_k":3}' >/dev/null

echo "smoke-one: OK"
