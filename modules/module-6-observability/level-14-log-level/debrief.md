# Log Overload

## What Was Broken
The `LOG_LEVEL` environment variable was set to `DEBUG`, causing the application to emit verbose debug logs (10 lines/second). This overwhelmed the log aggregation pipeline and made useful logs impossible to find.

## The Fix
Change `LOG_LEVEL` to `INFO`. For most production systems, INFO is the right default — errors, warnings, and key operations are logged without debug noise.

## Why It Matters
Log verbosity is a common production runbook item. Ideal pattern: use INFO in production, temporarily raise to DEBUG on specific pods using `kubectl set env` for live debugging, then revert. Store LOG_LEVEL in a ConfigMap so you can change it without redeploying.

## Pro Tip
Use a ConfigMap for log level: `envFrom: [{configMapRef: {name: app-config}}]`. Change `kubectl patch configmap app-config -p '{"data":{"LOG_LEVEL":"DEBUG"}}'` then restart pods. Revert with same approach.

## Concepts
environment variables, LOG_LEVEL, log verbosity, ConfigMap, runtime configuration
