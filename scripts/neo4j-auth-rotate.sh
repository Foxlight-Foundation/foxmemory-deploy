#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

usage() {
  cat <<USAGE
Usage: $0 --new-pass '<password>' [--no-restart]

Rotates Neo4j password using compose/.env contract, then verifies login.
USAGE
}

NEW_PASS=""
RESTART=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --new-pass) NEW_PASS="$2"; shift 2;;
    --no-restart) RESTART=0; shift;;
    -h|--help) usage; exit 0;;
    *) echo "unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -n "$NEW_PASS" ]] || { echo "--new-pass is required"; usage; exit 1; }
require_cmd docker
require_env NEO4J_PASSWORD

# Update .env source-of-truth
if grep -q '^NEO4J_PASSWORD=' "$ENV_FILE"; then
  sed -i.bak "s#^NEO4J_PASSWORD=.*#NEO4J_PASSWORD=${NEW_PASS}#" "$ENV_FILE"
else
  echo "NEO4J_PASSWORD=${NEW_PASS}" >> "$ENV_FILE"
fi
if grep -q '^NEO4J_AUTH=' "$ENV_FILE"; then
  sed -i.bak "s#^NEO4J_AUTH=.*#NEO4J_AUTH=neo4j/${NEW_PASS}#" "$ENV_FILE"
else
  echo "NEO4J_AUTH=neo4j/${NEW_PASS}" >> "$ENV_FILE"
fi

echo "[rotate] updated $ENV_FILE"

if [[ "$RESTART" -eq 1 ]]; then
  compose stop "$SERVICE_STORE" || true

  # Temporarily disable auth, set password, restore auth contract
  python3 - <<PY
from pathlib import Path
p=Path("$COMPOSE_FILE")
s=p.read_text()
s=s.replace('NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}','NEO4J_AUTH: none')
p.write_text(s)
PY

  compose up -d "$SERVICE_NEO4J"
  sleep 10

  CONTAINER="${NEO4J_CONTAINER:-foxmemory-neo4j}"
  docker exec "$CONTAINER" cypher-shell "ALTER USER neo4j SET PASSWORD '$NEW_PASS' CHANGE NOT REQUIRED;" >/tmp/neo4j-rotate.out 2>&1 || {
    echo "[rotate] failed to set password"; tail -n 30 /tmp/neo4j-rotate.out; exit 1;
  }

  python3 - <<PY
from pathlib import Path
p=Path("$COMPOSE_FILE")
s=p.read_text()
s=s.replace('NEO4J_AUTH: none','NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}')
p.write_text(s)
PY

  compose up -d "$SERVICE_NEO4J" "$SERVICE_STORE"
  sleep 10
fi

"$(dirname "$0")/neo4j-auth-preflight.sh"
echo "NEO4J_PASSWORD_ROTATED_OK"
