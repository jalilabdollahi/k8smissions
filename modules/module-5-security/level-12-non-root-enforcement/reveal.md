**Fix**

1. `kubectl -n k8smissions describe rs -l app=invoice-render` shows `FailedCreate ... pods must set runAsNonRoot: true`.
2. Add it at pod level:
   `kubectl -n k8smissions patch deploy invoice-render --type=merge -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true}}}}}'`
   Pods are now admitted, but the `log-tail` busybox container stays in `CreateContainerConfigError` (`container has runAsNonRoot and image will run as root`).
3. Give that container a numeric UID:
   `kubectl -n k8smissions patch deploy invoice-render -p '{"spec":{"template":{"spec":{"containers":[{"name":"log-tail","securityContext":{"runAsUser":101}}]}}}}'`
4. `kubectl -n k8smissions rollout status deploy/invoice-render`

Do not delete the policy or its binding; the validator keeps testing that root pods are rejected.
