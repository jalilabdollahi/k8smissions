`gateway` is a victim: its readiness probe calls `auth`, so it heals by itself once the stack below it works. The faults, bottom up:

1. **auth crash loop.** `logs --previous` says it cannot read `/secrets/jwt-secret`. The Secret holds the key `JWT_SECRET`, and a Secret volume creates one file per key. Add the key `jwt-secret` with the same value (or set `SECRET_FILE=/secrets/JWT_SECRET` on the Deployment).
2. **users-cache stuck in ContainerCreating.** The Deployment mounts ConfigMap `users-seed-v2`, which does not exist; the real one is `users-seed`. Fix the volume's `configMap.name`.
3. **users-cache Service port.** `targetPort: 8081` but the container listens on 8080, so `auth` gets `connection refused` and answers 504. Set `targetPort: 8080`.

Restarting or scaling `gateway` changes nothing. Afterwards restart `auth` if it is in backoff.
