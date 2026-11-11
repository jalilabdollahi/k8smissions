**Relaxing the namespace to `baseline` or `privileged`.** One label change makes the first error vanish and throws away the policy the security team wanted. The validator requires `restricted` and a non-root user; fix the pods, not the policy.

**Adding `runAsNonRoot: true` without a user.** The pod is admitted, then fails with `container has runAsNonRoot and image will run as root`, because the Python image's default user is root. Give it a numeric `runAsUser`. The sidecar needs the same hardening as the app.

**Only raising `initialDelaySeconds` a little.** A delay of 20 seconds still kills a 25 second start, and a huge one delays the detection of real failures for ever after. A `startupProbe` is the tool made for slow starts.

**Fixing only `maxReplicas`.** With the memory metric the HPA never sees the CPU load, and a CPU metric stays `<unknown>` until every container has a CPU request. Check `kubectl describe hpa` after each change.
