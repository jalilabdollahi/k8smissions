## What was broken

Deployment `checkout` runs nginx with a log-shipper sidecar. nginx writes its access log to `/logs/access.log` on a shared `emptyDir` volume, and the sidecar is supposed to `tail -F` that file. The volume was declared for the pod and mounted into nginx, but the `log-shipper` container never got a `volumeMounts` entry for it.

## The evidence

`READY 1/2` pointed at a single container. `kubectl logs <pod>` defaults to the first container (nginx), which was healthy and misleading. `kubectl logs <pod> -c log-shipper` printed `/logs is not there, nothing to ship`, and `describe pod` showed the sidecar restarting with exit code 1.

## Why Kubernetes behaved this way

Volumes belong to the pod, mounts belong to the container. A volume that is listed under `spec.volumes` does nothing for a container that does not mount it, and Kubernetes does not warn about that, because an unused volume is legal. Containers in a pod share volumes and the network, but not the filesystem, so each one sees only the paths it mounts.

## The fix

Add the `logs` volume to the `log-shipper` container's `volumeMounts` at `/logs`. The pod template changed, so the Deployment rolls out new pods; both containers become Ready and every line nginx writes is echoed by the sidecar.

## In production

Shipping logs through a sidecar and a shared volume is a real pattern when an app writes to files. Give the emptyDir a `sizeLimit` and rotate the file, or it fills the node disk. When an app can log to stdout, prefer that and let the node agent collect it.

## Commands worth remembering

- `kubectl logs <pod> -c <container>`
- `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].volumeMounts}'`
- `kubectl exec <pod> -c <container> -- ls /logs`
