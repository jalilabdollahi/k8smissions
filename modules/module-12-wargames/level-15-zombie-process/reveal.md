Three faults:

1. Each `/thumb` request double-forks a resize helper; the grandchild is orphaned and reparented to PID 1, which is the Python server and never reaps, so zombies accumulate until the per-user process limit (`RLIMIT_NPROC`) stops the pod from creating threads. Set `shareProcessNamespace: true` on the pod template: the `pause` container becomes PID 1 and reaps orphans.
2. There is no readiness probe, so a wedged pod stays in the Service endpoints. Add `readinessProbe` (`httpGet /healthz`, short period and timeout).
3. There is no liveness probe, so nothing restarts a wedged container. Add `livenessProbe` the same way, with a detection time of a few seconds.

Probes alone would only hide the leak (the pod would be restarted every minute); reaping alone leaves nothing to catch the next wedge.
