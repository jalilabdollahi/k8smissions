NS=k8smissions
kubectl -n argocd get app ledger-api -o jsonpath='{.status.operationState.message}{"\n"}'
kubectl -n argocd get app ledger-api -o jsonpath='{.status.sync.status} {.status.health.status}{"\n"}'
kubectl -n $NS get pods,job
kubectl -n gitops-git port-forward svc/gitserver 18109:8080 >/dev/null 2>&1 &
trap "kill %1" EXIT
until git ls-remote http://localhost:18109/cgi-bin/git/ledger.git >/dev/null 2>&1; do sleep 1; done
git clone -q http://localhost:18109/cgi-bin/git/ledger.git ledger
cd ledger
# a PostSync hook runs only after the app is healthy, and it cannot be healthy before the migration
sed -i.bak 's/hook: PostSync/hook: PreSync/' deploy/migrate-job.yaml && rm deploy/migrate-job.yaml.bak
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "Run the migration before the rollout (PreSync)"
git push -q origin main
# the running operation waits for health forever: terminate it, Argo then syncs the new commit
kubectl -n argocd annotate app ledger-api argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd patch app ledger-api --type merge -p '{"status":{"operationState":{"phase":"Terminating"}}}'
until kubectl -n $NS get pod -l job-name=db-migrate -o name 2>/dev/null | grep -q pod; do sleep 2; done
kubectl -n $NS get pods
kubectl -n $NS describe pod -l job-name=db-migrate | tail -5
# the Job reads ConfigMap migrations, which is only created later, in the Sync phase: create it with the hook
cat > deploy/migrations.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: migrations
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/sync-wave: "-1"
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
data:
  target_version: "3"
YAML
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "Create the migrations ConfigMap in the PreSync phase, before the Job"
git push -q origin main
kubectl -n argocd annotate app ledger-api argocd.argoproj.io/refresh=hard --overwrite
until [ "$(kubectl -n argocd get app ledger-api -o jsonpath='{.status.operationState.phase}')" != Running ]; do
  kubectl -n argocd patch app ledger-api --type merge -p '{"status":{"operationState":{"phase":"Terminating"}}}'
  sleep 3
done
kubectl -n argocd patch app ledger-api --type merge -p '{"operation":{"sync":{}}}'
until [ "$(kubectl -n argocd get app ledger-api -o jsonpath='{.status.sync.status}/{.status.health.status}/{.status.operationState.phase}')" = Synced/Healthy/Succeeded ]; do sleep 3; done
kubectl -n $NS get deploy ledger-api
