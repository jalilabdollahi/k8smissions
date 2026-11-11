kubectl -n k8smissions get pods --show-labels
kubectl -n k8smissions get endpoints app
kubectl -n k8smissions scale deployment app-stable --replicas=9
kubectl -n k8smissions scale deployment app-canary --replicas=1
kubectl -n k8smissions rollout status deployment/app-stable --timeout=100s
