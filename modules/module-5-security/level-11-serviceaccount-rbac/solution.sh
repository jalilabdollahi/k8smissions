kubectl -n k8smissions logs deploy/feature-flags
kubectl -n k8smissions patch deploy feature-flags --type=merge -p '{"spec":{"template":{"spec":{"serviceAccountName":"flags-reader"}}}}'
kubectl -n k8smissions logs deploy/feature-flags
kubectl -n k8smissions patch deploy feature-flags --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":true}}}}'
kubectl -n k8smissions rollout status deploy/feature-flags --timeout=100s
