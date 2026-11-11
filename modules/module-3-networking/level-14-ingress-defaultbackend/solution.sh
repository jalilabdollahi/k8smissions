kubectl get ingressclass
kubectl -n k8smissions get ingress docs -o jsonpath='{.spec.ingressClassName}'
kubectl -n k8smissions patch ingress docs --type=merge -p '{"spec":{"ingressClassName":"nginx"}}'
kubectl -n k8smissions create ingress fallback --class=nginx --default-backend=maintenance:80
