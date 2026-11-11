kubectl -n k8smissions describe quota object-counts
kubectl -n k8smissions get pods --field-selector=status.phase=Succeeded
kubectl -n k8smissions get cronjob price-sync -o yaml | grep -i history
kubectl -n k8smissions patch cronjob price-sync --type=merge -p '{"spec":{"successfulJobsHistoryLimit":2,"jobTemplate":{"spec":{"ttlSecondsAfterFinished":3600}}}}'
kubectl -n k8smissions get jobs -o name | xargs -r kubectl -n k8smissions delete
kubectl -n k8smissions rollout restart deploy/catalog-web
kubectl -n k8smissions rollout status deploy/catalog-web --timeout=100s
