Two defects stacked on top of each other:

1. Pipeline `ship-api` passes `$(tasks.build.results.image-digest)`, but `build-image` declares a result named `digest`. Tekton refuses a reference to an undeclared result. Change the param to `$(tasks.build.results.digest)`.
2. The push step writes the digest to `/workspace/digest.txt`, which only exists inside the build pod, so the declared result is never filled and `deploy` receives an empty string. Write it to `$(results.digest.path)` instead (`printf '%s' "${out##*@}" > $(results.digest.path)`).
3. Create a new PipelineRun of `ship-api` (old runs keep the old spec). `deploy` now verifies the digest against the registry and reports it as `deployed-digest`.
