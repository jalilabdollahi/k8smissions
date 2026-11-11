#!/bin/bash
kubectl -n k8smissions get pipelinerun release-2041
kubectl -n k8smissions get pods -l tekton.dev/pipelineRun=release-2041
kubectl -n k8smissions logs -l tekton.dev/pipelineRun=release-2041 --tail=3
kubectl -n k8smissions patch pipelinerun release-2041 --type=merge -p '{"spec":{"status":"Cancelled"}}'
kubectl -n k8smissions patch pipeline release --type=json \
  -p '[{"op":"replace","path":"/spec/tasks/0/params/1/value","value":"$(params.approval-timeout)"}]'
