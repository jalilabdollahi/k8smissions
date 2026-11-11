## What was broken

Task `dispatch` runs `kubectl` as ServiceAccount `dispatcher` to start a child PipelineRun and wait for it. The ServiceAccount had no Role bound to it, so the first call was refused with a 403. Granting only the obvious verb moves the failure one line down: `kubectl wait` also needs to read the run.

## The evidence

The step log read `pipelineruns.tekton.dev is forbidden: User "system:serviceaccount:k8smissions:dispatcher" cannot create resource ...`, and after the first fix a second error for `get` (or `list`/`watch`) on the same resource. `kubectl auth can-i ... --as=system:serviceaccount:...` reproduces each answer without running the pipeline.

## Why Kubernetes behaved this way

RBAC is additive and starts from nothing. Tekton objects are custom resources in the `tekton.dev` API group, so rules must name that group (the empty core group does not cover them) and the plural resource name. `kubectl wait` is a client-side loop: it GETs the object and then watches it with a list-and-watch request, so `create` alone is not enough.

## The fix

A Role in `k8smissions` with `create`, `get`, `list`, `watch` on `pipelineruns.tekton.dev`, bound to the ServiceAccount. That is the whole job. Wildcards on `tekton.dev`, a ClusterRole or `cluster-admin` would pass the run but let the nightly job delete pipelines or run arbitrary TaskRuns.

## In production

Scope orchestration accounts to the namespace and the resource they need; if the child runs belong to another namespace, bind there instead. Review `can-i --list` for the account after changes.

## Commands worth remembering

- `kubectl auth can-i --list --as=system:serviceaccount:NS:SA -n NS`
- `kubectl create role NAME --verb=... --resource=...`
- `kubectl api-resources --api-group=tekton.dev`
