## Scaling portal to one replica

It makes the sessions consistent and leaves the service with a third of its capacity. The requirement was to keep three replicas.

## Restarting the pods

A restart only wipes the in-memory sessions. The Service still spreads the next login and the next request over different pods.

## Raising the affinity timeout

The timeout only controls how long the pinning lasts. The default is already far longer than the 2-minute session, and without affinity enabled the timeout does nothing.
