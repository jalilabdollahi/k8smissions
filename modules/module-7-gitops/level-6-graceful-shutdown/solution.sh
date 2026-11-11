NS=k8smissions
kubectl -n $NS get events --field-selector reason=FailedPreStopHook
kubectl -n $NS get deploy catalog -o jsonpath='{.spec.template.spec.containers[0].lifecycle}{"\n"}'
kubectl -n $NS patch deploy catalog --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/lifecycle/preStop","value":{"sleep":{"seconds":10}}}]'
kubectl -n $NS rollout status deploy/catalog --timeout=90s
