## What was broken

`build-shop` writes `shop.tar` into the workspace `scratch`, sleeps while it prepares the rest of the build, and later checksums the file in a second Task. The CI platform binds all runs to the same PVC `build-scratch`. With three runs at once, each `package` step overwrote the file the others were about to verify, so two of three saw somebody else's archive.

## The evidence

A failing `verify` log shows `archive sha256 A, build recorded B`, two different values within one run. `kubectl get taskrun` shows several TaskRuns active at once with different pods, all mounting `build-scratch`. A lone run passes, which is why the problem only appeared after the team started merging in bursts.

## Why Kubernetes and Tekton behaved this way

A PersistentVolumeClaim is one filesystem, and every TaskRun pod that mounts it sees the same directory tree: Kubernetes does no locking and Tekton does not know the runs are meant to be independent. Isolation has to come from paths. A workspace binding in the Pipeline can set `subPath`, which is applied to the volume mount; with the run name in it, each run gets a private directory inside the shared claim.

## The fix

`subPath: $(context.pipelineRun.name)` on the workspace of both Tasks, so build and verify of one run use the same directory and different runs never meet. The claim, the run YAML and the platform stay untouched.

## In production

`volumeClaimTemplate` gives each run its own claim and is the cleaner design where runs are yours to change. With a shared claim, also think about cleanup of old subdirectories and about ReadWriteOnce pinning concurrent pods to one node.

## Commands worth remembering

- `kubectl explain pipeline.spec.tasks.workspaces.subPath`
- `kubectl get taskrun -l tekton.dev/pipelineRun=NAME -o wide`
- `kubectl get pvc,pv`
