# Common mistakes: level 6

**Reading logs.** `kubectl logs` has nothing because the container was never created. When a pod sits in ContainerCreating, go straight to `kubectl describe pod` and read the events.

**Recreating the ConfigMap from scratch.** Deleting and re-adding `app-config` with the same content fixes nothing: the volume still selects `settings.yaml`. Compare the key in the volume with the key in the ConfigMap, and change one of them.

**Deleting the pod to retry.** The kubelet already retries the mount. A replacement pod from the same template hits the same missing key, so wait for a fix to roll out rather than forcing restarts.
