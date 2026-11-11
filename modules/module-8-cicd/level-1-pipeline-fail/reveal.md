The `generate` and `publish` steps pass the version through `/tmp/version.txt`, but each step is a separate container, so `publish` never sees the file, and the declared `version` result stays empty.

1. Edit Task `build` (`kubectl edit task build`).
2. In `generate`, write the version to `$(results.version.path)` instead of `/tmp/version.txt` (`printf '%s.%s.%s' ... > $(results.version.path)`).
3. In `publish`, read it from `$(results.version.path)`.
4. Start a new PipelineRun of `release-notes`; old runs keep their old Task definition and never turn green. The TaskRun result `version` is now `2.9.42` and `publish` prints it.

A shared path such as `/workspace/version.txt` also lets `publish` read the file, but the result still has to be written for the objective to hold.
