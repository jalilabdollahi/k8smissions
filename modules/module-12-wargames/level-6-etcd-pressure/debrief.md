**What was broken.** The release tool stored every release as a Secret and never pruned (`MAX_REVISIONS=0`), leaving 24 objects of about 330 KiB, roughly 8 MB that every list call must read from etcd, serialize and send. On top of that `config-syncer` listed all Secrets every 250 ms, so the API server and etcd were continuously reading and encoding that payload.

**The evidence.** `time kubectl get secrets` takes seconds; `get secrets -o json | wc -c` shows megabytes; `--show-labels` reveals that nearly all objects are `owner=release-deployer`; the syncer logs `list took ... ms (... bytes)`; and the CronJob's environment has `MAX_REVISIONS=0`.

**Why Kubernetes behaved this way.** etcd and the API server are optimised for many small objects, not for large ones read repeatedly. A LIST reads and serializes everything that matches, and clients that poll multiply the cost. The per-object limit (about 1 MiB) is an upper bound, not a recommendation. Helm and other release tools bound their history for exactly this reason.

**The fix.** Remove the old releases but keep the deployed release and its predecessor (a rollback needs it), bound the history in the tool so every deploy prunes, and slow the poller. Better still, give clients a label selector or a watch instead of a list loop.

**In production.** Watch object counts and sizes (`apiserver_storage_objects`, etcd db size), use `--history-max` style limits, put `ResourceQuota` `count/secrets` on namespaces, and replace polling with informers.

**Commands to remember.** `kubectl get secrets --show-labels`, `kubectl get <kind> -o json | wc -c`, `kubectl set env cronjob/<name> KEY=value`.
