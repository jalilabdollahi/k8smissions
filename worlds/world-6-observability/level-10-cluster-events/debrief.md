# The Timeline of Failure

## Situation
A 15-minute production incident happened. Multiple events logged across namespaces. Player must reconstruct the incident timeline from events and logs + write a brief post-mortem.

## Successful Fix
kubectl get events -A --sort-by='.lastTimestamp' | tee timeline.txt Identify root cause event and chain

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for The Timeline of Failure.

## Concepts
Event timeline, incident post-mortem, MTTD (Mean Time to Detect), observability → actionability, SRE principles
