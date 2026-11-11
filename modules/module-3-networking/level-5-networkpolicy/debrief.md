## What was broken

`ledger-api` was protected by `default-deny-ingress` and by `allow-frontend`, which was meant to let the storefront in. The allow rule had two errors: it selected source pods labelled `role=frontend`, a label no storefront pod carries, and it allowed port 80 while the ledger listens on 8080.

## The evidence

`kubectl describe networkpolicy` printed the rule's "From" selector and "To Port". `kubectl get pods --show-labels` showed `app=storefront,tier=web` on the clients, and the Deployment spec showed `containerPort: 8080`. Requests hung instead of being refused, which is the signature of a dropped packet rather than a closed port.

## Why Kubernetes behaves this way

NetworkPolicies are additive allow lists. Once a policy selects a pod for Ingress, everything not allowed by some policy is dropped. A rule needs both a matching peer and a matching port, and the port is the destination pod's port after the Service has translated it.

## The fix

Make the peer selector match the storefront pods and the port match 8080. Deleting the policies would also make the first check pass, but it would open `ledger-api` to `report-batch`, which is exactly what the security team asked to prevent.

## In production

Label workloads with a stable `app.kubernetes.io/name` and write policy peers against those labels. Test a policy from both an allowed and a forbidden pod.

## Commands worth remembering

- `kubectl describe networkpolicy`
- `kubectl get pods --show-labels`
- `kubectl exec <pod> -- curl -s --max-time 3 http://<svc>:<port>`
