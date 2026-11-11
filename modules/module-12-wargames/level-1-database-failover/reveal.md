Three independent faults, any order:

1. **Cordoned node holds the volume.** `describe pod ledger-db-0` shows `volume node affinity conflict` plus `unschedulable`. The local-path PV is bound to one node and that node was cordoned for the drill. `kubectl uncordon <node>` lets the pod schedule there and reuse the same PVC (the data is intact).
2. **Service selector.** `ledger-db` selects `app=ledger-db,role=primary` but the StatefulSet pod only carries `app=ledger-db`, so the Service has no endpoints (app log: `connection refused`). Replace the selector with `app: ledger-db`.
3. **NetworkPolicy label.** `ledger-db-ingress` admits `tier=app` while the application pods are labelled `tier=backend`, so traffic is dropped (app log: `timed out`). Change the `from.podSelector` to `tier: backend`. Do not delete the policy: the validator checks that outsiders are still blocked.

Do not delete the PVC to unstick the pod; a new volume is empty and `entry-0001` would be gone.
