kubectl -n argocd get app shop-prod -o jsonpath='{.spec.source}{"\n"}'
kubectl -n argocd get app shop-dev -o jsonpath='{.spec.source}{"\n"}'
kubectl -n argocd patch app shop-prod --type json -p '[
  {"op":"replace","path":"/spec/source/path","value":"overlays/prod"},
  {"op":"remove","path":"/spec/source/kustomize"}]'
kubectl -n argocd annotate app shop-prod argocd.argoproj.io/refresh=hard --overwrite
kubectl -n shop-prod rollout status deploy/shop --timeout=120s
kubectl -n shop-prod get deploy shop
