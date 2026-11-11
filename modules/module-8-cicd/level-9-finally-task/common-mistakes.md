**Moving `teardown` to `finally` but keeping `$(tasks.provision.results.name)`.** It looks done and the passing run is clean, but in the failed run `provision` never wrote its result, so the finally Task cannot start: the run hangs in Running and the objects stay. Derive the name from `$(context.pipelineRun.name)`.

**Cleaning only by name and forgetting the old objects.** The new `teardown` only removes the current run's scratch objects. The 14 `scratch-it-07NN` leftovers belong to runs that are long gone, so delete them once by label.

**Making `teardown` fail on missing objects.** If `provision` died before creating the Service, a plain `kubectl delete` exits 1 and the run reports a second failure for the cleanup. Use `--ignore-not-found`.
