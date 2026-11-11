Four acts, in four areas:

1. Security: namespace `checkout` enforces Pod Security `restricted`; the pod template has no `securityContext`, so the ReplicaSet is refused. Add pod-level `runAsNonRoot: true`, `runAsUser: 10001`, `seccompProfile: RuntimeDefault`, and for both containers `allowPrivilegeEscalation: false` and `capabilities.drop: [ALL]`. (Keep the namespace label.)
2. Scheduling: `nodeSelector: pool=genral` matches no node (the label is `pool=general`), and both workers carry the leftover taint `dedicated=batch:NoSchedule`. Fix the selector and remove the taint (`kubectl taint nodes -l pool=general dedicated-`) or tolerate it.
3. Probes: the app needs about 25 s before it listens; the liveness probe (initial delay 5 s, two failures) restarts it every 15 s. Add a `startupProbe` on `/healthz` (period 5 s, failure threshold 12 or more) so liveness only starts after startup.
4. Autoscaling: the HPA looks at memory (which stays flat), allows at most 2 replicas (min = max), and the `log-shipper` sidecar has no CPU request. Switch the metric to CPU utilisation, raise `maxReplicas`, and give `log-shipper` a CPU request so the utilisation can be computed.
