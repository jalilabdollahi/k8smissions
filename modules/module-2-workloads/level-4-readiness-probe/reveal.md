1. `kubectl -n k8smissions logs deploy/catalog` shows the app listens at once and warms for 20s; `curl` from the `probe` pod gets 503 on `/` and on `/ready` during that time.
2. Without a readiness probe a pod is Ready as soon as the container starts, so the Service routes to it immediately.
3. Add a `readinessProbe` (`httpGet` on `/ready`, port 8080, `periodSeconds: 2`) to the `app` container. Probing `/` also works because it returns 503 while cold.
4. Wait for the rollout; new pods now join the endpoints only after the cache is warm.
