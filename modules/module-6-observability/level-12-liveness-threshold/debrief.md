## What was broken

`report-engine` is healthy but periodically unresponsive: every 30 seconds it merges segments for 14 seconds with its request loop stopped. The liveness probe asked every 5 seconds with a 1 second timeout and gave up after 2 failures, so after about 10 seconds into every pause the kubelet killed the container. The restarts were self-inflicted.

## The evidence

The previous container's log, `kubectl logs --previous`, contained no error, only the compaction start line with no finish line: the process was killed in the middle. `describe pod` showed `Liveness probe failed` events followed by `Killing`. Putting the pause length (14s) next to the probe window (about 10s) explains it.

## Why Kubernetes behaves this way

The kubelet counts consecutive failed probes. A liveness probe with `periodSeconds: 5` and `failureThreshold: 2` restarts the container after the second failure in a row, so it tolerates less than about 6 seconds of silence. Changing `initialDelaySeconds` only matters at start. The check cannot know the silence is planned; the window must be longer than the longest pause the app is allowed to have.

## The fix

Raise `failureThreshold` (or `periodSeconds`) so the tolerated silence is more than 14 seconds with margin, for example 6 failures at 5 seconds. Detection of a real hang gets slower, 30 seconds instead of 10, which is the price. Removing the probe or setting a huge threshold would lose the safety net it exists for.

## In production

Better: stop the pause (compact in a thread so the health endpoint still answers) and keep the probe strict. If the pause is truly needed, a startup or readiness approach may fit better than a long liveness window.

## Commands worth remembering

- `kubectl logs <pod> --previous`
- `kubectl describe pod <pod>` (Events and Last State)
- `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'`
