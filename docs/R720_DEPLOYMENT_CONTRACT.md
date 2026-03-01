# R720 Deployment Target Contract (Workstream G.1)

Status: draft v1 (ready for preflight scripting)
Date: 2026-03-01

## Objective
Deploy foxmemory as a self-hosted mem0 replacement on R720 with clear boundaries, deterministic startup checks, and rollback safety.

## Deployment Mode
- Primary mode: `compose.external.yml`
- Reason: keeps inference provider pluggable via OpenAI-compatible endpoint while running local `store + qdrant`.

## Runtime Topology
- `foxmemory-store` (API): `:8082`
- `qdrant` (vector DB): `:6333`
- Internal service dependency: `store -> qdrant:6333`

## Network / Exposure
- Preferred exposure: private LAN + tunnel/proxy at edge (no raw public Docker host exposure).
- Health endpoint required: `GET /health` on store.

## Storage Contract
- Persistent volume required for Qdrant data.
- Target path class: local block storage on R720 (no network filesystem for persistent qdrant data).
- Minimum free-space policy (initial): >= 20 GB free before deployment.

## Secrets Contract
Secrets must not be committed. Source of truth is runtime env/secrets store on R720.

Required runtime values:
- `OPENAI_BASE_URL`
- `OPENAI_API_KEY`
- `MEM0_LLM_MODEL`
- `MEM0_EMBED_MODEL`
- `QDRANT_COLLECTION`

Optional/conditional:
- `QDRANT_API_KEY` (only when Qdrant auth is enabled)

## Startup Contract
- `docker compose -f compose.external.yml up -d` must reach healthy state.
- Readiness gate: bounded retry/backoff against `http://localhost:8082/health`.
- Failure diagnostics required on startup failure:
  - `docker compose ps`
  - `docker compose logs --tail=200 store qdrant`

## Acceptance Criteria (for G.4)
1. Store health is green.
2. Write operation succeeds.
3. Search retrieves expected memory.
4. Delete operation succeeds.
5. Data persists across restart (qdrant volume continuity).

## Rollback Trigger
Rollback if any of:
- Health endpoint unstable for >10 minutes after deploy.
- Write/search/delete acceptance fails.
- Post-restart persistence fails.

## Rollback Action
- Revert to last known good image tags.
- Restart stack.
- Re-run smoke + persistence checks.

## Next Action
Implement `scripts/r720-preflight.sh` for env/docker/disk/network/health prerequisites (Workstream G.2).
