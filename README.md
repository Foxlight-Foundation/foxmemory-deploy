# foxmemory-deploy

Deployment pack for FoxMemory (Node/TS services + Mem0 OSS-compatible store).

## Modes
1. `compose.one.yml` — one-node (qdrant + infer + store)
2. `compose.split.yml` — split topology for Mini/R720 style deployments

## Quick start
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

## Notes
- Uses Docker Hub images by default.
- Configure OPENAI_API_KEY if using OpenAI LLM/embedder path.
- Qdrant persists in named Docker volume.
