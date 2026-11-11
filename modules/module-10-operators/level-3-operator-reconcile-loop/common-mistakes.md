## Editing the ConfigMap and waiting

The patch is correct but nothing changes: the running pod read `WATCH_NAMESPACE` at startup and never looks again. Restart the Deployment (`kubectl rollout restart`) or delete the pod.

## Moving the WebApps to the namespace the operator watches

Recreating `site-a` and `site-b` in `staging` makes the operator build them there, but the sites belong in `k8smissions` and the validator looks for them (and their Deployments) in that namespace.

## Hunting for an error in the logs

There is none to find. Quiet logs from a controller are a clue about scope, not about a crash; go and look at what it is configured to watch.
