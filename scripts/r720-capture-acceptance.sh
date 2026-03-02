#!/usr/bin/env bash
set -euo pipefail

# Capture acceptance evidence for R720 cutover runs.
# Usage:
#   BASE_URL=https://memory.example.com ./scripts/r720-capture-acceptance.sh
#   OUT_DIR=artifacts/r720 BASE_URL=http://localhost:8082 ./scripts/r720-capture-acceptance.sh

OUT_DIR="${OUT_DIR:-artifacts/r720}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$OUT_DIR/acceptance-$STAMP"
mkdir -p "$RUN_DIR"

BASE_URL="${BASE_URL:-http://localhost:8082}"
DO_RESTART="${DO_RESTART:-0}"

{
  echo "timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')"
  echo "base_url=$BASE_URL"
  echo "do_restart=$DO_RESTART"
} > "$RUN_DIR/context.env"

set +e
BASE_URL="$BASE_URL" DO_RESTART="$DO_RESTART" bash scripts/r720-acceptance.sh >"$RUN_DIR/output.log" 2>&1
RC=$?
set -e

echo "$RC" > "$RUN_DIR/exit_code.txt"

if [ "$RC" -eq 0 ]; then
  echo "PASS: acceptance evidence captured at $RUN_DIR"
else
  echo "FAIL($RC): acceptance evidence captured at $RUN_DIR"
fi

exit "$RC"
