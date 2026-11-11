**What was broken.** catalog-web uses a readiness gate so that a pod is only added to the Service after its cache is warm. A small controller, warmup-gate, checks each pod's `/warm` endpoint and writes a pod condition. The pods waited for `catalog.k8smissions.io/warm`; the controller wrote `catalog.k8smissions.io/warmed`. Nothing ever satisfied the gate, so no pod ever became Ready and the rollout stalled.

**The evidence.** `kubectl describe pod` looks healthy: every container is Ready. Only the pod-level `Ready` condition is False, with `ContainersReady` True. The pod's condition list showed an extra condition, `warmed`, that no gate was waiting for, and the controller's log named the type it managed. The mismatch is only visible when you compare the two names.

**Why Kubernetes behaved this way.** Pod readiness is the AND of `ContainersReady` and every condition type in `spec.readinessGates`. The kubelet owns the container side; anything else (a controller, a load-balancer integration) patches the extra conditions through the `pods/status` subresource. Kubernetes does not know which controller should satisfy a gate, so a typo in the type name means it waits forever and does not complain.

**The fix.** Make the two names identical, on the controller side or in the pod template. The gate must stay: the validator restarts the Deployment under traffic and any request answered by a cold pod fails the check. Removing the gate, with no other warm check, brings the 503s back.

**In production.** The same mechanism powers cloud load-balancer readiness (pod ready only after the target is registered). Give such controllers RBAC for `pods/status`, alert when a pod stays `ContainersReady` but not `Ready`, and make the condition name a shared constant.

**Worth remembering.**
- `kubectl get pod <pod> -o jsonpath='{.status.conditions}'`
- `kubectl explain pod.spec.readinessGates`
- `kubectl rollout status deployment/<name>`
