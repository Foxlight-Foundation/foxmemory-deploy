# FoxMemory Deploy Runbook (n00b-friendly)

This runbook assumes you are new to containers and just want a reliable checklist.

## 0) Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- Ports available: `8081` and `8082`
- Internet access if pulling images from Docker Hub

## 1) Prepare env

```bash
cp .env.example .env
```

Open `.env` and verify values:
- image names point to valid images
- `OPENAI_BASE_URL` points where you think it does
- model names exist in your inference backend

## 2) Start one-node stack

```bash
docker compose -f compose.one.yml up -d
```

## 3) Validate service health

```bash
curl -s http://localhost:8081/health
curl -s http://localhost:8082/health
```

Expected: both return JSON with `ok: true`.

## 4) Validate memory path

Write:

```bash
curl -s -X POST http://localhost:8082/v1/memories \
  -H 'content-type: application/json' \
  -d '{"user_id":"demo","messages":[{"role":"user","content":"remember I prefer concise replies"}]}'
```

Search:

```bash
curl -s -X POST http://localhost:8082/v1/memories/search \
  -H 'content-type: application/json' \
  -d '{"user_id":"demo","query":"response preference","top_k":5}'
```

## 5) Tear down

```bash
docker compose -f compose.one.yml down -v
rm -f .env
```

---

## Common failures and fixes

### A) `service has neither an image nor a build context`

Cause: env vars for image names are missing.

Fix: ensure `.env` exists and includes `FOXMEMORY_INFER_IMAGE` + `FOXMEMORY_STORE_IMAGE`.

### B) `401 Incorrect API key` during memory write

Cause: store is calling a provider that requires a real key, or provider base URL not correctly applied.

Fix:
- verify `OPENAI_BASE_URL`
- verify `OPENAI_API_KEY`
- verify provider accepts OpenAI-compatible API shape

### C) Qdrant connection refused (`127.0.0.1:6333`)

Cause: embedded Qdrant not started or not reachable from store process.

Fix:
- check store logs
- verify image version and entrypoint behavior
- verify qdrant-related env vars

Logs:

```bash
docker compose -f compose.one.yml logs --tail=200 store infer
```

---

## Operational tips

- Pin images to explicit tags in production (avoid `latest`)
- Keep a known-good `.env` template per environment
- Add CI smoke tests for every image publish
