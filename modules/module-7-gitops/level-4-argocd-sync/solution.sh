kubectl -n argocd get app ledger-api -o jsonpath='{.status.operationState.phase}{"\n"}{.status.operationState.message}{"\n"}'
kubectl -n argocd patch app ledger-api --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}'
kubectl -n argocd annotate app ledger-api argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd patch app ledger-api --type merge -p '{"operation":{"sync":{"syncOptions":["CreateNamespace=true"]}}}'
until [ "$(kubectl -n argocd get app ledger-api -o jsonpath='{.status.operationState.phase}')" = Succeeded ]; do sleep 3; done
kubectl -n ledger-prod rollout status deploy/ledger-api --timeout=120s
