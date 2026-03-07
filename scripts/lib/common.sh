#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$PROJECT_DIR_DEFAULT}"
COMPOSE_FILE="${COMPOSE_FILE:-$PROJECT_DIR/compose.graph.yml}"
ENV_FILE="${ENV_FILE:-$PROJECT_DIR/.env}"
SERVICE_NEO4J="${SERVICE_NEO4J:-neo4j}"
SERVICE_STORE="${SERVICE_STORE:-store}"

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; exit 1; }; }

require_env() {
  local k="$1"
  if ! grep -q "^${k}=" "$ENV_FILE"; then
    echo "missing required env var in $ENV_FILE: $k" >&2
    exit 1
  fi
}

env_get() {
  local k="$1"
  grep -E "^${k}=" "$ENV_FILE" | tail -n1 | cut -d= -f2-
}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}
