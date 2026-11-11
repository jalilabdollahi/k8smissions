**What was broken.** Terminating a pod and removing it from a Service happen in parallel, not in order. `catalog` exited immediately on SIGTERM, so for a moment kube-proxy on some nodes still sent requests to a pod that was gone: connection refused or reset. A faster rollout (`maxUnavailable: 50%`) simply made more pods terminate at the same time, so the effect became visible. The team had added a pre-stop `sleep`, but as an `exec` hook, and the image holds only the `http-echo` binary.

**The evidence.** `kubectl get events` during a rollout showed `FailedPreStopHook` with an "executable file not found" message. Watching `kubectl get endpointslices -w` shows the pod leaving the list around the time it is already terminating.

**Why Kubernetes behaved this way.** The kubelet runs the `preStop` hook before it sends SIGTERM and counts the time against `terminationGracePeriodSeconds`. If the hook fails, the kubelet logs the event and carries on to the SIGTERM, so a broken hook is the same as no hook. The native `sleep` action is run by the kubelet itself, so it works in images without a shell.

**The fix.** `lifecycle.preStop.sleep.seconds: 10` (keep it well under the grace period). New pods keep serving while the old ones wait out the propagation delay, then shut down. Raising only `terminationGracePeriodSeconds` does nothing for this race.

**In production.** Pair the delay with a readiness probe that fails first when the app drains, and keep an eye on `maxUnavailable`. If the app handles SIGTERM itself, drain connections there as well.

**Commands worth remembering.**
- `kubectl get events --field-selector reason=FailedPreStopHook`
- `kubectl rollout restart deploy/NAME` and `kubectl rollout status deploy/NAME`
- `kubectl get endpointslices -l kubernetes.io/service-name=NAME -w`
