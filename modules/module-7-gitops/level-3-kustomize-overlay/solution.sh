kubectl -n gitops-git port-forward svc/gitserver 18083:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18083/cgi-bin/git/shop.git shop
kubectl -n shop-staging get all,hpa,pdb
kubectl kustomize shop/overlays/production | grep -E '^kind|^  name'
kubectl delete -k shop/overlays/production -n shop-staging
kubectl -n shop-staging rollout status deploy/stg-checkout --timeout=120s
