**What was broken.** Two services showed the same symptom, OOMKilled on a 128Mi limit, for opposite reasons. `profile-api` had an unbounded cache (`CACHE_MAX_MB=0`) that grew 2Mi every second. `render-svc` needs a fixed 180Mi template set in memory and had a limit that could never hold it.

**The evidence.** Sampled over time, `profile-api` memory is a straight line upward and the pod dies at the same age every time; its log says `bound=none`. `render-svc` jumps to its limit within seconds of starting, and its log never reaches `template cache warm`. A second sample from `memory.current` distinguishes them: the slope is positive for one and zero for the other.

**Why Kubernetes behaved this way.** The memory limit is a hard cgroup cap: crossing it gets the process OOM-killed, whatever the reason. Kubernetes does not know whether growth is a leak, a cache or a legitimate working set. The shape over time tells you: a leak needs a code or config bound, a plateau needs a bigger limit (and a request that matches it so the scheduler reserves what the pod really uses).

**The fix.** Set the cache bound on `profile-api`; raise the limit and request on `render-svc` to the observed working set plus headroom.

**In production.** Look at `container_memory_working_set_bytes` over days, not at one `kubectl top`. Alert on the slope (`deriv()` or `predict_linear()`) before the kill happens. Raising a limit to silence a leak just moves the page to 3 a.m.; capping a cache the product depends on changes its behaviour, so check what the knob does first.

**Worth remembering.**
- `kubectl exec <pod> -- cat /sys/fs/cgroup/memory.current`
- `kubectl describe pod <pod>` (Last State, Reason: OOMKilled)
- `kubectl set env deployment/<name> --list`
