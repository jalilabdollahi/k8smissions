Both containers inherited `httpGet` probes. `tcp-echo` is not an HTTP server and `ticker` listens on nothing, so every probe fails.

1. `kubectl -n k8smissions describe pod -l app=settlement-gateway` shows `Liveness probe failed` events: a malformed-response error for `tcp-echo` and `connection refused` for `ticker`.
2. For `tcp-echo` use `tcpSocket: {port: 7000}` in both liveness and readiness probes.
3. For `ticker` use an `exec` probe that tests `/tmp/heartbeat` is fresh, e.g. `sh -c 'test $(( $(date +%s) - $(cat /tmp/heartbeat) )) -lt 20'`.
4. Apply with `kubectl edit` or `kubectl patch`; wait for the new pod to be 2/2 Ready.
