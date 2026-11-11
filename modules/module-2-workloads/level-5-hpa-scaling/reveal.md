1. `kubectl -n k8smissions describe hpa web-backend` shows `FailedGetResourceMetric ... missing request for cpu in container log-forwarder`.
2. For a `Resource` metric the HPA sums usage and requests across all containers in the pod, so one container without a request makes the whole metric unusable. `web` already has a request, `log-forwarder` does not.
3. `kubectl -n k8smissions set resources deployment web-backend -c log-forwarder --requests=cpu=20m` adds it (this rolls out a new pod).
4. After a minute the HPA shows a utilisation well over 50% and raises the replica count.
