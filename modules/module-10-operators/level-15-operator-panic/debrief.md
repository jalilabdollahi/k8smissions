## What was broken

The operator crashed for two unrelated reasons that surfaced one after another. First the release was installed without its CRD (Helm installs `crds/` only on a first `helm install`, and a templated CRD or a skipped hook easily goes missing), so listing `workloads` returned 404 and the code iterated over `None`. Second, once the CRD existed, the workload `legacy-sync` had no `spec.options`, and the code indexed into that missing object.

## The evidence

`kubectl logs --previous` shows the traceback of the crashed container; the current container has often no output yet. `TypeError: 'NoneType' object is not iterable` pointed at the list call; `kubectl get crd` confirmed the type did not exist. After installing the CRD the second traceback, `'NoneType' object is not subscriptable`, appeared when the loop reached `legacy-sync`.

## Why Kubernetes behaved this way

A Deployment restarts a crashing container with exponential back-off up to five minutes, so after a few crashes the operator stays down long after the cause is fixed; `kubectl rollout restart` resets that. The API server also treats custom resources as plain data: a CR may omit any optional field, so a controller must never assume that nested objects exist. Installing a CRD is only half of the fix: the Workloads can be applied only after the CRD is Established.

## In production

Operators must survive bad input: a reconcile that panics on one object blocks every other object. Controller-runtime recovers panics per reconcile, and the CRD schema should carry `default:` values so `spec.options.retries` always exists. Ship CRDs separately from the chart (or with a pre-install check), and keep a startup check that the CRD is present.

## Worth remembering

- `kubectl logs <pod> --previous`
- `kubectl get cm <name> -o jsonpath='{.data.<key>}' | kubectl apply -f -`
- `kubectl wait --for=condition=Established crd/<name>`
