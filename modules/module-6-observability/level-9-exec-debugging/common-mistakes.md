## Changing the Service port

The Service already points at the right port, 5678. The server refuses connections on every port of the pod IP, so any `port` or `targetPort` edit gets the same refusal.

## Giving up because `kubectl exec` fails

There is no shell in the image, but that does not make the pod opaque. `kubectl debug` with `--target` adds a second container that shares its network and processes, and you can run any tool from it.

## Debugging from a separate pod

A new pod has its own network namespace: `wget localhost` there tests nothing about quote-api, and `wget <pod-ip>:5678` only repeats the refusal. You need to see the socket from inside the pod's namespace.
