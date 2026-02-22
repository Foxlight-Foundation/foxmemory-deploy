# Runbook

## Start
```bash
docker compose -f compose.one.yml up -d
```

## Stop
```bash
docker compose -f compose.one.yml down
```

## Health checks
```bash
curl -s http://localhost:8081/health
curl -s http://localhost:8082/health
```

## Troubleshooting
- image pull errors: verify registry auth/tag
- service unavailable: inspect `docker compose logs`
