## Rolling the Deployment back

`kubectl rollout undo` restores the `http` port name, so the Service works, but the pods answer with release 4.1. The release was supposed to ship; fix the Service side instead.

## Looking at pod readiness

The pods are Ready because their probe checks the container directly on 8080. Readiness never tests the Service's port lookup, so green pods say nothing about this fault.

## Changing the Service `port` instead of `targetPort`

`port` is what clients dial; `targetPort` is where the pod listens. Changing `port` leaves the broken lookup untouched and breaks every client URL on top.
