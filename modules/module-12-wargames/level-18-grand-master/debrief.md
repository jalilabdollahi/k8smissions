**What was broken.** One "hardening" commit broke four layers, and each one hid the next. The namespace's `restricted` Pod Security level rejected a pod template with no security context, so no pods existed. Then a typo in the `nodeSelector` value and a leftover `dedicated=batch` taint on both workers left the pods Pending. Then a liveness probe that starts at 5 seconds killed an app that needs 25 seconds to warm up. And an HPA that watched memory, capped at two replicas, with a sidecar lacking a CPU request, could not scale on CPU.

**The evidence.** `describe rs` listed `violates PodSecurity "restricted:latest"` with the exact fields. `describe pod` said `didn't match Pod's node affinity/selector`, then `had untolerated taint {dedicated: batch}`, then `Liveness probe failed ... Container app failed liveness probe, will be restarted`. `describe hpa` said first nothing useful (memory 30%/80%), then `missing request for cpu in container "log-shipper"`.

**Why Kubernetes behaved this way.** Pod Security admission checks the pod spec when the pod is created, so a violation produces no pod at all. The scheduler filters on selectors and taints before it considers anything else. Liveness probes start counting after `initialDelaySeconds` unless a startup probe is defined, in which case liveness waits for it. The HPA computes utilisation as usage divided by the request, summed over all containers, so one container without a request makes the metric unavailable.

**The fix.** A compliant security context on every container, a correct selector and taint, a startup probe, and a CPU-based HPA with room to grow and requests everywhere. Do not relax the namespace: the validator checks the policy and the non-root user.

**In production.** Roll out policy changes with `warn` and `audit` modes first (`pod-security.kubernetes.io/warn`), dry-run Deployments against the namespace, and load-test the scaling path as a step of the release.

**Commands to remember.** `kubectl describe rs`, `kubectl label ns <name> pod-security.kubernetes.io/enforce=restricted --dry-run=server`, `kubectl taint nodes <node> <key>-`, `kubectl describe hpa`, `kubectl top pod --containers`.
