# Label Not Found

## What Was Broken
The pod used nodeSelector for 'accelerator-type: nvidia-v100' but no node had this label. nodeSelector is a hard constraint — no match means Pending forever.

## The Fix
Remove the nodeSelector or label a node with the required key-value pair.

## Why It Matters
nodeSelector is the simplest scheduling constraint but has no fallback. For workloads that should prefer GPUs but can run without them, use preferredDuringScheduling nodeAffinity.

## Pro Tip
Check all node labels at once: kubectl get nodes -o json | python3 -c "import json,sys; [print(n['metadata']['name'], list(n['metadata']['labels'].keys())) for n in json.load(sys.stdin)['items']]"

## Concepts
nodeSelector, node labels, scheduling constraint, Pending pod, label mismatch
