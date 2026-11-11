**What was broken.** session-db accepts at most 20 connections. cart-api runs 6 replicas with a pool of 5 each, which asks for 30. The first four pods took all 20 slots, the other two kept getting `ERR too many connections` and never became Ready, so the Service had only some of its pods.

**The evidence.** The cart-api logs said `too many connections` over and over, and session-db's own counters (`active`, `rejected`) showed it sitting at its limit while `rejected` kept growing. The trap came with the obvious fix: a pool of 3 gives 6 x 3 = 18, which is under 20 and looks right, and it even works until the next deploy.

**Why Kubernetes behaved this way.** A rolling update does not replace pods one for one. With `maxSurge: 2` the Deployment starts 2 extra pods before it stops the old ones. Each new pod opens its full pool immediately, while the old pods still hold theirs. At the peak there are 8 pods, so 8 x 3 = 24 connections are wanted and 4 are refused. Pool sizing therefore has to be done for (replicas + surge) x pool, not replicas x pool.

**The fix.** A pool of 2 gives 16 at the peak. The other fix is to keep a pool of 3 and set `maxSurge: 0` so no extra pods exist (a trade of rollout speed for connection budget). Reducing the replica count would also fit, but it throws away capacity the objective requires.

**In production.** Put a pooler (PgBouncer, ProxySQL) between the apps and the database so the connection count no longer scales with pod count, and treat `max_connections` as a budget shared by every Deployment, Job and rollout. Retry with jitter instead of retrying in lockstep.

**Worth remembering.**
- `kubectl get deploy <name> -o jsonpath='{.spec.strategy}'`
- `kubectl set env deployment/<name> KEY=value`
- `kubectl rollout restart deployment/<name>`
