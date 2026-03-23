# Scheduler Overload

## What Was Broken
Three independent scheduling failures: (1) team-a pod had nodeSelector for non-existent label, (2) team-b Deployment had required anti-affinity impossible with 5 replicas on 2 nodes, (3) team-c pod referenced a non-existent PriorityClass.

## The Fix
Fix each issue independently: remove/fix nodeSelector, relax anti-affinity to preferred, remove missing PriorityClass reference.

## Why It Matters
Production scheduling triaging: for each pending pod, kubectl describe pod, read the Events section for exact reason. The scheduler messages are detailed: 'N nodes didn't match pod affinity rules', 'N nodes had label not found', 'N nodes had insufficient memory'.

## Pro Tip
Automate scheduling issue detection: kubectl get pods --all-namespaces --field-selector=status.phase=Pending -o json | python3 -c 'import json,sys; [print(p["metadata"]["name"]) for p in json.load(sys.stdin)["items"]]'

## Concepts
nodeSelector, podAntiAffinity, PriorityClass, multi-issue, systematic debugging
