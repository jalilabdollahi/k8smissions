## What was broken

`ledger-db` needed members with fixed names and DNS names, but it ran as a Deployment. A Deployment's pods are interchangeable cattle: random suffixes, no ordering, a new name after every restart.

## The evidence

`get pods` showed names like `ledger-db-7c9f5d6b8-xk2lp`. The headless Service `ledger-db` existed, but it only listed pod IPs, because a Deployment gives its pods no per-pod DNS names.

## Why Kubernetes behaves this way

A StatefulSet creates pods named `<set>-<ordinal>` and sets each pod's `hostname` and `subdomain`. When `serviceName` points at a headless Service in the same namespace, DNS publishes `<pod>.<service>` for every member. When a member is deleted, its replacement gets the same name, so the DNS name, and any storage claim, follow it.

## The fix

Delete the Deployment (its pods carry the same label as the StatefulSet's and would otherwise sit behind the Service) and apply a StatefulSet named `ledger-db` with `serviceName: ledger-db`. A Deployment and a StatefulSet may share a name because they are different kinds.

## In production

Real databases pair the StatefulSet with `volumeClaimTemplates`, so each member also keeps its disk. Deleting a StatefulSet does not delete those claims. Keep `serviceName` correct from the first apply: it cannot be changed afterwards.

## Commands worth remembering

- `kubectl explain statefulset.spec.serviceName`
- `kubectl rollout status statefulset/<name>`
- `kubectl exec <pod> -- nslookup <pod>.<service>`
