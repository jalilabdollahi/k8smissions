## What went wrong

The etcd quota limit of 2GB is etcd's default and is too small for production clusters. A busy cluster accumulates revisions of every object (ConfigMaps, Secrets, custom resources) until compaction runs. When the quota is exceeded, etcd raises an alarm and refuses all write operations — the cluster becomes read-only.

## Fix

```yaml
data:
  quota-backend-bytes: '8589934592'
  auto-compaction-mode: periodic
  auto-compaction-retention: 1h
```

To defragment etcd after increasing the quota:
```bash
etcdctl defrag --cluster
etcdctl alarm disarm
```

## Why this matters

The Kubernetes documentation recommends 8GB as the maximum safe etcd database size for production clusters. Beyond 8GB, etcd performance degrades significantly. Key mitigation strategies:
1. **Compaction**: `auto-compaction-retention: 1h` removes old revisions older than 1 hour, keeping the database small
2. **Defragmentation**: compaction marks space as free but doesn't shrink the file; `etcdctl defrag` reclaims it
3. **Event TTL**: configure `--event-ttl=1h` on the API server to expire old Events
4. **Monitoring**: alert when etcd database size exceeds 75% of quota