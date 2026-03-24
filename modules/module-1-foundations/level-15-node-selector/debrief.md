# Won't Schedule

## Situation
Pod stuck in Pending. It has a nodeSelector requiring disktype=ssd, but no node has that label.

## Successful Fix
Either remove the nodeSelector or add the label to a node: kubectl label node <node> disktype=ssd

## What To Validate
Pod scheduled and Running

## Why It Matters
nodeSelector vs nodeAffinity, taints vs labels, when to constrain scheduling

## Concepts
nodeSelector, node labels, scheduling constraints, affinity vs nodeSelector
