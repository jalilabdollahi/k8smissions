The first sync failed because namespace `ledger-prod` does not exist and the Application has no `CreateNamespace=true` sync option. A failed manual sync does not retry by itself.

1. `kubectl -n argocd get app ledger-api -o jsonpath='{.status.operationState.message}'` shows the failure (namespace not found).
2. Add the option: `kubectl -n argocd patch app ledger-api --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true"]}}}'`.
3. Request a new sync: `kubectl -n argocd patch app ledger-api --type merge -p '{"operation":{"sync":{"syncOptions":["CreateNamespace=true"]}}}'`.
4. Wait for `Synced`/`Healthy`. Creating the namespace by hand with `kubectl create ns ledger-prod` and requesting a sync works too.
