**What was broken.** search-indexer loads a 180Mi index about 25 seconds after it starts. The container had a 128Mi memory limit, so the kernel OOM-killed it at the exact moment the index finished loading, and the Deployment started over. The restart loop never reached a steady state.

**The evidence.** `kubectl describe pod` showed `Last State: Terminated, Reason: OOMKilled, Exit Code: 137`. The misleading part is `kubectl top`: right after a start it shows 15 to 20Mi because the index has not loaded yet. Only samples taken after the load show the real number, and a pod that dies at the load never lets you take one for long. That is also why people reach for a VPA: it watches usage for you and recommends values. Without one, you do the same by hand.

**Why Kubernetes behaved this way.** A memory limit is a hard cgroup ceiling. The kernel does not throttle memory like CPU, it kills. The request is a different thing: the scheduler reserves it and the ResourceQuota counts it. Pods must therefore be sized twice, once so they survive (limit) and once so the cluster is not paying for memory nobody uses (request). The quota here (1Gi of requests, 2Gi of limits) is why simply writing 1Gi into both would have left the third replica unable to start: `kubectl describe rs` shows `exceeded quota`.

**The fix.** Request about the observed working set, limit with around 30% headroom, and scale to 3.

**In production.** Run a VPA in `Off` or `Initial` mode to get recommendations, and compare them to the 95th percentile over a week, not a single sample. Leave extra room for runtime growth such as page cache and GC.

**Worth remembering.**
- `kubectl top pod --containers`
- `kubectl describe pod | grep -A5 "Last State"`
- `kubectl describe resourcequota`
