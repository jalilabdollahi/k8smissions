## Treating exit code 137 as "out of memory"

Both `cart-cache` and `cart-reporter` end with 137. Only `cart-cache` says `OOMKilled`; the reporter was killed by the kubelet after failed liveness probes. Giving the reporter more memory changes nothing.

## Raising the memory limit on the cache

The LimitRange `cart-limits` caps every container at 128Mi, so the API server refuses a bigger limit and the ReplicaSet reports `FailedCreate`. The cache has to be made smaller instead, and the LimitRange must stay as it is.

## Removing the reporter's liveness probe

The pod stops restarting, but a hung reporter would never be restarted again. Correct the probe so it checks the real port.
