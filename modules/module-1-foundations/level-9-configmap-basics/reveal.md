1. `kubectl get cm pricing-config -o yaml` shows `TAX_RATE: "0.20"`, but `kubectl exec deploy/pricing -- env` shows `TAX_RATE=0.19`.
2. The pods read the ConfigMap into environment variables when they started, two hours before the edit.
3. `kubectl -n k8smissions rollout restart deployment/pricing` replaces them; the new pods start with the current ConfigMap and the Service answers 0.20.
