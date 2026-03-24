# Sudden Eviction

## What Was Broken
A NoExecute taint was added to the node during a maintenance drain. Pods without matching tolerations were immediately evicted — no graceful shutdown window.

## The Fix
Add a toleration with tolerationSeconds: 300 to give the pod 5 minutes to finish in-flight requests before being evicted.

## Why It Matters
Two taint effects: NoSchedule prevents new pods. NoExecute evicts existing pods. For maintenance drains, prefer Kubernetes node drain (kubectl drain) which respects PodDisruptionBudgets.

## Pro Tip
System pods like kube-proxy have built-in tolerations for node conditions: node.kubernetes.io/not-ready:NoExecute and node.kubernetes.io/unreachable:NoExecute with tolerationSeconds:300.

## Concepts
taints, NoExecute, tolerationSeconds, eviction, node maintenance
