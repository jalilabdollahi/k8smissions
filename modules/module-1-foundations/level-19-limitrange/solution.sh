kubectl -n k8smissions get deployment,rs,pods
kubectl -n k8smissions describe rs -l app=invoice-render | tail -8
kubectl -n k8smissions describe limitrange team-defaults
kubectl -n k8smissions set resources deployment invoice-render --requests=memory=256Mi --limits=memory=512Mi
kubectl -n k8smissions rollout status deployment/invoice-render --timeout=80s
