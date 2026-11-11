**Removing `onError: continue` from `test`.** The Task now fails and `deploy` is skipped, but the `report` step is skipped too, so the archived summary of exactly the runs that need one disappears. The flag is fine where a later step must run.

**Printing a failure message in `report` without exiting.** `echo "tests failed"` is not a failure: the step exits 0 and the Task stays green. The exit code of the step is what Tekton looks at.

**Reading the PipelineRun colour only.** The seeded run was green, which proves nothing; what counts is the status of the step and of the Task. Check `status.steps` and run the suite that is known to fail.
