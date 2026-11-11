# Debrief: half a config directory

**What was broken.** `config-reader` mounts one projected volume at `/etc/db`, built from Secret `db-secret` and ConfigMap `db-config`. Both have a key named `db.password`; the Secret's holds the real value, the ConfigMap's is an empty leftover from before the migration. Without `items`, every key becomes a file, so the two collided and the source listed last, the ConfigMap, won. The Secret was correct and the app still saw an empty password.

**The evidence.** The app logs `db.password=0 bytes`, `wc -c /etc/db/db.password` prints 0, and `kubectl get configmap db-config -o yaml` shows the stale `db.password: ""`. The pod is Ready because nothing checks the content of the files until the application does.

**Why Kubernetes behaves this way.** A projected volume writes the union of its sources into one atomic directory. The API server rejects duplicate paths that you write out in `items`, but it does not look at keys that are projected implicitly, so a collision is silent and the last source wins. Which one that is depends on list order only.

**The fix.** Say what each source contributes. Give the ConfigMap source `items: [{key: db.url, path: db.url}]` so it only provides the URL. Deleting the stale key from the ConfigMap is also correct; reordering the sources works but breaks the next time somebody sorts the list.

**In production.** Always use `items` in projected volumes, so that the directory contains exactly the files you expect and nothing that is added to a ConfigMap later. Keep secrets and configuration with distinct key names.

**Commands worth remembering**
- `kubectl exec <pod> -- ls -l <dir>`, `wc -c <file>`: sizes expose empty files.
- `kubectl get pod <pod> -o jsonpath='{.spec.volumes[*].projected}'`
- `kubectl explain pod.spec.volumes.projected.sources`
