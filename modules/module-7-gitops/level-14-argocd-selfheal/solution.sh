NS=k8smissions
kubectl -n argocd get app payments-api -o jsonpath='{.status.sync.status}{"\n"}{.spec.syncPolicy.automated}{"\n"}'
kubectl -n $NS get cm payments-config -o jsonpath='{.data.UPSTREAM_TIMEOUT_MS}{"\n"}'
kubectl -n gitops-git port-forward svc/gitserver 18114:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18114/cgi-bin/git/payments-api.git payments-api
cd payments-api
git log --oneline
cat > deploy/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: payments-config
data:
  UPSTREAM_TIMEOUT_MS: "1500"
  UPSTREAM_URL: http://ledger-upstream
YAML
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "payments-api: upstream timeout 1500 ms"
git push -q origin main
kubectl -n argocd annotate app payments-api argocd.argoproj.io/refresh=hard --overwrite
until [ "$(kubectl -n $NS get cm payments-config -o jsonpath='{.data.UPSTREAM_TIMEOUT_MS}')" = 1500 ]; do sleep 2; done
kubectl -n argocd get app payments-api -o jsonpath='{.status.sync.status}{"\n"}'
