Release 2.0 moved the nginx health location from `/healthz` to `/-/health`, but the Deployment's readiness probe still asks for `/healthz`, which now returns 404. The new pod can never become Ready and, with `maxUnavailable: 0`, the rollout cannot remove an old pod.

1. `kubectl describe pod` on the new pod shows `Readiness probe failed: HTTP probe failed with statuscode: 404`.
2. `kubectl get cm docs-site-conf-v2 -o yaml` shows the health location is `/-/health`.
3. Patch the probe path: `kubectl patch deploy docs-site --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/-/health"}]'` and wait for `rollout status`.
