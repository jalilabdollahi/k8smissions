1. `kubectl logs <pod> -c log-shipper` says `/logs is not there`: the sidecar exits with code 1 and restarts, so READY stays `1/2`.
2. The pod already declares the `logs` emptyDir and `nginx` writes its access log into it, but `log-shipper` never mounts it.
3. Add `volumeMounts: [{name: logs, mountPath: /logs}]` to the `log-shipper` container, for example with `kubectl patch deployment checkout` (a strategic merge patch finds the container by name).
4. The rollout starts new pods; requests through Service `checkout` now appear in `kubectl logs <pod> -c log-shipper`.
