**Fix**

1. `kubectl get nodes -L data-class` shows one labelled worker; `get pods -o wide` shows replicas on both workers.
2. The Deployment only has a `preferredDuringSchedulingIgnoredDuringExecution` rule: a soft preference, outweighed by the spread constraint.
3. Replace it with `requiredDuringSchedulingIgnoredDuringExecution` with a `nodeSelectorTerms` match on `data-class In [restricted]` (`kubectl edit deployment ledger-api`).
4. The pod template changed, so the Deployment rolls out new pods that can only land on the labelled node and removes the old ones. `kubectl rollout status` waits for it.
