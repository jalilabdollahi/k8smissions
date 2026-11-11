NS=k8smissions
kubectl -n gitops-git port-forward svc/gitserver 18081:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18081/cgi-bin/git/charts.git charts
helm -n $NS history ledger-api
helm -n $NS get values ledger-api --revision 1 > prod-values.yaml
cat prod-values.yaml
helm -n $NS upgrade ledger-api charts/ledger-api -f prod-values.yaml --set image.tag=1.0 --wait --timeout 90s
