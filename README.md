# foxmemory-deploy

Deployment pack for FoxMemory services.

## Why this exists
This repo makes FoxMemory reproducible for others: one-command local deploy, clear environment config, and documented deployment topologies.

## Deployment modes
1. **One-node mode** (`compose.one.yml`)
   - infer + store together on one host
2. **Split mode** (`compose.split.yml`)
   - infer and store independently deployable

## Quick start
```bash
cp .env.example .env
docker compose -f compose.one.yml up -d
```

Then verify:
```bash
curl -s http://localhost:8081/health
curl -s http://localhost:8082/health
```

## Files
- `compose.one.yml`
- `compose.split.yml`
- `.env.example`
- `docs/RUNBOOK.md`

## Notes
- Current images default to GHCR references.
- Can be switched to Docker Hub tags once registry workflow is updated.
## Automation note
Agent tooling should read `AGENTS.md` first.
If your tool supports custom instruction files, point it to `AGENTS.md` as the canonical source.

