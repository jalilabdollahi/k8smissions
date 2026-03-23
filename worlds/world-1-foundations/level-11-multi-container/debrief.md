# Sidecar Sabotage

## Situation
A Pod has two containers: main app + log-shipper sidecar. The sidecar crashes immediately with exit code 1.

## Successful Fix
Fix the sidecar command so it tails the shared log file

## What To Validate
Both containers Running, restartCount sidecar = 0

## Why It Matters
Multi-container patterns (sidecar, ambassador, adapter), shared emptyDir volumes between containers

## Concepts
multi-container pods, sidecar pattern, shared volumes, container independence
