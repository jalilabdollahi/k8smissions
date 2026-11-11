**Debugging metrics-server.** `kubectl top pod` already works, so reinstalling or patching metrics-server (certificates, `--kubelet-insecure-tls`) cannot help and wastes time. When the data exists but the HPA refuses to use it, read the HPA's conditions.

**Looking only at the main container.** `resizer` has a request, so `kubectl get deployment -o yaml` looks correct at a glance. The HPA considers every container in the pod, including the sidecar.

**Setting a fixed replica count.** `kubectl scale deployment thumbnailer --replicas=4` relieves the queue for a while but the autoscaler stays blind, and a later load spike beyond four pods goes unanswered. The objective is a working HPA.

**Expecting an instant result.** After the rollout the HPA needs one or two metric scrapes before it shows a percentage and a further sync period before it scales. Watch with `kubectl get hpa -w` for about a minute before assuming the fix failed.
