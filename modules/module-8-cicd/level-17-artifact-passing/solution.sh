#!/bin/bash
kubectl -n k8smissions get pipelinerun ship-api-0422 -o jsonpath='{.status.conditions[0].message}'; echo
kubectl -n k8smissions get task build-image -o jsonpath='{.spec.results[*].name}'; echo
kubectl -n k8smissions patch pipeline ship-api --type=json \
  -p '[{"op":"replace","path":"/spec/tasks/1/params/0/value","value":"$(tasks.build.results.digest)"}]'
kubectl -n k8smissions patch task build-image --type=json -p '[
  {"op":"replace","path":"/spec/steps/1/script","value":"#!/busybox/sh\nset -e\nref=registry.k8smissions.svc.cluster.local:5000/ship-api:$(params.tag)\nout=$(crane append --insecure -f /workspace/layer.tar.gz -t \"$ref\")\nprintf \"%s\" \"${out##*@}\" > $(results.digest.path)\necho \"pushed $ref\"\n"}]'
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: ship-api-
spec:
  pipelineRef:
    name: ship-api
YAML
