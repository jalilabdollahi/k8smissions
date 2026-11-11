**What was broken.** Revision 2 of `ledger-api` was built from the chart's own `values.yaml` plus a single `--set image.tag=1.0`. The production overrides (3 replicas, the production message, the real image repository) lived only in revision 1's user-supplied values, and Helm does not carry user values from one `upgrade` to the next unless you ask for it. The chart default repository does not exist, so the new pod sat in ImagePullBackOff and the old ReplicaSet was scaled down to one pod to match the new replica count.

**The evidence.** `helm history` showed the extra revision at the time of CI's run. `helm get values --revision 1` and `--revision 2` side by side showed what was lost. `kubectl describe pod` pointed at the repository name.

**Why Kubernetes behaved this way.** Helm computes each release from scratch: chart defaults, then `-f` files, then `--set`, last one wins. The cluster only saw a valid Deployment with different numbers, so nothing was "wrong" from its point of view.

**The fix.** Take the production values from the revision that held them and pass them again together with the new tag:
`helm get values ledger-api --revision 1 > prod.yaml` then `helm upgrade ledger-api <chart> -f prod.yaml --set image.tag=1.0`.

**In production.** Keep the values file in Git next to the pipeline and always upgrade with `-f values-prod.yaml`; `--reuse-values` is fragile because it also reuses stale chart defaults and ignores new ones. `helm upgrade --install --atomic` rolls back automatically if the new pods never become ready.

**Commands worth remembering.**
- `helm get values RELEASE --revision N` and `helm get values RELEASE --all`
- `helm template RELEASE CHART -f values.yaml` to preview before upgrading
- `helm diff upgrade` (plugin) to see the change first
