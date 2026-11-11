## What was broken

Pipeline `ingest` declares a workspace `source` that its two Tasks share: `fetch` writes three CSV exports into it and `verify` counts them. Run `ingest-2210` bound nothing, so Tekton marked it Failed before starting a pod. The workaround run bound `source` to an `emptyDir`, which satisfied validation but not the Pipeline.

## The evidence

`kubectl describe pipelinerun ingest-2210` carries the validation message in its condition, naming the missing workspace. For the second run, `verify`'s log said no export files were found even though `fetch` had logged three downloads.

## Why Tekton behaved this way

Declared workspaces are required unless marked `optional`, and the check happens when the run is reconciled, hence the immediate failure. Every TaskRun is its own pod. An `emptyDir` lives and dies with one pod, so two Tasks each get a different empty directory. Sharing data between Tasks needs a volume that outlives the pod: a PVC, supplied through `volumeClaimTemplate` (a claim created per run and owned by it) or `persistentVolumeClaim` (an existing claim).

## The fix

Start a new PipelineRun binding `source` to a `volumeClaimTemplate`. Run specs are immutable, so the old run stays failed; nobody edits it.

## In production

`volumeClaimTemplate` is the safe default: the claim is garbage-collected with the PipelineRun. A shared named PVC is for caches and needs care with parallel runs. With ReadWriteOnce claims Tekton keeps the pods of one run on the same node, which only matters on multi-node clusters.

## Commands worth remembering

- `kubectl get pipelinerun <run> -o jsonpath='{.status.conditions[0].message}'`
- `kubectl get pvc` while a run is going
- `kubectl explain pipelinerun.spec.workspaces`
