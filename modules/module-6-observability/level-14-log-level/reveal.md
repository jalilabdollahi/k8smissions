## What went wrong

The container runs with `LOG_LEVEL: DEBUG`, emitting approximately one log line every 100ms (~600 lines/minute, ~864,000 lines/day). At this volume, important log entries (errors, warnings) are hidden in noise and log storage costs become significant.

## Fix

```yaml
env:
- name: LOG_LEVEL
  value: INFO
```

## Why this matters

Log levels define the minimum severity of events to emit. The conventional hierarchy: `DEBUG < INFO < WARN < ERROR < FATAL`. In production, `INFO` is the standard — it captures application lifecycle events and errors without debug noise. Use a `ConfigMap` to manage the log level value so you can change it across deployments without rebuilding the image. Some teams implement dynamic log level changes via an API endpoint, allowing temporary DEBUG logging during incident investigation without a pod restart.