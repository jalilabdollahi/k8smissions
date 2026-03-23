# Database Needs Identity

## Situation
A database is deployed as a Deployment. On restarts, pod identity and hostname change, breaking replication.

## Successful Fix
Convert to StatefulSet with serviceName and stable hostnames

## What To Validate
kubectl get statefulset, pods have predictable names (db-0, db-1)

## Why It Matters
When to use StatefulSet (databases, Kafka, ZooKeeper, etcd)

## Concepts
StatefulSet vs Deployment, stable network IDs, ordered deploys, headless service, VolumeClaimTemplates
