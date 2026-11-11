## Scaling only the canary down to one pod

One canary pod beside two stable ones is still 33% of the traffic. The ratio matters, so the stable side has to grow as well.

## Deleting or scaling the canary to zero

The canary then gets 0% of the traffic. That is no longer an experiment, and the check requires the canary to keep serving a small share.

## Changing the Service selector to hide one Deployment

Adding `track=stable` to the selector removes the canary from the Service completely. The goal is a small share, not none; the pod ratio is what sets it.
