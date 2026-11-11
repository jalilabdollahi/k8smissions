**Fix**

1. `kubectl -n k8smissions logs deploy/edge-nginx` shows the first failing operation; each partial fix shows the next (`chown`, `setgid(101)`, `bind() to 0.0.0.0:80 ... Permission denied`).
2. Give back exactly the capabilities nginx uses as root: `CHOWN` (hand its temp directories to the worker user), `SETUID` and `SETGID` (drop to user `nginx`), `NET_BIND_SERVICE` (port 80).
   `kubectl -n k8smissions patch deploy edge-nginx --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/securityContext/capabilities/add","value":["CHOWN","SETUID","SETGID","NET_BIND_SERVICE"]}]'`
3. `kubectl -n k8smissions rollout status deploy/edge-nginx`, then `kubectl -n k8smissions exec deploy/edge-nginx -- grep CapEff /proc/1/status` shows a small mask.

Keep `drop: ["ALL"]`; do not use `privileged: true`, and do not add `SYS_ADMIN`, `NET_ADMIN`, `NET_RAW` or `DAC_OVERRIDE`.
