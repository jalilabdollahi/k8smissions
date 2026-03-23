# Spot Survivor

## What Was Broken
The batch-job Deployment used nodeSelector: node-type: spot — restricting to spot nodes only. When spot nodes were reclaimed, pods couldn't reschedule to on-demand nodes (different taint, wrong nodeSelector).

## The Fix
Remove the nodeSelector or replace with a soft preference (nodeAffinity preferred), and add tolerations for both spot and on-demand node taints.

## Why It Matters
Spot instance survival strategy: use preferredDuringScheduling nodeAffinity for spot (cheaper), fall back to on-demand automatically, tolerate both node types. Use PodDistributionBudget to maintain minimum replicas.

## Pro Tip
Cloud providers label spot nodes: EKS uses node.kubernetes.io/lifecycle=spot, GKE uses cloud.google.com/gke-spot=true. Use these labels in soft affinity rules.

## Concepts
spot instances, tolerations, nodeSelector, fallback scheduling, preemptible nodes
