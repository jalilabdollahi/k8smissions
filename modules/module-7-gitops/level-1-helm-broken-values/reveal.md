CI ran `helm upgrade ledger-api ./chart --set image.tag=1.0` without `--reuse-values`, so revision 2 was rendered from the chart defaults plus one override. Replicas, message and image repository went back to the dev defaults.

1. `helm history ledger-api -n k8smissions` shows revision 1 (install) and revision 2 (CI upgrade).
2. `helm get values ledger-api -n k8smissions --revision 1 > prod.yaml` recovers the production overrides (they include the old tag `0.2.3`).
3. Clone the `charts` repo (`kubectl -n gitops-git port-forward svc/gitserver 8080:8080`, then `git clone http://localhost:8080/cgi-bin/git/charts.git`).
4. `helm upgrade ledger-api charts/ledger-api -n k8smissions -f prod.yaml --set image.tag=1.0 --wait` creates revision 3 with the production values and the new tag.

`helm rollback ledger-api 1` would restore the overrides but also the old tag, which is not what CI wanted.
