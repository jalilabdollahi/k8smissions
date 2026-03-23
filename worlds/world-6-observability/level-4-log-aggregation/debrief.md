# Logs Across Restarts

## Situation
App crashed and restarted 5 times. Need to see the logs from the PREVIOUS crash, not current instance.

## Successful Fix
kubectl logs <pod> --previous -n k8smissions Identify the crash message (OOM / missing config / etc)

## What To Validate
Player outputs the crash reason from previous logs

## Why It Matters
Review how the fix changed the cluster behavior for Logs Across Restarts.

## Concepts
kubectl logs --previous, --since, --tail, multi-container logs, log rotation, log aggregation tools (Loki, EFK, CloudWatch)
