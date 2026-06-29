## What went wrong

Tekton CRDs (PipelineRun, TaskRun, Pipeline, Task) are registered under the `tekton.dev` API group. A Role granting access to `apiGroups: ["apps"]` or `apiGroups: [""]` does not cover them. The EventListener's ServiceAccount has no Role at all, so every attempt to create a PipelineRun is rejected.

## Fix

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tekton-run-role
  namespace: k8smissions
rules:
- apiGroups: ["tekton.dev"]
  resources: ["pipelineruns", "taskruns"]
  verbs: ["create", "get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tekton-run-rb
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: tekton-run-role
subjects:
- kind: ServiceAccount
  name: trigger-sa
  namespace: k8smissions
```

## Why this matters

Custom Resource Definitions register their resources under custom API groups. When writing RBAC for CRDs, always use the CRD's group name — not `apps` or `""`. You can discover API groups with `kubectl api-resources | grep tekton` or `kubectl api-groups`. The EventListener needs create access to PipelineRuns; it also typically needs get/list/watch access to Triggers, TriggerBindings, and TriggerTemplates in the `triggers.tekton.dev` group.