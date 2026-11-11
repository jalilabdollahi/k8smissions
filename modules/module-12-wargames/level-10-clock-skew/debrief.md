**What was broken.** Three faults stacked on one error message. `auth` ran with `TZ=PST8`, so the `iat` and `exp` strings it signed were eight hours behind UTC, and `api` parses claims as UTC. Tokens also lived only 5 seconds while `api` allowed zero leeway. Behind both of those, the signing key had been rotated on `auth` only, so even a correctly timed token had a bad signature.

**The evidence.** `exec deploy/auth -- date` printed a PST time while `exec deploy/api -- date` printed UTC, although both pods sit on the same kind of node. The `auth` log showed `exp` values hours in the past. `kubectl get deploy -o yaml` showed `TZ`, `TOKEN_TTL_SECONDS=5` and `LEEWAY_SECONDS=0`. After the time fixes the error changed from `token expired` to `bad signature`; `api` checks expiry first, which is why the signature fault stayed invisible.

**Why Kubernetes behaved this way.** Containers share the node's kernel clock, so real skew between pods does not exist; what differs is each process's idea of local time. A timestamp without a zone is ambiguous, and an environment variable is read at start, which is why the Secret fix needs a restart of `api`.

**The fix.** Unset `TZ` on `auth`, pick a TTL and leeway that fit real client latency (minutes, not hours), copy the current key into `api-verify`, and restart `api`.

**In production.** Use RFC 3339 timestamps with a zone, or integer epoch seconds, as JWT does. Keep leeway to a few seconds to a minute; a huge leeway silently turns expiry off. Rotate keys with an overlap period (accept old and new) and roll consumers via a hash in the pod template.

**Commands to remember.** `kubectl exec <pod> -- date`, `kubectl set env deploy/<name> VAR-` (removes a variable), `kubectl get secret <name> -o jsonpath='{.data.key}' | base64 -d`.
