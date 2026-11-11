# Debrief: the config that is not there

**What was broken.** The pod mounted ConfigMap `app-config` through an `items` list that picked the key `settings.yaml`. After the refactor, the ConfigMap's key is `app.yaml`. A selected key that does not exist makes the volume impossible to set up.

**The evidence.** The pod showed `ContainerCreating` with no restarts and `kubectl logs` had nothing to print. In `kubectl describe pod`, the Events section had a `FailedMount` warning, `configmap references non-existent config key: settings.yaml`. The ConfigMap itself was healthy, which is why it looks like nothing is wrong.

**Why Kubernetes behaves this way.** The kubelet prepares volumes before it creates containers. When the mount fails, it retries with backoff and the pod stays in `ContainerCreating`. Contrast this with a missing key referenced as an environment variable (`configMapKeyRef`): that fails later, with `CreateContainerConfigError`. A whole missing ConfigMap in a volume behaves the same way as a missing key unless the volume is marked `optional: true`.

**The fix.** Make `items[].key` name a key that exists, or drop `items` and let every key become a file named after the key. Changing the ConfigMap to add `settings.yaml` also works, but then two names exist for the same content. Once the mount succeeds the kubelet starts the container with no further action.

**In production.** Rename keys and consumers in the same change, and check events on any pod that does not leave `ContainerCreating`. `optional: true` avoids the stuck pod but makes the app start without its configuration, which is often worse.

**Commands worth remembering**
- `kubectl describe pod <pod>`: events explain mount failures.
- `kubectl get configmap <name> -o yaml`: the actual keys.
- `kubectl explain pod.spec.volumes.configMap.optional`
