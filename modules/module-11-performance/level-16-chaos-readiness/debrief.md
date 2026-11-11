**What was broken.** `checkout-api` had a pod anti-affinity rule that was syntactically fine and logically empty: its `labelSelector` named `app: checkout-api`, a label no pod carries. Both replicas ran on one node, so losing that node removed all capacity.

**The evidence.** `kubectl get pods -o wide` showed the same NODE for both replicas. `kubectl get pods --show-labels` showed the pods labelled `app.kubernetes.io/name`, and the rule asked for `app`. The earlier "reshuffle" restart changed nothing because there was nothing in the rule for the scheduler to honour.

**Why Kubernetes behaved this way.** Affinity terms are evaluated by the scheduler against the labels of pods that exist on each node; a selector that matches no pod excludes no node. There is no validation that a selector matches anything. The rule also only applies at scheduling time (`...IgnoredDuringExecution`), so existing pods never move on their own; a template change rolls the Deployment and re-schedules them.

**The fix.** Correct the selector to the pods' own label and let the rollout place one replica per node.

**In production.** Prefer `topologySpreadConstraints` for spread (it also handles three or more replicas and zones). Verify placement with a drill like this one, not by reading the manifest, and keep a PodDisruptionBudget for voluntary evictions (module 9 and the PDB level in this module cover it). With `required` anti-affinity and only two nodes, a node loss leaves the replacement Pending, so size for one replica serving at peak or use `preferred` terms.

**Worth remembering.**
- `kubectl get pods -o wide --show-labels`
- `kubectl explain pod.spec.affinity.podAntiAffinity`
- `kubectl cordon <node>` and `kubectl delete pod <pod> --force --grace-period=0` (use only on drill namespaces)
