# Watchtower Phase 1 (Monitor-Only) for FoxMemory

Goal: observe available image updates without mutating running services.

## Why this mode first

- Prevents surprise restarts during active debugging/cutover validation.
- Produces update visibility artifacts before any automation is allowed to restart core memory services.
- Keeps rollback posture simple while confidence is still being built.

## Recommended container policy

- Run Watchtower with `--monitor-only`.
- Use `--label-enable` so only explicitly labeled containers are in scope.
- Keep `WATCHTOWER_LABEL_TAKE_PRECEDENCE` unset/false in phase 1 so global monitor-only cannot be accidentally bypassed by per-container labels.
- Suppress startup-notification noise in phase 1 (`--no-startup-message`) so alert channels reflect meaningful change.
- Start with labels on non-critical services first; do **not** auto-update store/vector services yet.

## Compose example (phase 1)

```yaml
services:
  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command:
      - --interval
      - "300" # faster visibility loop for validation windows (default is 86400s / 24h)
      - --monitor-only
      - --label-enable
      - --no-startup-message
      - --cleanup
```

## Labeling model

Container must include this label to be monitored:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=true
```

Containers without label remain out of scope in phase 1.

## Exit criteria to move past phase 1

- At least 24h of clean monitor-only operation.
- No unexplained restarts in critical stack.
- Explicit go/no-go decision recorded in deployment notes.

## Source

- Watchtower docs: https://containrrr.dev/watchtower/container-selection/
- Watchtower args: https://containrrr.dev/watchtower/arguments/

## Label immutability caveat (important)

In this environment, container labels are effectively deployment-time state for this workflow.
Do **not** rely on `docker update --label-add` to retroactively fix watch scope; set `com.centurylinklabs.watchtower.enable=true` in compose/service definitions and recreate containers, then verify non-zero `Scanned` in watchtower logs.
