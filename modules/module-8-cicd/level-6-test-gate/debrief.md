## What was broken

Task `unit-tests` runs the suite in step `test`, marked `onError: continue`, and then a `report` step that prints the exit code and the summary. Nothing ever turned that exit code into a failure of the Task, so a red suite produced a green TaskRun and `deploy` ran after it. The run of last night, `ship-ledger-0612`, had the failing `regression` suite and shipped.

## The evidence

The run looked fine at the Pipeline level. Only `kubectl get taskrun -o yaml` showed `status.steps`: step `test` terminated with exit code 1 inside a Succeeded Task, and `kubectl logs -c step-test` listed the two failed tests. The `report` step even printed "test step exit code: 1".

## Why Tekton behaved this way

A TaskRun fails when a step fails, unless that step has `onError: continue`; then Tekton records the exit code under `/tekton/steps/<step>/exitCode` (available as `$(steps.step-NAME.exitCode.path)`) and moves on. The flag is meant for steps whose failure is a fact to report. A Pipeline task fails when its TaskRun fails, and tasks that `runAfter` a failed task are not started, so the gate only works if the Task really fails.

## The fix

Keep `onError: continue` on `test` so `report` still runs, then end `report` with `exit` and the recorded code. The report is archived, the Task fails, `deploy` is skipped.

## In production

Archive test reports from a `finally` task as well, so that infrastructure failures are reported too. Write the gate as an explicit line (`exit "$code"`), not as a side effect. A deploy that must never follow red tests deserves a validation run with a known-failing suite.

## Commands worth remembering

- `kubectl get taskrun <name> -o jsonpath='{.status.steps[*].terminated.exitCode}'`
- `kubectl get pipelinerun <name> -o jsonpath='{.status.skippedTasks}'`
- `kubectl explain task.spec.steps.onError`
