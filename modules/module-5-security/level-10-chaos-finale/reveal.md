## What went wrong

Six independent misconfigurations combined to take down the entire system:
1. Quota too restrictive: `requests.cpu: "1"` in the quota but pods each request 1 CPU with 3 replicas
2. Security violation: `runAsUser: 0` rejected by the namespace's restricted policy
3. Missing RBAC: `app-sa` has no Role or RoleBinding
4. Network blackout: `deny-all` NetworkPolicy with no ingress/egress rules
5. Impossible PDB: `minAvailable: 5` with only 2 replicas

## Fix

Fix each resource in order:

```yaml
# 1. Expand quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: chaos-quota
  namespace: k8smissions
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "2Gi"
    pods: "10"
---
# 2. Fix securityContext and reduce CPU requests in Deployment
# spec.replicas: 2  (fits quota: 2 × 200m = 400m < 2000m)
# containers[0].resources.requests.cpu: "200m"
# containers[0].securityContext:
#   runAsNonRoot: true
#   runAsUser: 1000
#   allowPrivilegeEscalation: false
#   capabilities:
#     drop: [ALL]
---
# 3. Add RBAC for app-sa
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: k8smissions
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-binding
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-role
subjects:
- kind: ServiceAccount
  name: app-sa
---
# 4. Replace deny-all with allow policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app
  namespace: k8smissions
spec:
  podSelector:
    matchLabels:
      app: chaos
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - port: 53
      protocol: UDP
---
# 5. Fix PDB
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: chaos-pdb
  namespace: k8smissions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: chaos
```

## Why this matters

Real incidents are rarely single-cause. Compound failures compound each other: quota violations hide security violations, networking failures mask RBAC errors. The diagnostic discipline — enumerate all failures before fixing any one — prevents the fix for problem A from masking problem B. Triage order matters: fix scheduling blockers (quota, security) first so pods can start, then fix runtime issues (RBAC, network).