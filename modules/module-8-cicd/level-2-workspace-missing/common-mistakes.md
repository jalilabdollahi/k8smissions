**Binding `source` to `emptyDir`.** The run starts and `fetch` is green, which looks like success. `verify` runs in a different pod with a different, empty directory and fails. `emptyDir` is fine for scratch space inside one Task, not for passing files between Tasks.

**Trying to edit the failed PipelineRun.** `spec` of a PipelineRun is immutable once it has started. Create a new run (for example with `kubectl create -f`, which gives it a fresh name) instead of patching `ingest-2210`.

**Making the Pipeline workspace optional.** That silences the validation error, but `fetch` and `verify` still have nothing to share, so the run fails later, or passes with `files` = 0.
