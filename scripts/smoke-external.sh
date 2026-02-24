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
sleep 6
curl -fsS http://localhost:8082/health >/dev/null

echo "smoke-external: store healthy"
