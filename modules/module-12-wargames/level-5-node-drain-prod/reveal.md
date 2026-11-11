Four blockers, found one at a time:

1. **PDB `checkout-pdb` has `minAvailable: 3` for 2 replicas.** No eviction is ever allowed. Patch it to `minAvailable: 1` (deleting it would pass the drain and fail the "still protected" check).
2. **Bare pod `report-scratch`** has no controller, so drain refuses to delete it without `--force` (it is not recreated anywhere).
3. **`search` uses an `emptyDir`.** Drain needs `--delete-emptydir-data` to accept losing it.
4. **The other worker carries `dedicated=batch:NoSchedule`.** Without removing that taint (`kubectl taint node <other> dedicated-`) the evicted `checkout` and `search` pods have nowhere to run and stay Pending after a "successful" drain.

Then `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --force`. The node stays cordoned.
