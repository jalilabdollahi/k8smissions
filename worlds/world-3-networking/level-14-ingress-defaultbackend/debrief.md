# 404 Not Found

## What Was Broken
The Ingress `backend.service.name` was `app-serv` — a truncated typo. The actual Service is `app-service`. The Ingress controller couldn't find the backend service and returned 404 for all matched paths.

## The Fix
Fix the backend service name in the Ingress rules to match the exact Service name. Service names are case-sensitive and must be in the same namespace as the Ingress.

## Why It Matters
Ingress 404 errors have two common root causes: (1) wrong service name/port in backend (controller can't find it) or (2) the Service has no endpoints (selector mismatch). Check both with `kubectl describe ingress` and `kubectl get endpoints`.

## Pro Tip
Use `kubectl describe ingress <name>` — the Events section shows controller errors like 'service not found'. This is faster than reading the raw YAML.

## Concepts
Ingress, backend service, HTTP routing, IngressClass, 404 debug
