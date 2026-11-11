NS=k8smissions
kubectl -n argocd get app grand-finale-app -o jsonpath='{.status.conditions[*].message}{"\n"}'
kubectl -n argocd patch app grand-finale-app --type merge -p '{"spec":{"source":{"targetRevision":"main"}}}'
kubectl -n gitops-git port-forward svc/gitserver 18090:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18090/cgi-bin/git/finale.git finale
cd finale
ls chart
helm template grand-finale-app chart -f chart/values-production.yaml | grep -E 'targetPort|image:'
cat > chart/values-production.yaml <<'YAML'
replicaCount: 2
image:
  tag: "1.0"
message: "grand-finale v2.3"
service:
  targetPort: 5678
resources:
  requests:
    cpu: 100m
    memory: 64Mi
YAML
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "Production values: container port and requests that fit the quota"
git push -q origin main
kubectl -n argocd patch app grand-finale-app --type merge -p '{"spec":{"source":{"helm":{"valueFiles":["values-production.yaml"]}}}}'
kubectl -n argocd annotate app grand-finale-app argocd.argoproj.io/refresh=hard --overwrite
until [ "$(kubectl -n argocd get app grand-finale-app -o jsonpath='{.status.sync.status}/{.status.health.status}')" = Synced/Healthy ]; do sleep 3; done
kubectl -n $NS rollout status deploy/grand-finale-app --timeout=120s
