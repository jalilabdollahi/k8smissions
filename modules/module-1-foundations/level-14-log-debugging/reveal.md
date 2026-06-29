## What went wrong

The official PostgreSQL image requires `POSTGRES_PASSWORD` to be set before it starts. This is a deliberate safety check — PostgreSQL refuses to run with an empty superuser password. Since no env vars are defined, it exits on every start.

## Fix

Add the required environment variable in manifest.yaml:

```yaml
env:
- name: POSTGRES_PASSWORD
  value: "mysecretpassword"
```

## Why this matters

This level teaches the most important debugging habit: read the application logs first. The log said exactly what was missing. Skipping the logs and guessing the problem wastes time — the application already told you the answer.