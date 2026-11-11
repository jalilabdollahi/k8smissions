## What was broken

Service `cart` selected pods with `app=cart` only. The load-test stub that was left running after Tuesday's test carries `app=cart` too (and a different `tier` label), so it joined the Service's endpoints. With four endpoints and round-robin style balancing, roughly every fourth request reached the stub.

## The evidence

Everything looked healthy: both Deployments were fully Ready. The giveaway was `kubectl get endpointslices` listing four addresses for a Service backed by three replicas, and `kubectl get pods --show-labels` showing that the fourth address belonged to a pod with `tier=load`.

## Why Kubernetes behaves this way

A Service has no idea which Deployment a pod belongs to. The endpoints controller simply lists every Ready pod in the namespace whose labels are a superset of `spec.selector`. A selector with one key is a wide net.

## The fix

Add the distinguishing label to the selector (`tier: web`). Deleting the stray Deployment would fix the symptom too, but the next pod that happens to share `app=cart` brings the problem back.

## In production

Give Services a selector with at least two labels (for example `app.kubernetes.io/name` plus `app.kubernetes.io/component`), and keep load-test or canary workloads on their own label values. Review `kubectl get endpointslices` after any deploy that adds pods.

## Commands worth remembering

- `kubectl get endpointslices -l kubernetes.io/service-name=<svc> -o wide`
- `kubectl get pods --show-labels -l <selector>`
- `kubectl get pods -o wide` to match endpoint IPs to pods
