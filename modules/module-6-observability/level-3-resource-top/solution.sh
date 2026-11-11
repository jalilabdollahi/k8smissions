kubectl -n k8smissions top pod --sort-by=cpu || true
kubectl -n k8smissions top pod --containers --sort-by=cpu || true
kubectl -n k8smissions set resources deploy/thumbnailer -c exporter --limits=cpu=200m
kubectl -n k8smissions rollout status deploy/thumbnailer --timeout=120s
