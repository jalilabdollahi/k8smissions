# API Server Writes Fail

## What Was Broken
etcd hit the 2GB default quota. All write operations (CREATE, UPDATE, PATCH) failed with 'database space exceeded'. The cluster became read-only — no new deployments, config changes, or pod scheduling was possible.

## The Fix
Defragment etcd to reclaim space from compacted revisions, disarm the quota alarm, and raise the quota to prevent recurrence.

## Why It Matters
etcd space management: compaction removes old revisions (run with auto-compaction-retention: 1h), defragmentation reclaims the space freed by compaction (doesn't run automatically, must be scheduled). Both are required for healthy etcd.

## Pro Tip
Monitor etcd space: kubectl exec -n kube-system etcd-master -- etcdctl endpoint status --write-out=table. Alert when DB size > 80% of quota. Schedule regular defrag jobs.

## Concepts
etcd, quota, defragmentation, compaction, mvcc, database space exceeded
