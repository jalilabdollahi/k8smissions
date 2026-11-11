The `metrics-proxy` sidecar and the `app` container both bind port 8080. They share one network namespace, the sidecar starts first and wins, and the app dies with `Address already in use`.

1. `kubectl -n k8smissions logs deploy/quote-service --all-containers --prefix` shows the healthy proxy; `logs -c app --previous` shows `cannot listen on 8080: [Errno 98] Address already in use`.
2. `kubectl -n k8smissions set env deploy/quote-service -c metrics-proxy LISTEN_PORT=9102` moves the sidecar to its own port.
3. `kubectl -n k8smissions rollout status deploy/quote-service` waits for the new pod; the app now binds 8080 and the Service works.
