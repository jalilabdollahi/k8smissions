# The Garbled Token

## What Was Broken
The Secret's `data.token` was base64 of a base64 string — double-encoded. When the app decoded the Secret value, it received the base64 string `c3VwZXJzZWNyZXQtYXBpLXRva2VuLTEyMzQ1` instead of the real token `supersecret-api-token-12345`.

## The Fix
Store `echo -n 'actual-value' | base64` in the `data` field. Or use `stringData` — it takes plain text and Kubernetes handles the encoding automatically.

## Why It Matters
`data` vs `stringData`: `data` requires base64 values; `stringData` takes plain strings. Both end up stored as base64 in etcd. `stringData` is write-only — you won't see it in `kubectl get secret -o yaml`; only `data` is returned.

## Pro Tip
Use `kubectl create secret generic <name> --from-literal=token=<value>` to let kubectl handle encoding. For YAML manifests, prefer `stringData` to avoid manual base64.

## Concepts
Secret, base64, data, stringData, encoding, kubectl create secret
