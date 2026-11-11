## What was broken

`storefront` called `http://inventory:8080`. That name only exists in the caller's own namespace, so DNS returned nothing. Behind it sat a second problem: `warehouse` had a NetworkPolicy that admits only namespaces labelled `team=storefront`, and `k8smissions` did not carry that label.

## The evidence

`nslookup inventory` from a pod in `k8smissions` failed, while `kubectl get svc -A` showed `inventory` in `warehouse`. After switching to `inventory.warehouse`, the name resolved but connections timed out: dropped packets, not refused ones. `describe networkpolicy` in `warehouse` showed the namespace selector, and `get ns --show-labels` showed that `k8smissions` lacked it.

## Why Kubernetes behaves this way

Cluster DNS names are `<service>.<namespace>.svc.cluster.local`; the resolver's search list fills in only the caller's own namespace. NetworkPolicy then treats namespaces as selectable objects: a `namespaceSelector` matches on namespace labels, so access is granted by labelling, not by name.

## The fix

Use the qualified name (or an ExternalName Service `inventory` that points to it) and label the calling namespace with the key the policy expects. Weakening the policy instead would open `warehouse` to the contractors namespace.

## In production

Namespace labels are an access control input. Who may label namespaces should be controlled with RBAC, since a label can grant network access.

## Commands worth remembering

- `kubectl get svc -A`
- `kubectl get ns --show-labels`
- `kubectl label namespace <ns> <key>=<value>`
