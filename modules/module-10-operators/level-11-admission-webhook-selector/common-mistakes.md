## Deleting the webhook

The server pod comes back, and so does everything in `shop`, but nothing is labelled anymore: the whole point of `pod-labeler` is lost, and the validator's `shop` check fails. Fix the scope, do not remove the guard.

## Setting failurePolicy: Ignore

This also unblocks the server, because a webhook that cannot be reached is skipped. But the mutation then silently disappears every time the server is down, and the level requires the webhook to keep failing closed.

## Replacing the selector instead of extending it

Overwriting `namespaceSelector` with only the exclusion makes the webhook match every namespace, `kube-system` included. Keep `matchLabels: {k8smissions/lab: "true"}` and add the `matchExpressions` beside it.
