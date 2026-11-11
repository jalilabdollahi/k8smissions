#!/bin/bash
kubectl -n k8smissions get pvc build-scratch
kubectl -n k8smissions get taskrun -o custom-columns=NAME:.metadata.name,POD:.status.podName,STATUS:.status.conditions[0].status
kubectl -n k8smissions patch pipeline build-shop --type=json -p '[
  {"op":"add","path":"/spec/tasks/0/workspaces/0/subPath","value":"$(context.pipelineRun.name)"},
  {"op":"add","path":"/spec/tasks/1/workspaces/0/subPath","value":"$(context.pipelineRun.name)"}]'
