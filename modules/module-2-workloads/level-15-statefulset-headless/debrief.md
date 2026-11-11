## What was broken

The StatefulSet `db` declares `serviceName: db-hs`, but no Service with that name existed. There was only Service `db`, a regular ClusterIP Service. The pods were fine and clients could reach them, but the stable per-member names `db-N.db-hs` did not resolve, so `db-monitor` could never become Ready.

## The evidence

`logs deploy/db-monitor` repeated `cannot reach member` for the three names, and `kubectl exec probe -- nslookup db-0.db-hs` found nothing. `get statefulset db -o yaml` showed the `serviceName`, and `get svc` showed no Service of that name.

## Why Kubernetes behaves this way

A StatefulSet sets each pod's `hostname` to its name and its `subdomain` to `serviceName`. The cluster DNS only creates `<hostname>.<subdomain>` records when a headless Service (`clusterIP: None`) with that exact name selects the pod. A ClusterIP Service gives you a single virtual IP and one A record, not one per pod. `serviceName` and a Service's `clusterIP` are both immutable, so the missing piece is added, not edited.

## The fix

Create Service `db-hs` with `clusterIP: None`, a selector of `app=db` and a port. Leave Service `db` alone: it is the client entry point and would stop load-balancing if it became headless.

## In production

Most StatefulSets run two Services: a headless one for member identity and a normal one for client traffic. Create the headless Service first, in the same manifest as the StatefulSet.

## Commands worth remembering

- `kubectl exec <pod> -- nslookup <pod>.<service>`
- `kubectl get svc -o custom-columns=NAME:.metadata.name,IP:.spec.clusterIP`
- `kubectl explain statefulset.spec.serviceName`
