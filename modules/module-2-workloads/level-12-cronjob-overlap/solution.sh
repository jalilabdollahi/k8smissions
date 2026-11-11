kubectl -n k8smissions get cronjob data-processor
kubectl -n k8smissions get jobs
kubectl -n k8smissions patch cronjob data-processor --type=merge -p '{"spec":{"concurrencyPolicy":"Forbid"}}'
kubectl -n k8smissions delete jobs -l app=data-processor
