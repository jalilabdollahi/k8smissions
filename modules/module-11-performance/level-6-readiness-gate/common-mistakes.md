**Looking at container readiness.** `kubectl get pod` shows `1/1` for the containers' own checks only in some views, and `describe` shows every container Ready, so the app looks healthy. The failing part is the pod's `Ready` condition, one level up.

**Deleting the readiness gate.** The rollout then completes, but new pods are Ready the instant their `/healthz` answers, long before the cache is warm. The 10 req/s probe sees 503s from cold pods and the check fails. If you want to drop the gate you need a real warm check in the readiness probe instead.

**Fixing the controller's RBAC.** Its logs show no errors: it patches successfully, just under a name nobody waits for. Permissions are not the problem.

**Not waiting after the fix.** If you changed the pod template, a new rollout starts and takes about 20 seconds; if you changed the controller, give it a second or two to relabel the pods.
