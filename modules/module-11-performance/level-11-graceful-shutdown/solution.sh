#!/bin/bash
# SIGTERM never reached the worker (sh is PID 1) and 15s is shorter than the longest clip.
kubectl patch deployment video-transcoder -n k8smissions --type=json -p '[
  {"op":"replace","path":"/spec/template/spec/containers/0/command","value":["python","-u","/app/worker.py"]},
  {"op":"replace","path":"/spec/template/spec/terminationGracePeriodSeconds","value":40}]'
kubectl rollout status deployment/video-transcoder -n k8smissions --timeout=90s
