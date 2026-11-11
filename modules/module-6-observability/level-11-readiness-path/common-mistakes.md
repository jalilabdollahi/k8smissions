## Deleting the old pods or restarting the rollout

`kubectl rollout restart` creates new pods with the same probe and they fail the same way. Deleting old pods only reduces your serving capacity while the new revision stays broken.

## Removing the readiness probe

The rollout would finish, but the Deployment then sends traffic to pods the moment they start, and the validator requires an HTTP probe that really returns 200.

## Reading the logs of the pod

nginx here logs nothing for a failed probe, so `kubectl logs` looks clean. The failing check is recorded by the kubelet in the pod's events, not by the application.
