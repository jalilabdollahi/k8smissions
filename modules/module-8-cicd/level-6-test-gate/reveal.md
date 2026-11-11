The `test` step has `onError: continue`, so its failure is swallowed, and `report` only prints the exit code and exits 0. Every run is green, and `deploy` always follows.

1. `kubectl get taskrun <unit-tests run> -o yaml`: step `test` terminated with exit code 1 while the Task is Succeeded.
2. Edit Task `unit-tests`: keep `onError: continue` on `test` (the report must run), and in `report` read the code with `cat $(steps.step-test.exitCode.path)`, print the summary, then `exit "$code"`.
3. A run with `suite=regression` now Fails at `unit-tests`, `deploy` is skipped, and the report is in the log; `suite=smoke` still deploys.
