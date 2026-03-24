# Common Mistakes — The Noisy Neighbour

## Mistake 1: Deleting the LimitRange

**Wrong approach:** Removing the LimitRange to make the pod work — the policy exists for a reason

**Correct approach:** Fix the pod to comply with the policy

## Mistake 2: Setting limits lower than requests

**Wrong approach:** limits.cpu: 50m when requests.cpu: 100m — limits must be >= requests

**Correct approach:** Limits are the ceiling, requests are the reservation. Always limits >= requests
