1. `kubectl -n k8smissions get svc shop -o yaml` shows the selector `app=shop, version=blue`; `get pods --show-labels` shows the blue pods have `version=blue` while the green pods only have `app=shop, release=green`.
2. A selector of `version=green` would match nothing, because green pods have no `version` label. The distinguishing label on the green side is `release`.
3. `kubectl -n k8smissions patch service shop --type=merge -p '{"spec":{"selector":{"version":null,"release":"green"}}}'` drops `version` and adds `release=green` in one atomic change.
4. `kubectl -n k8smissions get endpoints shop` now lists the three green pod IPs; `shop-blue` is untouched, so rolling back is the same patch with `blue`.
