## Common mistakes

- **Running `kubectl edit pod` and changing `command`.** The API server rejects it: container commands are immutable on a running pod. Delete the pod and recreate it.
- **Reading the exit code 0 as success.** The container "succeeded" at running echo. The question is why the program that ended is not the one you wanted.
- **Changing the Service.** The Service selector and port are fine; there is simply no running nginx behind it.
- **Deleting the pod and doing nothing else.** Pods have no controller here, so nothing brings it back. You must apply a manifest again.
