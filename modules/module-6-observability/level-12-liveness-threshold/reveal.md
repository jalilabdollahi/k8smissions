The engine's request loop pauses for 14 seconds every 30 seconds (the log says `compaction ... finished after 14.0s`). The liveness probe fails after `periodSeconds 5 x failureThreshold 2`, about 10 seconds, so every pause gets the container killed.

1. `kubectl logs --previous` shows the compaction pause; `describe pod` shows `Liveness probe failed` followed by `Killing`.
2. Raise the failure window above the pause but keep it short enough to catch a real hang, for example `failureThreshold: 6` with the 5 second period (30 seconds).
3. `kubectl patch deploy report-engine --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/failureThreshold","value":6}]'` and wait for the rollout.
