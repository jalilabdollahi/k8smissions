# Common mistakes: level 14

**Restarting the consumer.** `kubectl rollout restart deployment/api-consumer` gives the pod the current token and the first check passes. The rotation after that leaves it stale again, which the validator's second rotation shows.

**Recreating or re-editing the Secret.** The Secret is correct; the gateway already accepts it. The pod's copy is what is stale, so a different Secret value changes nothing for it.

**Mounting the volume at `/etc/api/token` without `subPath`.** That makes `token` a directory containing a file `token`, so the app finds `/etc/api/token/token` and not the file it reads. Mount at the directory (`/etc/api`) so the key appears as `/etc/api/token`.

**Expecting an instant change.** Kubelet updates Secret volumes on its sync loop, up to about a minute after the Secret changes. The validator waits for it; give a manual check the same time.
