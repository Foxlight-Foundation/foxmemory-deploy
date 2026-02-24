#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing .env (copy from .env.example first)." >&2
  exit 1
fi

required=(
  OPENAI_BASE_URL
  OPENAI_API_KEY
  MEM0_LLM_MODEL
  MEM0_EMBED_MODEL
  QDRANT_COLLECTION
)

# At least one Qdrant endpoint form must be present
has_qdrant_url=0
has_qdrant_hostport=0

if grep -Eq '^QDRANT_URL=.+$' "$ENV_FILE"; then
  has_qdrant_url=1
fi
if grep -Eq '^QDRANT_HOST=.+$' "$ENV_FILE" && grep -Eq '^QDRANT_PORT=.+$' "$ENV_FILE"; then
  has_qdrant_hostport=1
fi

missing=()
for key in "${required[@]}"; do
  if ! grep -Eq "^${key}=.+$" "$ENV_FILE"; then
    missing+=("$key")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing required env vars in .env: ${missing[*]}" >&2
  exit 1
fi

if [ "$has_qdrant_url" -eq 0 ] && [ "$has_qdrant_hostport" -eq 0 ]; then
  echo "Missing Qdrant endpoint: set QDRANT_URL or both QDRANT_HOST and QDRANT_PORT." >&2
  exit 1
fi

echo "env-validate: OK"
