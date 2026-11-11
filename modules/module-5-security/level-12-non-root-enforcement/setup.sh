#!/bin/bash
# The platform team's admission policy, scoped to this level's namespace only.
NS=${NS:-k8smissions}
kubectl apply -f - <<'YAML'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-run-as-non-root
  labels: {k8smissions/managed: "true"}
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE"]
      resources: ["pods"]
  validations:
  - expression: >-
      (has(object.spec.securityContext) && has(object.spec.securityContext.runAsNonRoot) && object.spec.securityContext.runAsNonRoot) ||
      (object.spec.containers + (has(object.spec.initContainers) ? object.spec.initContainers : [])).all(c,
        has(c.securityContext) && has(c.securityContext.runAsNonRoot) && c.securityContext.runAsNonRoot)
    message: "pods must set runAsNonRoot: true (pod level or on every container)"
    reason: Forbidden
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-run-as-non-root
  labels: {k8smissions/managed: "true"}
spec:
  policyName: require-run-as-non-root
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels: {kubernetes.io/metadata.name: k8smissions}
YAML

# wait until the policy is really enforced before the Deployment is created
for i in $(seq 1 40); do
  if kubectl -n "$NS" run policy-probe --image=busybox:1.36 --dry-run=server -- sleep 1 2>&1 | grep -qi "runAsNonRoot"; then
    exit 0
  fi
  sleep 1
done
echo "admission policy is not active" >&2
exit 1
