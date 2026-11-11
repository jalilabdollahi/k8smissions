**What was broken.** The v42 release put two bad values into `shop-config` and marked it `immutable: true`. Three consumers read it in three different ways: `shop-web` through `envFrom` (validated at start, so it crash-looped), `shop-worker` through `subPath` file mounts (it kept running and quietly served the broken values), and the `shop-report` CronJob through `envFrom` (it would have failed at 03:00).

**The evidence.** `logs deploy/shop-web` prints `FATAL config: MAX_CONN must be a positive integer, got ''`. `kubectl patch cm shop-config` is refused with `field is immutable`. `get cm` shows `shop-config-v41`, kept by the pipeline, with sane values. And `exec shop-worker -- cat /etc/shop/MAX_CONN` shows an empty value no matter what happens to the ConfigMap afterwards.

**Why Kubernetes behaved this way.** An immutable ConfigMap protects consumers from accidental edits and relieves the API server, because kubelets stop watching it; the price is that a change means a new object, and a replaced object with the same name can be served from the kubelet's cache while pods referencing the old one still run on the node. Environment variables are fixed when a container starts, and a `subPath` mount is a bind mount of one file that is never refreshed. A crash-looping container waits in exponential backoff (up to five minutes).

**The fix.** Create a new, versioned ConfigMap with the v41 values and repoint `shop-web`, `shop-worker` and `shop-report` at it. The template change makes both Deployments roll, which also clears the crash-loop backoff and replaces the `subPath` pods.

**In production.** Name ConfigMaps per release (Kustomize's `configMapGenerator` hash suffix does exactly this), validate config in CI, and avoid `subPath` for anything that changes.

**Commands to remember.** `kubectl get cm <name> -o yaml`, `kubectl patch deploy <name> --type=json`, `kubectl create job --from=cronjob/<name> <job>`.
