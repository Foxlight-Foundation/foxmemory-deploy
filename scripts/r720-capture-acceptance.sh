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

BASE_URL="${BASE_URL:-${R720_BASE_URL:-http://localhost:8082}}"
DO_RESTART="${DO_RESTART:-0}"

{
  echo "timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')"
  echo "base_url=$BASE_URL"
  echo "r720_base_url=${R720_BASE_URL:-}"
  echo "do_restart=$DO_RESTART"
} > "$RUN_DIR/context.env"

# Fast-fail noisy local retries when no stack is actually up.
# Also apply a short cooldown to avoid heartbeat-thrashing with identical local failures.
# Set ALLOW_LOCAL_BASE_URL=1 to bypass this guard for intentional local acceptance runs.
if [[ "$BASE_URL" =~ ^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$ ]] && [[ "${ALLOW_LOCAL_BASE_URL:-0}" != "1" ]]; then
  COOLDOWN_SECONDS="${LOCAL_BLOCK_COOLDOWN_SECONDS:-900}"  # 15m
  LAST_BLOCK_FILE="$OUT_DIR/.last-local-blocked-epoch"
  NOW_EPOCH="$(date +%s)"

  if [[ -f "$LAST_BLOCK_FILE" ]]; then
    LAST_EPOCH="$(cat "$LAST_BLOCK_FILE" 2>/dev/null || echo 0)"
    AGE="$(( NOW_EPOCH - LAST_EPOCH ))"
    if [[ "$AGE" -lt "$COOLDOWN_SECONDS" ]]; then
      echo "BLOCKED: local BASE_URL cooldown active (${AGE}s < ${COOLDOWN_SECONDS}s). Use live R720 BASE_URL with DO_RESTART=0." | tee "$RUN_DIR/output.log"
      RC=2
      echo "$RC" > "$RUN_DIR/exit_code.txt"
      echo "FAIL($RC): acceptance evidence captured at $RUN_DIR"
      exit "$RC"
    fi
  fi

  if ! curl -fsS -m 2 "$BASE_URL/health" >/dev/null 2>&1; then
    echo "$NOW_EPOCH" > "$LAST_BLOCK_FILE"
    echo "BLOCKED: local BASE_URL unreachable ($BASE_URL). Use live R720 BASE_URL with DO_RESTART=0." | tee "$RUN_DIR/output.log"
    RC=2
    echo "$RC" > "$RUN_DIR/exit_code.txt"
    echo "FAIL($RC): acceptance evidence captured at $RUN_DIR"
    exit "$RC"
  fi
fi

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
