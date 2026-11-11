kubectl -n k8smissions get pods -l app=thumbnailer
POD=$(kubectl -n k8smissions get pods -l app=thumbnailer -o name | head -1)
kubectl -n k8smissions describe $POD | grep -A6 "Last State"
kubectl -n k8smissions logs $POD --previous
kubectl -n k8smissions set resources deployment thumbnailer --requests=memory=192Mi --limits=memory=256Mi
kubectl -n k8smissions rollout status deployment/thumbnailer --timeout=100s
