**What was broken.** The HPA for thumbnailer showed `<unknown>/60%` and never scaled, although the pod was clearly busy. The Deployment runs two containers. `resizer` has `requests.cpu: 100m`, the `log-shipper` sidecar has no resources at all.

**The evidence.** `kubectl describe hpa` carried the real message in its conditions: `ScalingActive False`, reason `FailedGetResourceMetric`, `missing request for cpu in container log-shipper of Pod ...`. `kubectl top pod` working fooled the team into blaming metrics-server. It proves the metrics pipeline works; it says nothing about whether a percentage can be computed.

**Why Kubernetes behaved this way.** For a `Resource` metric with a `Utilization` target, the HPA computes (sum of container usage) / (sum of container requests) across the pod. A container without a request makes the denominator undefined, so the HPA reports unknown rather than guessing. Sidecars you did not write (mesh proxies, log shippers) are the usual way this bites: nobody remembers they are in the pod.

**The fix.** Give every container a CPU request, even a tiny one, so the percentage exists. Alternatively use a `ContainerResource` metric to scale on the main container only, which ignores the sidecar. After the pod template changes, the pods restart and the HPA needs a minute or two before the first sample, which is normal.

**In production.** Enforce requests on every container with a LimitRange default or an admission policy, so the next sidecar does not silently break autoscaling. Also remember that a tiny sidecar request skews the average very little, but a huge one dilutes the signal.

**Worth remembering.**
- `kubectl describe hpa <name>`
- `kubectl get hpa <name> -w`
- `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].resources}'`
