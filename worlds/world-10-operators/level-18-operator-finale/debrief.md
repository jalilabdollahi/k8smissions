# Operator Meltdown

## What Was Broken
Three simultaneous failures: (1) webhook with failurePolicy: Fail and no namespaceSelector blocked system pod creation, (2) CRD v1 version was missing while v1 objects were stored in etcd, (3) operator with 2 replicas and no leader election caused split-brain.

## The Fix
Fix each independently: change webhook to Ignore with namespaceSelector, add v1 back to CRD as non-storage version, enable leader election.

## Why It Matters
Production operators: webhooks must have failurePolicy: Ignore or bulletproof service reliability, CRD versions must be migrated carefully before removal, replicated operators must always use leader election.

## Pro Tip
Incident command: triage in order of blast radius. Webhook blocking all pod creation is the highest priority (everything is broken). CRD version issues affect only that resource type. Operator split-brain is bad but usually recoverable with operator restart.

## Concepts
webhook failurePolicy, CRD versioning, leader election, operator meltdown, incident triage
