kubectl -n k8smissions logs -l tier=ledger --prefix --since=1m | awk '{print $1}' | sort | uniq -c
kubectl -n k8smissions logs deploy/ledger-api | head -3
kubectl -n k8smissions set env deploy/ledger-api LOG_LEVEL=INFO
kubectl -n k8smissions rollout status deploy/ledger-api --timeout=90s
