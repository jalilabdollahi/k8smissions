1. `kubectl patch pipelinerun release-2041 --type=merge -p '{"spec":{"status":"Cancelled"}}'` stops the run and its pod; the run stays as history.
2. In Pipeline `release`, task `wait-approval` passes the literal `"0"` as `expiry` ("never") instead of the Pipeline param. Change it to `$(params.approval-timeout)`:
   `kubectl patch pipeline release --type=json -p '[{"op":"replace","path":"/spec/tasks/0/params/1/value","value":"$(params.approval-timeout)"}]'`.
3. Leave `release-approvers` alone: adding a name there would be approving the release yourself. A run created with a short `approval-timeout` now fails by itself, and approvals still need a listed approver.
