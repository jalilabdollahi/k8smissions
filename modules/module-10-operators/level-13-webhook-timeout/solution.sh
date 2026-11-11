time kubectl -n k8smissions run probe --image=busybox:1.36 --labels=guarded=true,team=payments --dry-run=server -o name
kubectl -n k8smissions logs deploy/quota-guard --tail=5
kubectl -n k8smissions get deploy asset-inventory -o jsonpath='{.spec.template.spec.containers[0].env}{"\n"}'
kubectl -n k8smissions set env deploy/asset-inventory INVENTORY_DELAY=0
kubectl -n k8smissions rollout status deploy/asset-inventory --timeout=90s
