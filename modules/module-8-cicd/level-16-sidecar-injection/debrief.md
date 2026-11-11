## What was broken

The test step slept a fixed five seconds, then asked the sidecar `mock-db` for its rows once. The sidecar loads its fixtures for a variable time before it listens. When it won the race the run passed, when it lost the step got `connection refused` and the run failed; on a busy node it always lost.

## The evidence

In a failed pod, the step log showed the refused connection at about 5 seconds, while the sidecar log (`kubectl logs POD -c sidecar-mock-db`) printed `listening on 8080` several seconds later. The passing runs were the ones where that line came first.

## Why Tekton behaved this way

All containers of a TaskRun pod, steps and sidecars alike, start at the same time. Tekton runs steps in order but treats sidecars as background helpers: the first step does not wait for them, and it is not gated on their readiness. A fixed `sleep` is therefore a bet on startup time, and bets lose under load. An unbounded wait is the opposite mistake: a loop with no deadline turns a dead dependency into a run that sits in Running until the pipeline's one hour default.

## The fix

Poll until the database answers, with a deadline that is generous for a slow start and short enough to fail clearly: a counter or `date` check in the script, and optionally a `timeout` on the step or Task as a second guard.

## In production

Real sidecars (proxies, databases) often offer readiness endpoints; use them in the retry. Prefer one shared retry helper over per-Task copies, and set Task `timeout` so a stuck dependency is a red run, not a blocked queue.

## Commands worth remembering

- `kubectl logs POD -c sidecar-mock-db`
- `kubectl get taskrun NAME -o jsonpath='{.status.sidecars}'`
- `kubectl explain task.spec.sidecars`
