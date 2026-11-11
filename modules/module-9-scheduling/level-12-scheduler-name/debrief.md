## What was broken

The `trainer` pods asked for scheduler `ml-sheduler`. The team's second scheduler runs a profile named `ml-scheduler`. A one-letter typo meant that no scheduler claimed the pods.

## The evidence

No events at all. Normally an unschedulable pod gets a `FailedScheduling` event from `default-scheduler`; that event is written by a scheduler that tried and failed. Here the default scheduler skipped the pods because the name was not its own, and the custom scheduler skipped them for the same reason. Silence is the clue. `kubectl get pod -o yaml | grep schedulerName` against the profile name finds it in seconds.

## Why Kubernetes behaves this way

Every scheduler watches for unscheduled pods but only acts on pods whose `schedulerName` equals one of its profile names (the default is `default-scheduler`). A name nobody serves is not an error to the API server, so the pod stays Pending forever. The field is immutable on a Pod, which is why the fix lives in the Deployment's template and the pods are recreated.

## The fix

Correct the name in the template. The ml-scheduler profile uses `MostAllocated` scoring and disables other scorers, so the four pods land together on one node, which is what proves the right scheduler ran. Pointing the pods back at `default-scheduler` would also start them, but it would spread them and defeat the team's packing.

## In production

Run schedulers with leader election and RBAC like the default one, and put the scheduler name in a shared Helm value so a typo breaks one place. A mutating policy can also default `schedulerName` per namespace.

## Commands worth remembering

- `kubectl get pod <pod> -o jsonpath='{.spec.schedulerName}'`
- `kubectl get events --field-selector reason=Scheduled -o wide`
- `kubectl logs deploy/ml-scheduler`
