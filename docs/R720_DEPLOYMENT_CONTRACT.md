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

## Operator Validation Command (remote-target mode)
When stack is up on R720 and reachable, run acceptance from any control host:

```bash
cd foxmemory-deploy
BASE_URL=http://<r720-host-or-domain>:8082 DO_RESTART=0 bash scripts/r720-capture-acceptance.sh
```

Expected success signal:
- command exits `0`
- artifacts directory contains `exit_code.txt` with `0`

## Next Action
Implement `scripts/r720-preflight.sh` for env/docker/disk/network/health prerequisites (Workstream G.2).

## Operator handoff packet (required for remote acceptance)
Before closing G.4 from a non-R720 runtime, provide a minimal handoff packet:
- `BASE_URL` for the live R720 memory endpoint (example: `http://<r720-host>:8082`)
- Confirmation that deployment is up (`bash scripts/r720-deploy.sh deploy` already run on R720)
- One capture command and artifact path:
  - `BASE_URL=<r720-endpoint> DO_RESTART=0 bash scripts/r720-capture-acceptance.sh`
- PASS condition: wrapper exits `0` and artifact folder contains `exit_code.txt=0`.

Why: this removes ambiguity about “reachable endpoint” and turns closure of G.4 into an auditable evidence handoff.

## Retry ownership contract (acceptance/deploy tooling)
- Exactly one layer may own retries for a given probe/action path, and it must use bounded exponential backoff with jitter.
- Wrapper layers must not add their own retry loops on top; they should emit explicit `BLOCKED` state when endpoint reachability is absent.
- Rationale: stacked retries turn partial dependency failures into noisy retry storms and delay operator diagnosis.

## Timeout budget contract (acceptance/deploy tooling)
- Every probe/action path must declare an explicit timeout budget (connect timeout, total request timeout, and max end-to-end step duration).
- Timeouts should fail fast enough to preserve operator feedback loops (minutes, not tens of minutes) while still tolerating short transient slowness.
- On timeout, tooling must capture deterministic artifacts (`context.env`, `output.log`, `exit_code.txt`) and return a clear failure state (`FAIL`/`BLOCKED`) without hidden retries.
- Rationale: bounded timeouts prevent stuck health checks from silently consuming the deploy window and make rollback decisions auditable.

## Circuit-breaker probe contract (remote acceptance)
- After repeated unreachable endpoint checks, acceptance wrappers should enter a temporary open state (`BLOCKED`) instead of continuously probing.
- Recovery attempts should use bounded half-open probes at a fixed minimum interval (cooldown) until a successful probe closes the breaker.
- The breaker state transition (`OPEN` -> `HALF_OPEN` -> `CLOSED`) must be reflected in artifacts/log output so operators can distinguish dependency outage from script failure.
- Rationale: fail-fast circuit behavior reduces noisy retries and makes dependency recovery observable and trustable.
