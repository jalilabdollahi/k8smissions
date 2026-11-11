kubectl -n k8smissions logs deploy/capacity-report --tail=3
kubectl get apiservices | grep metrics
kubectl api-versions | grep metrics
kubectl -n k8smissions get cm capacity-report -o yaml | sed 's#metrics.k8s.io/v1"#metrics.k8s.io/v1beta1"#' | kubectl apply -f -
kubectl -n k8smissions rollout restart deploy/capacity-report
kubectl -n k8smissions rollout status deploy/capacity-report --timeout=120s
