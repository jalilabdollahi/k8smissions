kubectl -n k8smissions describe rs -l app=invoice-render | grep -A3 -i FailedCreate
kubectl get validatingadmissionpolicy require-run-as-non-root -o yaml
kubectl -n k8smissions patch deploy invoice-render --type=merge -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true}}}}}'
kubectl -n k8smissions get pods
kubectl -n k8smissions describe pod -l app=invoice-render | grep -i -B1 -A2 "non-root"
kubectl -n k8smissions patch deploy invoice-render --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"log-tail","securityContext":{"runAsUser":101}}]}}}}'
kubectl -n k8smissions rollout status deploy/invoice-render --timeout=100s
