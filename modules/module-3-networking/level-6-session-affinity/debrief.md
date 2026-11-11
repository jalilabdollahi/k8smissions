## What was broken

`portal` stores login sessions in the memory of each pod. The Service had `sessionAffinity: None`, so requests from the same user were spread across all three pods. A login landed on one pod and the following click on another, which answered "no session".

## The evidence

All pods were Ready and healthy, so nothing failed outright. The pattern did the talking: a request worked about one time in three. Repeating requests with the same cookie, and watching only some succeed, points at a backend choice rather than at the application's logic.

## Why Kubernetes behaves this way

kube-proxy chooses a backend when a new connection is made, with no knowledge of cookies or users. `sessionAffinity: ClientIP` adds a rule keyed by source IP: for the timeout (`sessionAffinityConfig.clientIP.timeoutSeconds`, 10800 by default) every new connection from the same IP goes to the same pod. It works at layer 4, so clients behind one NAT address share a pod.

## The fix

Set `spec.sessionAffinity: ClientIP` on the Service. Reducing to one replica removes the symptom and the capacity.

## In production

Source-IP affinity is a stopgap. The durable fix is to move sessions out of pod memory into a shared store such as Redis or into signed tokens, or to use an Ingress with cookie affinity.

## Commands worth remembering

- `kubectl explain service.spec.sessionAffinityConfig`
- `kubectl get svc <name> -o jsonpath='{.spec.sessionAffinity}'`
- `curl -c jar -b jar` to carry cookies between requests
