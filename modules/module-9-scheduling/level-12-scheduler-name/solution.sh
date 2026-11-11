kubectl -n k8smissions get pods -l app=trainer -o jsonpath='{.items[0].spec.schedulerName}{"\n"}'
kubectl -n k8smissions get deploy ml-scheduler
kubectl -n k8smissions get configmap ml-scheduler-config -o jsonpath='{.data.config\.yaml}' | grep schedulerName
kubectl -n k8smissions patch deploy trainer --type=merge -p '{"spec":{"template":{"spec":{"schedulerName":"ml-scheduler"}}}}'
kubectl -n k8smissions rollout status deploy/trainer --timeout=120s
kubectl -n k8smissions get pods -l app=trainer -o wide
kubectl -n k8smissions get events --field-selector reason=Scheduled
