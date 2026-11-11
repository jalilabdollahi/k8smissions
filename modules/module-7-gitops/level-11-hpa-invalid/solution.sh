NS=k8smissions
kubectl -n argocd get app reports -o jsonpath='{.status.operationState.message}{"\n"}'
kubectl -n gitops-git port-forward svc/gitserver 18111:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18111/cgi-bin/git/reports.git reports
cd reports
cat > manifests/hpa.yaml <<'YAML'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: reports
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: reports
  minReplicas: 2
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target: {type: Utilization, averageUtilization: 70}
YAML
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "HPA: valid replica range, target the reports Deployment"
git push -q origin main
kubectl -n argocd annotate app reports argocd.argoproj.io/refresh=hard --overwrite
until [ "$(kubectl -n argocd get app reports -o jsonpath='{.status.sync.status}/{.status.health.status}')" = Synced/Healthy ]; do sleep 3; done
kubectl -n $NS describe hpa reports | tail -12
