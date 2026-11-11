#!/bin/bash
kubectl -n k8smissions get pipelinerun ingest-2210 -o jsonpath='{.status.conditions[0].message}'; echo
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: ingest-
spec:
  pipelineRef:
    name: ingest
  workspaces:
  - name: source
    volumeClaimTemplate:
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Mi
YAML
