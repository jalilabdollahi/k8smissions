**What was broken.** The namespace has a `count/configmaps: 100` ResourceQuota. A nightly exporter had been writing one result ConfigMap per run for weeks and never deleting any, so 96 of them piled up until the quota was full and the deploy bot could not create its release ConfigMap.

**The evidence.** `kubectl describe resourcequota` showed `100/100`, and `kubectl get configmap --show-labels` showed a long run of `export-result-*` all labelled `app=exporter`. The exporter's script already contained a cleanup step, but it searched for `app=exporter-output` while the results were created with `app=exporter`: the selector matched nothing, so nothing was ever deleted. The next trap: one of the old results, `export-result-0042`, is mounted by billing-web. Deleting everything by label would have taken it away, and billing-web would fail on its next restart.

**Why Kubernetes behaved this way.** Object-count quotas exist because every object is stored in etcd and watched by controllers; thousands of stale ConfigMaps (or Events, Secrets) slow the API server and the datastore down. The quota rejects the next create when the count reaches the limit, whoever asks. Kubernetes never garbage-collects objects that nothing owns; owner references or an explicit cleanup do that.

**The fix.** Cure the cause and the pile: make the exporter's creation and cleanup agree so each run replaces the last, then delete the old results while keeping what a pod still mounts. Raising the quota would have hidden the leak for a few more weeks.

**In production.** Give generated objects an `ownerReference` to their Job (and `ttlSecondsAfterFinished` on the Job) so they disappear with it, alert on quota usage above 80%, and delete by label only after listing what the selector matches.

**Worth remembering.**
- `kubectl describe resourcequota`
- `kubectl get configmap --show-labels --sort-by=.metadata.creationTimestamp`
- `kubectl create job --from=cronjob/<name> <test>`
