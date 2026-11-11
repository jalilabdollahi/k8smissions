## Installing the CRD and stopping

The first traceback disappears, the pod crashes again with a different one, and `legacy-sync` never gets a status. A CrashLoopBackOff can hide a second cause behind the first, so re-read `--previous` after each change.

## Editing the legacy-sync object so it has options

That gets the three existing Workloads reconciled, but the next Workload without `spec.options` kills the operator again. The validator creates exactly that, so the controller has to tolerate a missing field.

## Waiting for the back-off

Kubernetes waits up to five minutes between restarts of a crashing container. After a fix, `kubectl rollout restart` starts a fresh pod immediately.
