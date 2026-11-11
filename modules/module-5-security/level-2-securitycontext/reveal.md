**Fix**

1. `kubectl -n k8smissions logs deploy/status-page --previous`: nginx cannot create `/var/cache/nginx/client_temp`.
2. After that is fixed the next error is the pid file `/var/run/nginx.pid`.
3. Mount one `emptyDir` at `/var/cache/nginx` and one at `/var/run` in the `nginx` container (add the volumes under `spec.template.spec.volumes`). Keep `readOnlyRootFilesystem: true`.
4. `kubectl -n k8smissions rollout status deploy/status-page` waits for both pods to become Ready.
