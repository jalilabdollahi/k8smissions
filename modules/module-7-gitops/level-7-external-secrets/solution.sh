NS=k8smissions
kubectl -n argocd get app ledger-api -o jsonpath='{.status.sync.status} {.status.operationState.message}{"\n"}'
pw=$(kubectl -n $NS get secret ledger-db-rotated -o jsonpath='{.data.password}' | base64 -d)
kubectl -n gitops-git port-forward svc/gitserver 18087:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18087/cgi-bin/git/ledger.git ledger
cd ledger
git rm -q deploy/secret.yaml
git -c user.name=oncall -c user.email=oncall@example.com commit -qm "Remove the database Secret from Git"
git push -q origin main
kubectl -n argocd annotate app ledger-api argocd.argoproj.io/refresh=hard --overwrite
# Argo prunes the Secret it owned; create it again outside Git once it is gone
until ! kubectl -n $NS get secret ledger-db >/dev/null 2>&1; do sleep 2; done
kubectl -n $NS create secret generic ledger-db --from-literal=password="$pw"
kubectl -n $NS rollout restart deploy/ledger-api
kubectl -n $NS rollout status deploy/ledger-api --timeout=120s
