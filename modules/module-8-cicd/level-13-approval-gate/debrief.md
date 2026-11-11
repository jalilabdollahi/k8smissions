## What was broken

`wait-approval` is a script that polls for a ConfigMap `approval-<run>` and accepts it only when the `by` field is in `release-approvers`. The Pipeline declares an `approval-timeout` param (default 600 seconds), but the PipelineTask handed the Task a literal `0`, which the script reads as "wait forever". Run `release-2041` therefore polled for two days for an approver who no longer works there.

## The evidence

The first log line of the gate pod: `expiry 0s, 0 means never`. `kubectl get pipeline release -o yaml` showed the `approval-timeout` param declared but never referenced. The run was `Running` with one live pod and no one who could ever unblock it.

## Why Tekton behaved this way

A param that is declared but not wired is silently unused: Tekton substitutes only what is referenced. A PipelineRun does not end by itself when a script loops; only its timeout (an hour by default for the pipeline, unless set) or an explicit cancel will. Cancelling is done by setting `spec.status: Cancelled`, which stops the TaskRun pods and records the reason `Cancelled`; deleting the run would also delete the evidence.

## The fix

Cancel the stuck run, pass `$(params.approval-timeout)` to the gate and keep the approver list intact. Changing the list or creating an approval in Maria's name would defeat the gate; the validator proves an approval by an unlisted person is still refused.

## In production

Tekton has no manual approval task, so teams build a gate like this or use a controller. Whatever the mechanism, give every wait an expiry and make cancellation part of the runbook.

## Commands worth remembering

- `kubectl patch pipelinerun NAME --type=merge -p '{"spec":{"status":"Cancelled"}}'`
- `kubectl get pipelinerun NAME -o jsonpath='{.status.conditions[0].reason}'`
- `kubectl logs -l tekton.dev/pipelineRun=NAME --all-containers`
