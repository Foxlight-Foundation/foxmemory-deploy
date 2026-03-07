# Neo4j Auth Runbook (Environment-Agnostic)

## Goals
- Keep a single source of truth in `.env`
- Prevent auth drift between compose config and Neo4j persisted auth state
- Provide deterministic preflight and rotation helpers

## Files
- `scripts/lib/common.sh`
- `scripts/neo4j-auth-preflight.sh`
- `scripts/neo4j-auth-rotate.sh`

## Required env contract
In `.env`:
- `NEO4J_PASSWORD=<secret>`
- `NEO4J_AUTH=neo4j/${NEO4J_PASSWORD}`

## Preflight check
```bash
scripts/neo4j-auth-preflight.sh
```
Expected output: `NEO4J_AUTH_OK`

## Rotate password safely
```bash
scripts/neo4j-auth-rotate.sh --new-pass 'your-new-strong-password'
```
Expected output:
- `NEO4J_AUTH_OK`
- `NEO4J_PASSWORD_ROTATED_OK`

## Notes
- These scripts avoid hardcoded host paths by deriving compose/env paths from script location, with overrides via `PROJECT_DIR`, `COMPOSE_FILE`, and `ENV_FILE`.
- If your container names differ, set `NEO4J_CONTAINER` before running.
