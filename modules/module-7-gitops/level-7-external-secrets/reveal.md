Git owns the Secret `ledger-db` (with the old password) and Argo has `selfHeal` and `prune` on, so every manual edit is reverted. The Secret has to be removed from Git and live outside Argo's control.

1. Read the rotated password: `kubectl -n k8smissions get secret ledger-db-rotated -o jsonpath='{.data.password}' | base64 -d`.
2. Clone the `ledger` repo (port-forward to `svc/gitserver` in `gitops-git`), `git rm deploy/secret.yaml`, commit, `git push origin main`. The old password stays in Git history; rotating it was the point.
3. Argo prunes the Secret it owned. Wait until `kubectl get secret ledger-db` says NotFound, then create it again by hand: `kubectl create secret generic ledger-db --from-literal=password=<rotated>`. Created after the prune, Argo does not track it.
4. Restart the pods, which read the Secret only at start: `kubectl rollout restart deploy/ledger-api`.

(Creating a differently named Secret and pointing the Deployment at it, in Git, is accepted as well.)
