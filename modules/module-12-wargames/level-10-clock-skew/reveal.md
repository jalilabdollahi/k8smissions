Three independent faults, hidden behind each other:

1. `auth` runs with `TZ=PST8` and writes `iat`/`exp` as local wall-clock strings without a zone. `api` reads them as UTC, so every token looks 8 hours old. Remove the variable: `kubectl -n k8smissions set env deploy/auth TZ-`.
2. `auth` issues tokens that live 5 seconds and `api` has `LEEWAY_SECONDS=0`. Raise the lifetime (`kubectl set env deploy/auth TOKEN_TTL_SECONDS=300`) and/or the leeway (`kubectl set env deploy/api LEEWAY_SECONDS=30`), but stay well below two hours.
3. The signing key was rotated on `auth` (`auth-signing`, kid 2026-10) and not on `api` (`api-verify`, kid 2026-04). Copy the new key into `api-verify` and `kubectl rollout restart deploy/api` so the pods re-read it. This only shows up once the expiry errors are gone, because `api` checks expiry before the signature.
