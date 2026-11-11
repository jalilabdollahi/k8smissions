## What was broken

Leader election was implemented, but each replica competed for a different Lease: the lease name came from the pod name, so every pod acquired "its" lease immediately and considered itself the leader. Both pods reconciled every `Order`, each rewriting `status.lastWriter` with its own name, and the `claims` counter climbed every time ownership flipped.

## The evidence

`kubectl get lease` showed two healthy-looking leases, each with a holder and a fresh `renewTime`. Only comparing names and holders shows that they are two locks instead of one. The operator logs of both pods said `acquired lease ...` at start and `took over order ...` over and over.

## Why Kubernetes behaved this way

A Lease is just an object with `holderIdentity`, `renewTime` and `leaseDurationSeconds`; Kubernetes does not enforce who may write it. Mutual exclusion comes from every candidate using the same object name and from optimistic concurrency (`resourceVersion`) when taking over an expired lease. Give candidates different names and there is no election at all.

Scaling the operator to one replica would stop the fight, but loses failover; the lease exists precisely so a second replica can take over after `leaseDurationSeconds` when the leader disappears. The validator deletes the leader pod and expects the survivor to serve a new Order.

## In production

controller-runtime sets `LeaderElection: true` with a fixed `LeaderElectionID` per operator and uses the pod name as identity. Choose `leaseDuration`, `renewDeadline` and `retryPeriod` so failover is quick but a short API server hiccup does not cost the leadership. Make reconcile idempotent anyway: leadership can be lost mid-pass.

## Worth remembering

- `kubectl get lease -o custom-columns=NAME:.metadata.name,HOLDER:.spec.holderIdentity,RENEW:.spec.renewTime`
- `kubectl logs <pod> --tail=20` for each replica: only the leader acts.
- `kubectl set env deploy/<name> KEY=value` replaces a downward-API env var with a literal.
