## What was broken

Pipeline `inventory-build` declares a workspace `cache` and every run binds it to the claim `build-cache`. But the `compile` task in the Pipeline never maps it to the Task's `cache` workspace, and Task `compile` marks that workspace `optional: true`, so Tekton accepted the run and simply left it unbound. On top of that, the `resolve` step keeps its dependency directory under `$HOME`.

## The evidence

`kubectl logs <pod> -c step-resolve` printed `cache workspace bound: false` and `cache miss` on every run, including the seeded one that was started with the claim. `kubectl get pvc build-cache` showed a healthy but empty volume.

## Why Tekton behaved this way

Workspaces are wired in two layers: the run binds a volume to a Pipeline workspace, and the Pipeline maps its workspaces onto each Task's. A required Task workspace left unmapped is a validation error; an optional one is not, which makes "forgot to map it" invisible. Even when mapped, only paths under the workspace are on the claim: `$HOME` belongs to the container filesystem or to the pod's own volumes, and is gone when the pod is.

## The fix

Add the mapping in the Pipeline and write the cache below `$(workspaces.cache.path)` in the Task. The step can use `$(workspaces.cache.bound)` to behave sensibly without a cache.

## In production

A shared ReadWriteOnce cache serialises runs on one node, and parallel runs can corrupt it; many teams key the directory by lockfile hash. Treat `optional: true` as a decision to log, not to hide. Measure the effect: the second run's step duration is the proof.

## Commands worth remembering

- `kubectl get taskrun <name> -o jsonpath='{.spec.workspaces}'`
- `kubectl explain pipeline.spec.tasks.workspaces`
- `kubectl get pvc,pod -o wide`
