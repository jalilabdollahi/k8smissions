## What was broken

The canary release for `app` was meant to see about 10% of the traffic, but it had two pods next to two stable ones. Both Deployments label their pods `app=app`, and Service `app` selects only that label, so it saw four equal endpoints.

## The evidence

`get endpoints app` showed four addresses, and `get pods --show-labels` showed that two of them carried `track=canary`. A hundred requests through the Service split close to half and half, which is exactly what four equal backends produce.

## Why Kubernetes behaves this way

A Service has no weight field. kube-proxy picks a backend for each new connection from the Ready endpoints, roughly uniformly. The only lever a plain Service gives you for a canary is the pod count on each side, so a 10% canary needs about nine stable pods per canary pod. Note that the share is statistical: a small sample can wander a few points either way.

## The fix

Scale `app-stable` up to 9 and keep `app-canary` at 1, or scale the canary down and the stable side up to whatever ratio you need. Removing the canary gives 0%, which ends the experiment instead of running it.

## In production

Pod-ratio canaries are coarse: 1% needs 99 stable pods. Ingress controllers (canary annotations), a service mesh or Argo Rollouts split by weight, independent of pod count. Keep the ratio in mind when the HPA scales only one side.

## Commands worth remembering

- `kubectl get endpoints <svc>`
- `kubectl get pods --show-labels`
- `kubectl scale deployment <name> --replicas=<n>`
