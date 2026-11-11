# Reveal

The projected volume lists `db-secret` first and `db-config` second, with no `items`. Both objects have a key `db.password`; the ConfigMap's is an empty leftover, and because it is projected last, its empty file replaces the Secret's.

1. See the empty file: `kubectl exec deploy/config-reader -n k8smissions -- wc -c /etc/db/db.password` prints 0.
2. Project only the URL from the ConfigMap:

   ```bash
   kubectl patch deployment config-reader -n k8smissions --type=json -p '[
     {"op":"replace","path":"/spec/template/spec/volumes/1/projected/sources/1",
      "value":{"configMap":{"name":"db-config","items":[{"key":"db.url","path":"db.url"}]}}}]'
   ```
3. After the rollout `/etc/db/db.password` holds the Secret's value and the service reports `config=ok`. (Removing the stale key from the ConfigMap, or swapping the order of the sources, also works.)
