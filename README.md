# foxmemory-deploy

Deployment pack for FoxMemory.

## Modes
1. `compose.one.yml` — one-node (infer + store-with-embedded-qdrant)
2. `compose.split.yml` — split topology (infer and store on different infrastructure)
3. `compose.external.yml` — store only; inference via external OpenAI-compatible API

## Quick start (one-node)
```bash
cp .env.example .env
docker compose -f compose.one.yml up -d
```

## Verify
```bash
curl -s http://localhost:8081/health
curl -s http://localhost:8082/health
```

## Smoke test
```bash
curl -s -X POST http://localhost:8082/v1/memories \
  -H 'content-type: application/json' \
  -d '{"user_id":"demo","messages":[{"role":"user","content":"I like sci-fi movies"}]}'

curl -s -X POST http://localhost:8082/v1/memories/search \
  -H 'content-type: application/json' \
  -d '{"user_id":"demo","query":"movie preference","top_k":5}'
```

## Design contract
- `foxmemory-store` requires no external container other than optional `foxmemory-infer`.
- Inference integration uses OpenAI-compatible API shape.
- Embedded Qdrant is included in store container for two-container deployments.
