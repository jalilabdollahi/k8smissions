**What was broken.** The platform library 4.2.0 moved the warm-up cache size into a shared ConfigMap, `lib-defaults`, with `CACHE_MB=90`. All three services read it through `envFrom` and have a 64Mi limit, so each was OOM-killed while still warming up, restarted, and was killed again. `svc-gamma` had a second, independent problem: its export spool of 40 MB was written to an `emptyDir` with `medium: Memory`.

**The evidence.** `describe pod` showed `Last State: Terminated, Reason: OOMKilled, Exit Code 137` on all three. `logs --previous` ended at `cache at 55 MB`, well before the target. After the cache fix, `svc-gamma` was still killed although its logs showed a small heap: the spool log line came first, and the tmpfs held 40 MB of the 64.

**Why Kubernetes behaved this way.** The memory limit is a cgroup limit on everything the container touches: heap, page cache it dirties, and tmpfs pages. A memory-backed `emptyDir` is RAM, so writing to it spends the memory limit even though it looks like a disk. The kubelet re-reads `envFrom` only when a container starts, so editing the ConfigMap changes nothing for running containers.

**The fix.** A cache that fits (about 24 MB), a restart for every consumer of the ConfigMap, and a disk-backed `emptyDir` for the spool (or a limit that covers it).

**In production.** Size limits from observed usage (`kubectl top pod`, container memory metrics), keep shared defaults per workload class rather than one number for all, and use `sizeLimit` on memory volumes so they fail loudly. A shared ConfigMap is a blast radius: roll it out with a canary.

**Commands to remember.** `kubectl describe pod` (Last State), `kubectl logs --previous`, `kubectl top pod`, `kubectl rollout restart deploy/<name>`.
