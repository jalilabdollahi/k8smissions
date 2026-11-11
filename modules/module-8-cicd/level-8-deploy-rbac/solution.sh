#!/bin/bash
pod=$(kubectl -n k8smissions get taskrun -l tekton.dev/pipelineRun=release-1182 -o jsonpath='{.items[0].status.podName}')
kubectl -n k8smissions logs "$pod" -c step-apply | tail -3
kubectl auth can-i create deployments.apps -n shop-staging --as=system:serviceaccount:k8smissions:deploy-sa
kubectl -n shop-staging apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: storefront-deployer
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deploy-sa-storefront-deployer
subjects:
- kind: ServiceAccount
  name: deploy-sa
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: storefront-deployer
YAML
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: release-
spec:
  pipelineRef:
    name: release-storefront
  taskRunTemplate:
    serviceAccountName: deploy-sa
YAML
