## What went wrong

Three independent failures:
1. `image: alpine/git:999` — tag doesn't exist, pod enters ErrImagePull
2. `git-url` param has no default — TaskRun fails admission validation if the param isn't supplied
3. `multi-sa` has no RBAC — 403 Forbidden when trying to create TaskRuns

## Fix

```yaml
# Fix 1: valid image tag
steps:
- name: clone
  image: alpine/git:latest
  script: git clone $(params.git-url) /workspace/output
---
# Fix 2: default param value
params:
- name: git-url
  default: https://github.com/example/repo
---
# Fix 3: RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: multi-sa-role
  namespace: k8smissions
rules:
- apiGroups: ["tekton.dev"]
  resources: ["taskruns"]
  verbs: ["create", "get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: multi-sa-rb
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: multi-sa-role
subjects:
- kind: ServiceAccount
  name: multi-sa
  namespace: k8smissions
```

## Why this matters

Production pipeline failures are rarely single-cause. When multiple independent failures stack, they can mask each other — fixing the image pull error reveals the param validation error, fixing that reveals the RBAC error. The diagnostic discipline: collect all failure modes first, then fix in order of what blocks others. Image pull errors block everything; param validation errors block the run before pods start; RBAC errors surface only when the pipeline actually tries to create resources. Fixing in this order minimizes the number of fix-deploy-debug cycles.