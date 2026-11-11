#!/bin/bash
kubectl -n k8smissions describe sa ci-runner | grep -i -A2 secrets
kubectl -n k8smissions get secret ci-git -o jsonpath='{.metadata.annotations}'; echo
kubectl -n k8smissions annotate secret ci-git --overwrite \
  tekton.dev/git-0=http://gitserver.gitops-git.svc.cluster.local:8080
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: build-payments-
spec:
  pipelineRef:
    name: build-payments
  taskRunTemplate:
    serviceAccountName: ci-runner
YAML
