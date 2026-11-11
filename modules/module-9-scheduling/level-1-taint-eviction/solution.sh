kubectl describe node -l disktype=nvme | grep -A2 Taints
kubectl -n k8smissions get events --field-selector reason=TaintManagerEviction
kubectl -n k8smissions get deploy session-cache -o jsonpath='{.spec.template.spec.tolerations}'
kubectl -n k8smissions patch deploy session-cache --type=json -p '[{"op":"remove","path":"/spec/template/spec/tolerations/0/tolerationSeconds"}]'
kubectl -n k8smissions rollout status deploy/session-cache --timeout=90s
