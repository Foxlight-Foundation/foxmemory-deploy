# foxmemory-deploy

Deployment recipes for the FoxMemory stack.

If you’re new to infra: this repo is the "how to run it" layer. It does not contain core API code; it contains Docker Compose topologies and runbooks.

## What this repo is for

- Start FoxMemory services with sane defaults
- Choose a topology based on your environment
- Provide smoke tests and operations runbooks

## Topologies

1. **`compose.one.yml`** — one-node stack (`infer` + `store`)
2. **`compose.split.yml`** — split deployment across environments
3. **`compose.external.yml`** — only `store`; inference from an external OpenAI-compatible provider

---

## Quick start (one-node)

```bash
cp .env.example .env
docker compose -f compose.one.yml up -d
```

Health checks:

```bash
curl -s http://localhost:8081/health
curl -s http://localhost:8082/health
```

Stop:

```bash
docker compose -f compose.one.yml down -v
```

---

## Smoke tests

### One-node smoke

```bash
bash scripts/smoke-one.sh
```

### External-provider smoke

```bash
cp .env.example .env
# set OPENAI_BASE_URL and OPENAI_API_KEY for your provider
bash scripts/smoke-external.sh
```

---

## Env file basics

The `.env` file configures image tags, model names, and provider keys.

Most important fields:

- `FOXMEMORY_INFER_IMAGE`
- `FOXMEMORY_STORE_IMAGE`
- `OPENAI_BASE_URL`
- `OPENAI_API_KEY`
- `MEM0_LLM_MODEL`
- `MEM0_EMBED_MODEL`

---

## Docs to read next

- `docs/RUNBOOK.md` — step-by-step operations guide

## License

MIT (see `LICENSE` in service repos)
