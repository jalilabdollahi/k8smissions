## What was broken

`release-checkout` starts a one-pod canary next to the stable Deployment and lets `canary-gate` count 20 answers from the canary through Service `checkout` before it promotes. Run `release-checkout-0914` never finished. Two defects stacked up: the canary pods carried `app: checkout-canary`, a label the Service selector `app: checkout` does not match, and the gate had no time limit.

## The evidence

The gate's log showed `requests=... canary-answers=0` growing forever, so traffic flowed but never reached the canary. `kubectl get endpoints checkout` listed four addresses (stable only), and `kubectl get pods --show-labels` showed the canary with a different `app` label. The PipelineTask had no `timeout`, which is why 50 minutes of nothing was not an error.

## Why Kubernetes and Tekton behaved this way

A Service owns no pods: it follows a label selector, and the Endpoints controller silently ignores everything that does not match. A Task that loops until a condition is true has no opinion on how long is too long; Tekton applies the pipeline default (an hour) unless a Task or the Pipeline sets `timeout`. A timed-out Task fails, `promote` is skipped, and the stable Deployment is untouched.

## The fix

Label the canary pod template so the Service selects it, keeping a label (`track`) that separates it from stable, and give `canary-gate` a timeout shorter than the patience of the people waiting. An unready canary and a mislabelled canary then both end in a clear failure.

## In production

Service-selector canaries mix traffic by replica count; real canaries use a mesh or Argo Rollouts for exact percentages and metric analysis. The pipeline logic (a gate that can fail, a timeout, a promote that only follows success) stays the same.

## Commands worth remembering

- `kubectl get endpoints checkout -o wide`
- `kubectl get pods -l app=checkout --show-labels`
- `kubectl explain pipeline.spec.tasks.timeout`
