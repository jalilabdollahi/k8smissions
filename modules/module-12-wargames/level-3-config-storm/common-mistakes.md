**Copying the values from `shop-config-v38`.** It is the oldest version and the first one in the list, and the pods will start with it, but the validator compares with v41, the last release that worked. Check which version the pipeline marks as good before you copy.

**Deleting `shop-config` and recreating it under the same name.** It looks like the natural way around `immutable`, but the kubelet keeps the old immutable object cached while pods that use it are still on the node, so the new pods start with the old values and keep crash-looping. Use a new name and change the references.

**Fixing `shop-web` and stopping.** Once `shop-web` is healthy the incident looks over. `shop-worker` runs without errors, so nobody is paged, but it still serves the old values through its `subPath` files, and the CronJob would still read the bad ConfigMap at 03:00. Check every consumer's `/config` and run a Job from the CronJob.
