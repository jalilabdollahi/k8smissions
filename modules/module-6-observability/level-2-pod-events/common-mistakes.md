## Describing the Deployment or looking for pod logs

`kubectl describe deploy` only reports replica counts and a ReplicaSet name; the reason sits one level down on the ReplicaSet. And `kubectl logs` cannot help when no container ever ran.

## Switching the Deployment to the default service account

It makes pods appear, but they no longer run under `billing-sa`, which is the identity the billing team's policies refer to. The fix is to provide the account the manifest asks for.

## Giving billing-sa a Role to "make it work"

Missing RBAC and a missing account are different problems. The pods need only the account to exist; the worker calls no API, so granting permissions adds risk for nothing.
