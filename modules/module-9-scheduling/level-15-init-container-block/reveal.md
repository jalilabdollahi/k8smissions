## What went wrong

The init container runs `until nc -z non-existent-db-host 5432; do sleep 5; done` — a loop that exits only when the TCP connection succeeds. The hostname `non-existent-db-host` never resolves, so the loop runs forever. The main container starts only after all init containers exit 0, so it waits indefinitely.

## Fix

```yaml
initContainers:
- name: db-wait
  image: busybox:1.36
  command:
  - /bin/sh
  - -c
  - echo 'DB check skipped - DBaaS mode'; exit 0
```

In production, replace `non-existent-db-host` with the real database Service name once it exists.

## Why this matters

Init containers are designed for exactly this pattern — waiting for a dependency before the main container starts. They run sequentially and must all exit 0 before the main container phase begins. Common uses: wait-for-db, run migrations, copy config files, download secrets. The failure mode is always the same: if the init condition is never met, the main container never starts, the pod stays in `Init:0/1` forever, and `kubectl logs` on the main container returns 'container has not been started'. Always log what you're checking so `kubectl logs -c <init-container-name>` gives diagnostic output.