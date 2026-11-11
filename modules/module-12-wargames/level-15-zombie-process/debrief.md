**What was broken.** Every request spawned a short-lived helper that was orphaned on purpose (a double fork). The orphans are adopted by the container's PID 1, which here was the Python server, a process that never waits on children it did not start. The dead helpers stayed as zombie entries in the process table, until the per-user limit was reached and the pod could neither fork nor start request threads. Kubernetes saw nothing wrong: the main process was alive, and no probe had been defined.

**The evidence.** `exec <pod> -- ps -o pid,ppid,stat,comm` showed dozens of entries in state `Z` with parent PID 1, growing with every request. The worker log reported `can't start new thread` or the 500 from the failed fork. A pod with `1/1 Ready` and zero restarts is exactly what a pod without probes looks like when it is stuck.

**Why Kubernetes behaved this way.** Containers start the image's command as PID 1, and PID 1 has the init duty of reaping orphans. Ordinary application code does not do that. Readiness and liveness are opt-in: without them, Ready means only that the container process exists. With `shareProcessNamespace: true` the pod's own `pause` container becomes PID 1 of the whole pod and reaps.

**The fix.** Give the pod a reaping PID 1 (`shareProcessNamespace`, or an init such as `tini` in the image), then add a readiness probe so a stuck pod leaves the Service and a liveness probe so it is restarted.

**In production.** Prefer an init process in the image (`tini`, `dumb-init`) or `docker run --init` equivalents, fix the leak first and treat probes as the safety net, and probe an endpoint that exercises what actually breaks.

**Commands to remember.** `kubectl exec <pod> -- ps -o pid,ppid,stat,comm`, `kubectl explain pod.spec.shareProcessNamespace`, `kubectl get endpoints <svc> -w`.
