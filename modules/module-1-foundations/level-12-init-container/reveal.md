1. `kubectl logs <ledger-web pod> -c wait-for-db` repeats `waiting for ledger-db:5432`; the pod is healthy, it is waiting for a dependency.
2. `kubectl get endpoints ledger-db` is empty and `kubectl get deploy ledger-db` shows 0/0: the cost-saver scaled it to zero.
3. Run `kubectl scale deployment ledger-db --replicas=1`.
4. The init loop succeeds, `web` starts, and Service `ledger-web` answers `db: reachable`. Do not delete the init container; the page would start but report `db: unreachable`.
