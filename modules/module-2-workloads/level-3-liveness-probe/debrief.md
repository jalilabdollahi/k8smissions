## What was broken

The `inventory` pods have a liveness probe that starts checking port 8080 after 3 seconds and gives up after one failed attempt. The application needs 15 seconds to load its catalogue before it listens, so the kubelet killed every container before it ever became healthy. It restarted, took 15 seconds again, and was killed again.

## The evidence

`describe pod` showed `Liveness probe failed: ... connection refused` followed by `will be restarted`, with a restart count that kept climbing. `logs --previous` ended in "loading catalogue", never reaching "listening": the app was killed mid-start, not crashing.

## Why Kubernetes behaves this way

A liveness probe means "restart this container if it fails". The kubelet does not know how long your startup takes; it only counts failures from `initialDelaySeconds` onwards. If the probe is stricter than the real start, a healthy app is killed forever.

## The fix

Delay the first check past the startup time, and tolerate a few failures (`initialDelaySeconds: 30`, `failureThreshold: 3`). The probe stays, so a hung application is still restarted. Deleting the probe would make the symptom vanish and remove the safety net.

## In production

Measure real startup time under load, not on a laptop. Slow starters usually deserve a `startupProbe`, which holds liveness back until the app is up (module 6 covers probe design). Keep liveness checks cheap and local; they should not depend on other services.

## Commands worth remembering

- `kubectl describe pod <pod>` (events section)
- `kubectl logs <pod> --previous`
- `kubectl explain pod.spec.containers.livenessProbe`
