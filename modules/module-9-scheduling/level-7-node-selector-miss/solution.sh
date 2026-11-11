kubectl -n k8smissions describe pod -l app=inference-gateway | grep -A3 FailedScheduling
kubectl get nodes -L disktype,drain-pending
kubectl label node -l disktype=ssd drain-pending-
kubectl -n k8smissions rollout status deploy/inference-gateway --timeout=120s
kubectl -n k8smissions get pods -o wide
