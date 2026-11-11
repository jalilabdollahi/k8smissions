kubectl -n k8smissions get pods -o wide
kubectl -n k8smissions describe pod -l app=video-encoder | grep -A3 FailedScheduling
kubectl describe nodes | grep -A8 "Allocated resources"
cur=$(kubectl -n k8smissions get deploy video-encoder -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
echo "current request: $cur"
new=$(( ${cur%m} * 3 / 4 ))m
kubectl -n k8smissions set resources deploy/video-encoder --requests=cpu=$new
kubectl -n k8smissions rollout status deploy/video-encoder --timeout=120s
kubectl -n k8smissions get pods -o wide
