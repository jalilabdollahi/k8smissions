kubectl get ns payments-sandbox -o jsonpath='{range .status.conditions[*]}{.type}={.status}: {.message}{"\n"}{end}'
kubectl get apiservice | grep -v True
kubectl describe apiservice v1beta1.reports.example.io | tail -8
kubectl delete apiservice v1beta1.reports.example.io
until ! kubectl get ns payments-sandbox >/dev/null 2>&1; do sleep 3; done
until ! kubectl -n argocd get application payments-sandbox >/dev/null 2>&1; do sleep 3; done
kubectl get ns
