#!/bin/bash
kubectl -n k8smissions get pipelinerun notify-prod-9 -o jsonpath='{.status.conditions[0].message}'; echo
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: notify-prod-
spec:
  pipelineRef:
    name: deploy-notify
  params:
  - name: env
    value: prod
  - name: targets
    value:
    - slack-payments
    - pager-oncall
    - email-finance
YAML
