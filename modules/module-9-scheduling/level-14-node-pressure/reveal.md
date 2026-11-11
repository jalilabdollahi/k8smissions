1. The Evicted pods say `Pod ephemeral local storage usage exceeds the total limit of containers 50Mi`. The compaction writes 120Mi.
2. The Deployment sets no limit; LimitRange `container-defaults` injects `ephemeral-storage: 50Mi` into every container without one (`kubectl get pod -o yaml` shows it).
3. Give the container its own limit above the output size; this rolls the Deployment:
   `kubectl -n k8smissions set resources deploy/log-compactor --limits=ephemeral-storage=300Mi --requests=ephemeral-storage=200Mi`
