## What was broken

`log-shipper` crash-looped with `cannot get resource "pods/log"`, although its Role `log-reader` let it `get` and `list` pods. The first request in the script (`GET /pods/orders`) succeeded, which is why the pod started and then died a moment later on the log call.

## Why Kubernetes behaved this way

RBAC rules match on resource names, and subresources are separate names: `pods`, `pods/log`, `pods/exec`, `pods/portforward`, `pods/status`. Granting `get pods` never implies `get pods/log`. The API server answers 403 and writes the exact user, verb and resource in the message, which is the line to read.

## The fix

Add one rule for `pods/log` with the verb `get` to the existing Role. Nothing else needs to change. The Pod then backs off less after a restart; `kubectl rollout restart` skips the wait.

## In production

Use `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa>` to audit what an identity really holds. The tempting shortcuts, `resources: ["*"]` or binding `view`/`cluster-admin`, also open Secrets or other namespaces. Log shippers belong on narrow Roles, and a log agent for a whole cluster would use a ClusterRole limited to `pods/log` instead of a wildcard.

## Commands worth remembering

- `kubectl auth can-i get pods/log --as=system:serviceaccount:k8smissions:log-shipper`
- `kubectl auth can-i --list --as=system:serviceaccount:k8smissions:log-shipper -n k8smissions`
- `kubectl explain role.rules`
