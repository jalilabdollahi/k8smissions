# Anti-Affinity Trap

## What Was Broken
Required podAntiAffinity on hostname topologyKey means each pod must run on a unique node. With 3 replicas and 2 nodes, the third pod can never schedule.

## The Fix
Use preferred anti-affinity to spread pods when possible without making it a hard requirement. Only use required when strict pod isolation is a legal/security requirement.

## Why It Matters
requiredDuringScheduling anti-affinity is appropriate for: stateful pods where two instances must never share a node (data corruption risk), compliance requirements. For availability improvement, preferred is sufficient.

## Pro Tip
Check node count: kubectl get nodes | grep Ready | wc -l. Never set required anti-affinity replicas > node count.

## Concepts
podAntiAffinity, requiredDuringScheduling, node count, Pending pod, scheduling constraint
