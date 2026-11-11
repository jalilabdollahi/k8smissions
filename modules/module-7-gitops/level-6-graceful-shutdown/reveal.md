The `preStop` hook is `exec: sleep 10`, but `hashicorp/http-echo` has no `sleep` binary (it has no shell at all). The kubelet records a `FailedPreStopHook` event, gives up on the hook at once and sends SIGTERM, so the pod exits while the Service still routes to it for a second or two.

1. `kubectl -n k8smissions get events --field-selector reason=FailedPreStopHook` shows the hook failing.
2. Replace the hook with the built-in sleep action, which the kubelet runs itself and needs nothing in the image:
   `kubectl -n k8smissions patch deploy catalog --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/lifecycle/preStop","value":{"sleep":{"seconds":10}}}]'`
3. The patch starts a rollout; `kubectl rollout status deploy/catalog` waits for it.
