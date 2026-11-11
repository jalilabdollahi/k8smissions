#!/bin/bash
kubectl -n k8smissions logs -l tekton.dev/pipelineRun=ship-payments-0611 --all-containers --tail=3
kubectl -n k8smissions patch pipeline ship-payments --type=json \
  -p '[{"op":"replace","path":"/spec/params/1/default","value":"master"}]'
kubectl -n k8smissions patch pipeline ship-payments --type=json -p '[
  {"op":"replace","path":"/spec/tasks/1/taskSpec/steps/1/script","value":"#!/busybox/sh\nset -e\nref=registry.k8smissions.svc.cluster.local:5000/payments/api:$(params.tag)\nout=$(crane append --insecure -f /workspace/layer.tar.gz -t \"$ref\")\nprintf \"%s\" \"${out##*@}\" > $(results.digest.path)\necho \"pushed $ref\"\n"}]'
kubectl -n payments-prod get rolebinding deploy-sa-payments -o jsonpath='{.subjects}'; echo
kubectl -n payments-prod patch rolebinding deploy-sa-payments --type=json \
  -p '[{"op":"replace","path":"/subjects/0/namespace","value":"k8smissions"}]'
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: ship-payments-
spec:
  pipelineRef:
    name: ship-payments
  taskRunTemplate:
    serviceAccountName: deploy-sa
YAML
