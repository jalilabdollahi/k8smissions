The Pipeline needs a workspace `source` shared by `fetch` and `verify`, and the run bound none. The tempting `emptyDir` binding passes admission but each Task has its own pod and its own `emptyDir`, so `verify` finds nothing.

1. `kubectl describe pipelinerun ingest-2210`: "pipeline requires workspace with name source be provided by pipelinerun".
2. Create a new PipelineRun of `ingest` whose `spec.workspaces` binds `source` to a `volumeClaimTemplate` (100Mi, ReadWriteOnce), or to an existing PVC by `claimName`.
3. Wait for it to Succeed; `verify` reports `files` = 3.
