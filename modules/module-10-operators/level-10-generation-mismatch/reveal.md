Two bugs in the same status patch:

1. `observedGeneration` is computed as `old + 1`, so it is a counter that never settles on `metadata.generation`.
2. `lastSync` is stamped with the current time on every pass, so the patch always changes the object and the API server writes it (new `resourceVersion`) every two seconds.

Fix the code in ConfigMap `inventory-operator-code`: set `observedGeneration` to `item["metadata"]["generation"]` and only patch status when `observedGeneration` (or `phase`) differs from what is stored. Keep `ensure_child(...)` outside that condition so drift in the children is still healed on every pass. Then restart the operator:

```bash
kubectl -n k8smissions edit configmap inventory-operator-code
kubectl -n k8smissions rollout restart deploy/inventory-operator
```
