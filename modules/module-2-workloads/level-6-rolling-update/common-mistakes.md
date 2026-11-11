## Adding `maxUnavailable` or `maxSurge` to the existing strategy

Those fields only exist under `RollingUpdate`. With `type: Recreate` the API server rejects the patch ("may not be specified when strategy type is Recreate"), so the type itself has to change first.

## Adding more replicas

Eight pods that are all terminated together are down just as long as four. The strategy decides how pods are replaced, not how many there are.

## Testing the fix without a release

The Deployment looks healthy at rest before and after the fix. Only a rollout shows the difference, so trigger one (change an env var or annotation) and watch the pods.
