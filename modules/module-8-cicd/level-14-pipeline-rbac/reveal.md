`dispatcher` has no permissions at all. The Task needs `create` on `pipelineruns` in API group `tekton.dev` to start the child, and `get`, `list` and `watch` on the same resource for `kubectl wait`.

1. `kubectl create role pipelinerun-dispatch --verb=create,get,list,watch --resource=pipelineruns.tekton.dev`
2. `kubectl create rolebinding dispatcher-pipelinerun-dispatch --role=pipelinerun-dispatch --serviceaccount=k8smissions:dispatcher`
3. A new run of `orchestrate` (SA `dispatcher`) now creates `reindex-<run>` and waits for it; `cluster-admin` or `tekton.dev/*` would also work and would fail the least-privilege checks.
