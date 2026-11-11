**Fix**

1. `kubectl get clusterrole ticket-viewer -o yaml` shows `aggregationRule` selecting `aggregate-to-ticket-viewer: "true"` and rules without jobs or events: the hand edits were overwritten by the aggregation controller.
2. `kubectl get clusterrole --show-labels | grep ticket` shows `ticket-jobs` labelled `aggregate-to-ticket-viewer=ture` (typo in the value) and `ticket-events` labelled `rbac.shop.example/aggregate-to-ticket-viewer=true` (different key).
3. `kubectl label clusterrole ticket-jobs aggregate-to-ticket-viewer=true --overwrite`
4. `kubectl label clusterrole ticket-events aggregate-to-ticket-viewer=true`
5. After a few seconds `kubectl auth can-i list jobs -n k8smissions --as=x --as-group=support` answers yes.

Do not bind `support` to `cluster-admin` and do not add a wildcard to `ticket-viewer`.
