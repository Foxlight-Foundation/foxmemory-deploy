#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

require_cmd docker
require_env NEO4J_PASSWORD
PASS="$(env_get NEO4J_PASSWORD)"
CONTAINER="${NEO4J_CONTAINER:-foxmemory-neo4j}"

echo "[preflight] checking neo4j auth via cypher-shell..."
if docker exec "$CONTAINER" cypher-shell -u neo4j -p "$PASS" "RETURN 1 as ok;" >/tmp/neo4j-preflight.out 2>&1; then
  echo "NEO4J_AUTH_OK"
else
  echo "NEO4J_AUTH_FAIL"
  tail -n 20 /tmp/neo4j-preflight.out || true
  exit 1
fi
