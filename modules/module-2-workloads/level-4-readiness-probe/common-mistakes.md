## Adding a probe that always succeeds

An `exec: ["true"]` probe, or a TCP probe on the port, passes at once because the port is open from the first second. The pod is Ready immediately and users still get 503. The probe has to test the thing that is slow.

## Adding a liveness probe instead

A failing liveness probe restarts the container, which starts the 20 second warm-up over again. Readiness controls traffic; liveness controls restarts.

## Scaling up the Deployment

More replicas means more cold pods at every restart, not fewer 503s. The problem is routing to pods that are not ready, not a lack of capacity.
