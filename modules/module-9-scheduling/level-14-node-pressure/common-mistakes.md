## Looking at the nodes

`kubectl describe node` and `kubectl top node` show no pressure, because there is none. This eviction is the kubelet enforcing a per-pod limit, not the node running out of disk.

## Editing the LimitRange and waiting

A LimitRange only acts when a pod is admitted. The existing replicas keep their 50Mi limit and are evicted again, so the change has to be followed by a rollout. It also changes the default for everything else in the namespace.

## Setting only the request

A request of 200Mi with the injected 50Mi limit is rejected or ignored in favour of the limit; the limit is what the kubelet enforces. Raise the limit, and set the request alongside it.
