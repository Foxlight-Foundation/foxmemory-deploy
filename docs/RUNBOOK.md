# Runbook

## Start one-node mode
```bash
cp .env.example .env
docker compose -f compose.one.yml up -d
```

## Health checks
```bash
curl -s http://localhost:8081/health
curl -s http://localhost:8082/health
```

## Basic memory write/search
```bash
curl -s -X POST http://localhost:8082/v1/memories \
  -H 'content-type: application/json' \
  -d '{"user_id":"demo","messages":[{"role":"user","content":"remember I prefer concise responses"}]}'

curl -s -X POST http://localhost:8082/v1/memories/search \
  -H 'content-type: application/json' \
  -d '{"user_id":"demo","query":"response preference","top_k":5}'
```

## Stop
```bash
docker compose -f compose.one.yml down
```
