`search-api` serves one request at a time. Under the generator's load a health check waits behind several 600 ms searches and takes 1.5 seconds or more, while both probes give up after the default 1 second, so the pods are marked unready and then restarted.

1. `kubectl -n k8smissions describe pod -l app=search-api` shows `Liveness probe failed: ... context deadline exceeded (Client.Timeout exceeded ...)`.
2. Timing `wget` against `/healthz` from `search-load` confirms about 1.5 s.
3. Raise `timeoutSeconds` on both probes to about 10 (`kubectl patch deploy search-api --type=json ...`) and wait for the rollout.
