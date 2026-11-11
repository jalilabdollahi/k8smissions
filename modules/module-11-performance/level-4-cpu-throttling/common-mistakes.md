**Trusting `kubectl top`.** It shows an average over the last minute or so, well under the limit, so the pods look healthy. Throttling is a per-period effect and only the cgroup counters reveal it.

**Adding replicas.** Every extra pod gets its own 100m limit, so five replicas throttle just as much per request and cost five times the memory. Capacity per pod is what is missing.

**Raising only the request.** Setting `requests.cpu=500m` with the limit still at 100m is not allowed, and raising the request while the limit stays low changes nothing about throttling. The limit is what freezes the container.

**Deleting the whole `resources` block.** Latency recovers, but the pod loses its CPU request: the scheduler no longer reserves anything for it and under contention it gets the smallest share. Keep a request and change the limit.
