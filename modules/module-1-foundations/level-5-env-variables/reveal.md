## What went wrong

The container runs a shell script that checks `$DATABASE_URL`. If the variable is empty, it prints an error and calls `exit 1`. Since no `env` is defined in the pod spec, the variable is never set.

## Fix

Add the `env` section under the container in manifest.yaml:

```yaml
env:
- name: DATABASE_URL
  value: postgres://localhost/app
```

## Why this matters

In production, sensitive values like connection strings should never be hardcoded into a pod spec. They belong in a Secret, then referenced with `secretKeyRef`. For this lab, a plain value is fine.