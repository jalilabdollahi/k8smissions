The script requests `/apis/metrics.k8s.io/v1/...`, but metrics-server only registers `v1beta1`.

1. `kubectl get apiservices | grep metrics` shows `v1beta1.metrics.k8s.io` as the only metrics API (Available=True), so the server is fine.
2. In ConfigMap `capacity-report`, change `METRICS_API = "metrics.k8s.io/v1"` to `"metrics.k8s.io/v1beta1"` (`kubectl -n k8smissions edit cm capacity-report`).
3. Restart the pod so Python re-reads the script: `kubectl -n k8smissions rollout restart deploy/capacity-report`.
4. Wait about a minute and read the log; usage lines for `ledger-api` appear.
