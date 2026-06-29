## What went wrong

The container has `limits.memory: 64Mi` but consumes more than that at runtime. Each time memory usage crosses the limit, the kernel sends SIGKILL (exit code 137). The event stream shows the restart history: `Killing container with id ... OOMKilled`.

## Fix

```yaml
resources:
  requests:
    memory: 32Mi
  limits:
    memory: 256Mi
```

## Why this matters

Cluster events are a first-class observability tool and the primary source of truth for incident timelines. `kubectl get events --sort-by=.lastTimestamp` gives you a chronological view. Key event fields: `reason` (what happened), `message` (detail), `count` (how many times), `firstTime`/`lastTime`. Events have a default TTL of 1 hour — for longer retention you need an event exporter (e.g., `kube-event-exporter` or writing to a log store). The SRE discipline of writing post-mortems starts with this event timeline: what happened, when, and why.