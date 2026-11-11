The catalog-web pods wait for the condition `catalog.k8smissions.io/warm` in `spec.readinessGates`, but the `warmup-gate` controller sets `catalog.k8smissions.io/warmed`. The gate condition therefore never becomes True, so the pods are `ContainersReady` but never `Ready`, and the Service has no endpoints.

1. `kubectl get pod <pod> -o jsonpath='{.status.conditions}'` shows `ContainersReady True`, `Ready False` and a `warmed` condition the pod does not wait for.
2. `kubectl logs deploy/warmup-gate` prints the type it manages (`catalog.k8smissions.io/warmed`).
3. `kubectl set env deployment/warmup-gate CONDITION_TYPE=catalog.k8smissions.io/warm` makes the controller write what the pods wait for. Existing pods become Ready within a second or two.
4. (Equivalent: change `readinessGates` in the catalog-web template to `catalog.k8smissions.io/warmed`, which triggers a rollout.)
