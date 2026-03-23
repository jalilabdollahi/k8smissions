# Custom Resource Request

## What Was Broken
Extended resource names are case-sensitive and must exactly match what the device plugin registered. 'my.company/fpga' != 'company.io/fpga' — no node reported the requested resource.

## The Fix
Find the exact resource name from kubectl describe node and use it verbatim in the pod's resource limits.

## Why It Matters
Extended resources must always be in limits (not requests) and must be whole numbers (no fractions). The scheduler places pods on nodes that have the resource available and the device plugin allocates the actual device.

## Pro Tip
Device plugin resources appear in node status: kubectl get node <name> -o jsonpath='{.status.capacity}'. Look for keys with a domain prefix (not cpu/memory/pods).

## Concepts
extended resources, device plugin, custom resources, resource name, limits
