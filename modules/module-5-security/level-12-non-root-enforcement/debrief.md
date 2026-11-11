## What was broken

A ValidatingAdmissionPolicy refused every pod in the namespace that did not require `runAsNonRoot`. `invoice-render` did not set it, so its ReplicaSet could not create a single pod. After that was fixed, a second layer showed up: the busybox sidecar's image runs as root, and the kubelet refuses to start a container with `runAsNonRoot: true` when the image does not declare a numeric non-root user.

## Evidence

`kubectl get deploy` shows 0/2 and `get pods` shows nothing, because admission rejected the pods before they existed. The reason is in the ReplicaSet's `FailedCreate` events, quoting the policy's message. After the first fix, `describe pod` shows `CreateContainerConfigError: container has runAsNonRoot and image will run as root`.

## Why Kubernetes behaved this way

Admission and the kubelet check different things. The policy only inspects the manifest: is `runAsNonRoot` true somewhere? The kubelet inspects the real image and refuses to start root containers under that flag, but it can only reason about a numeric UID, never a user name, so `runAsUser` has to be a number. The nginx-unprivileged image declares UID 101, so its container needed nothing.

## The fix

Pod-level `runAsNonRoot: true` plus `runAsUser: 101` (or any non-zero UID) on the sidecar. The policy stays in force.

## In production

Admission policies are cluster-wide guard rails: fix the workload, not the rule. Prefer an image that really runs unprivileged (and check with `kubectl exec ... id -u`), and set `runAsUser` and `fsGroup` explicitly when volumes are shared between containers.

## Commands worth remembering

- `kubectl get validatingadmissionpolicy,validatingadmissionpolicybinding`
- `kubectl run x --image=busybox:1.36 --dry-run=server -- sleep 1` (see what admission says without creating)
- `kubectl exec <pod> -c <container> -- id -u`
