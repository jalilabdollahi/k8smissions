## What was broken

`quorum` is a clustered service whose nodes discover each other through the headless Service `quorum`. Its readiness endpoint answers 200 only when the name resolves to at least two other nodes. But a Service publishes DNS records and endpoints only for pods that are Ready. With every pod NotReady the name resolved to nothing, so no pod could ever become Ready.

## The evidence

All pods were Running with sensible logs, yet 0/3 Ready. `nslookup quorum` from another pod returned NXDOMAIN, and the EndpointSlice for `quorum` had no ready endpoints. The probe's 503 body ("waiting for peers: found 0 of 2") closed the loop. Deleting pods changes nothing, because each new pod waits for the same records.

## Why Kubernetes behaves this way

The endpoints controller treats readiness as "safe to receive client traffic" and keeps unready pods out of DNS. Peer discovery is a different need: members must find each other before any of them can serve. `spec.publishNotReadyAddresses: true` is the knob for that case. The `podManagementPolicy: Parallel` in this StatefulSet lets all three start together; with the default `OrderedReady`, pod-1 would not even exist until pod-0 was Ready.

## The fix

Set `publishNotReadyAddresses: true` on the Service. Do not remove the probe: the validator checks that every pod really sees three members, and the app would claim readiness it does not have.

## In production

The flag is meant for discovery Services of databases and consensus systems. Keep client traffic on a second, normal Service so users never reach unready members.

## Commands worth remembering

- `kubectl get endpointslices -l kubernetes.io/service-name=<svc> -o yaml`
- `kubectl exec <pod> -- nslookup <headless-svc>`
- `kubectl explain svc.spec.publishNotReadyAddresses`
