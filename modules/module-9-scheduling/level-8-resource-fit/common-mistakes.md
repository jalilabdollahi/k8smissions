## Scaling down to 2 replicas

The Pending pod disappears and so does a third of the capacity. The premiere needs 3 encoders.

## Setting the request to a token value (for example 1m)

All three replicas schedule, but the scheduler now believes they use nothing, and a busy node can starve them. The check requires the request to stay at least about 40% of the original.

## Trusting `kubectl top node`

It shows usage, and the scheduler does not read usage at all. The numbers that matter are in the Allocated resources section of `kubectl describe node`.
