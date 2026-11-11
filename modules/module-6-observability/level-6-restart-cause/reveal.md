Three restarts, three different causes.

- `cart-cache`: Last State `OOMKilled`. It caches 192 MB and the LimitRange gives every container 128Mi at most. Set `CACHE_MB` in ConfigMap `cart-cache-config` to something smaller (e.g. 64) and `kubectl -n cart rollout restart deploy/cart-cache`. Raising the limit is refused by the LimitRange.
- `cart-worker`: Reason `Error`, exit code 3, previous log `queue unreachable`. Its `QUEUE_ADDR` is `cart-queue:6397`; the Service listens on 6379. `kubectl -n cart set env deploy/cart-worker QUEUE_ADDR=cart-queue:6379`.
- `cart-reporter`: Reason `Error`, exit 137, and `Unhealthy` plus `Killing` events: the liveness probe dials port 9091 while the app listens on 9090. Patch the probe's port to 9090.
