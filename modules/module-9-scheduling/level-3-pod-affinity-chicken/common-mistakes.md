## Removing the affinity from both Deployments

All five pods become Ready, so it looks fixed, but nothing keeps web next to cache any more. The default spreading puts web pods on the worker that has no cache pod.

## Changing `required` to `preferred` on the web side

Web would then schedule immediately, probably away from the cache, and only be next to it by luck. The side that has to follow must stay a hard rule.

## Scaling down one Deployment to "make room"

Nothing is short of room. The pods are filtered out by the affinity rule, so changing replica counts changes nothing.
