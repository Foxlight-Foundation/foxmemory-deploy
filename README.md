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
bash scripts/validate-env.sh
bash scripts/smoke-external.sh
```

---

## Env file basics

The `.env` file configures image tags, model names, and provider keys.

### Required environment variables

| Variable | Purpose | Consumed by | Example |
|---|---|---|---|
| `FOXMEMORY_INFER_IMAGE` | Infer container image tag | Docker Compose (`infer`) | `docker.io/foxlightfoundation/foxmemory-infer:latest` |
| `FOXMEMORY_STORE_IMAGE` | Store container image tag | Docker Compose (`store`) | `docker.io/foxlightfoundation/foxmemory-store:latest` |
| `OLLAMA_BASE_URL` | Local model runtime URL for infer | `infer` service | `http://host.docker.internal:11434` |
| `OLLAMA_EMBED_MODEL` | Embedding model name for infer | `infer` service | `nomic-embed-text` |
| `OLLAMA_CHAT_MODEL` | Chat model name for infer | `infer` service | `llama3.1:8b` |
| `INFER_API_KEY` | API key accepted by infer and forwarded to store in one-node compose | `infer` service; one-node `store` auth wiring | `change-me` |
| `OPENAI_BASE_URL` | OpenAI-compatible base URL for store calls | `store` service | `http://infer:8081/v1` |
| `OPENAI_API_KEY` | Provider API key used by store | `store` service | `change-me` |
| `MEM0_LLM_MODEL` | LLM model used for memory reasoning | `store` service | `gpt-4.1-nano` |
| `MEM0_EMBED_MODEL` | Embedding model used by store | `store` service | `text-embedding-3-small` |
| `QDRANT_URL` | Canonical Qdrant endpoint URL | store runtime (where supported) | `http://qdrant:6333` |
| `QDRANT_API_KEY` | Qdrant auth key (optional) | store runtime | `` |
| `QDRANT_COLLECTION` | Collection name for memory vectors | `store` service | `foxmemory` |

Backward-compatible variables still present in some scripts/builds:

- `QDRANT_HOST`
- `QDRANT_PORT`

---

## Docs to read next

- `docs/RUNBOOK.md` — step-by-step operations guide

## License

MIT (see `LICENSE` in service repos)
