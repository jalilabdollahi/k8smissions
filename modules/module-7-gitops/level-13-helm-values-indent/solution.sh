NS=k8smissions
kubectl -n gitops-git port-forward svc/gitserver 18113:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18113/cgi-bin/git/search.git search
cd search
helm -n $NS get values search
helm -n $NS get manifest search | grep image:
grep -n tag values-prod.yaml
cat > values-prod.yaml <<'YAML'
replicaCount: 2
image:
  tag: "1.0"
message: "search prod: ranking v1.0"
YAML
helm template search chart -f values-prod.yaml | grep image:
helm -n $NS upgrade search chart -f values-prod.yaml
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "values-prod: quote the image tag"
git push -q origin main
kubectl -n $NS rollout status deploy/search --timeout=120s
