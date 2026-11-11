**Cause.** The anti-affinity term uses `labelSelector: {matchLabels: {app: checkout-api}}`, but the pods are labelled `app.kubernetes.io/name: checkout-api`. The selector matches nothing, so the rule never excludes any node and both replicas were free to land together (here: scheduled while the second worker was cordoned). Restarting the pods does not help while the selector is wrong: with nothing to avoid, the scheduler can put them together again.

**Fix.** Select the pods' real label:

    kubectl patch deployment checkout-api -n k8smissions --type=json -p '[{"op":"replace","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution/0/labelSelector","value":{"matchLabels":{"app.kubernetes.io/name":"checkout-api"}}}]'

Changing the template rolls the Deployment, and the new pods are placed one per node. Check with `kubectl get pods -o wide`.
