**What was broken.** The symptom sat at the top of a three-tier chain (`gateway` -> `auth` -> `users-cache`) and the causes were at the bottom: `auth` could not find its signing key file because the Secret key was named `JWT_SECRET` while the app reads `jwt-secret`; the `users-cache` pod could not start because its volume named a ConfigMap that does not exist; and the `users-cache` Service forwarded to port 8081 while the container listens on 8080.

**The evidence.** `get pods` shows three different states in three places: `gateway` 0/1 Running, `auth` CrashLoopBackOff, `users-cache` ContainerCreating. `logs --previous` on `auth` names the missing file. `describe pod` on `users-cache` shows `FailedMount ... configmap "users-seed-v2" not found`. After that, the gateway answered 504 with the message `users-cache did not answer (Connection refused)`, which is what a Service with the wrong `targetPort` looks like.

**Why Kubernetes behaved this way.** `gateway`'s readiness probe calls `auth`, so when `auth` has no ready pods the gateway removes itself from its Service: a dependency inside a readiness probe turns one failure into a chain. A Secret mounted as a volume produces one file per key, so a key rename breaks the consumer only at the next container start. A Service with a wrong `targetPort` still gets endpoints; they just refuse connections.

**The fix.** Repair the layers bottom-up and watch each parent recover without being touched. Restarting `gateway` was never going to help.

**In production.** Keep readiness probes local (can this pod serve?) and put dependency checks in monitoring; otherwise one bad pod empties every tier above it. Rename config keys together with their readers.

**Commands to remember.** `kubectl logs <pod> --previous`, `kubectl describe pod` (Events), `kubectl get endpointslices -l kubernetes.io/service-name=<svc>`.
