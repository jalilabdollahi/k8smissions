## Deleting the webhook or setting failurePolicy: Ignore

Pods get created again, and that is exactly the problem: `nginx:latest` slips through the guard. The platform team asked for the guard to stay in force, and the validator checks that a bad pod is still refused.

## Fixing only the first error

Swapping the `caBundle` changes the error from "unknown authority" to "certificate has expired". Run the failing command again after every change and keep going until it succeeds.

## Updating the Secret and not the pod

The server reads `/tls` once at start. Changing what is in the Secret (or the volume's `secretName`) is not enough without a new pod; pointing the Deployment at another Secret restarts it for you, an in-place Secret edit does not.
