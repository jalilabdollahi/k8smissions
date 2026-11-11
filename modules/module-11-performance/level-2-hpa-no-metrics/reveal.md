The pod has two containers. `resizer` has a CPU request of 100m but `log-shipper` has none. For a `Resource` metric of type `Utilization` the HPA divides the pod's total usage by the pod's total requests, and refuses when any container lacks a request (`missing request for cpu in container log-shipper`). metrics-server was never the problem.

1. `kubectl describe hpa thumbnailer` shows `FailedGetResourceMetric ... missing request for cpu`.
2. `kubectl set resources deployment/thumbnailer -c log-shipper --requests=cpu=10m,memory=16Mi` gives the sidecar a request.
3. Wait for the rollout; after about a minute the HPA reports a percentage and scales out, because `queue-feeder` keeps the load on.

(Alternative that is also accepted: change the HPA metric to type `ContainerResource` for container `resizer`.)
