## What was broken

The namespace quota `object-counts` allows 10 pods. `catalog-web` could only get 2 of its 3 pods, because eight Completed pods from the CronJob `price-sync` still existed and counted. Nothing was Pending: the third pod was refused at creation.

## Evidence

`describe quota` shows `count/pods 10 10`. `get pods` does list the Completed pods, but it is easy to read only the Running ones; nothing is Pending. The ReplicaSet events carry `exceeded quota: object-counts, requested: count/pods=1, used: count/pods=10, limited: count/pods=10`.

## Why Kubernetes behaved this way

`count/pods` is an object count: it covers pods in any phase. The older `pods` quota counts only non-terminal pods, so finished Jobs are free there. A Job keeps its finished pods so you can read their logs, and a CronJob keeps `successfulJobsHistoryLimit` Jobs (default 3, here raised to 20) until the controller prunes the oldest. Deleting a Job deletes its pods.

## The fix

Bound the history (`successfulJobsHistoryLimit`, and/or `ttlSecondsAfterFinished` in the job template) so the CronJob cannot fill the namespace again, and clear the existing Jobs for room now. Raising the quota would only move the cliff.

## In production

Choose between `pods` and `count/pods` knowingly, leave headroom for rolling updates (a surge pod needs one more), ship logs elsewhere instead of keeping finished pods for debugging, and watch `kubectl describe quota` in alerts.

## Commands worth remembering

- `kubectl describe quota`
- `kubectl get pods --field-selector=status.phase=Succeeded`
- `kubectl get jobs --sort-by=.status.startTime`
