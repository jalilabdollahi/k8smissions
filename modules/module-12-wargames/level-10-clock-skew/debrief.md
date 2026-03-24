# Time Drift

## What Happened
A cluster node's clock drifted 10 minutes from actual time. JWT tokens include iat (issued at) and exp (expiry) timestamps. When the node's clock is 10 minutes ahead, tokens appear expired before they actually are, causing authentication failures.

## The Fix (real clusters)
```bash
# On the affected node
sudo systemctl restart systemd-timesyncd
# or
sudo ntpdate pool.ntp.org

# Verify sync
timedatectl status
```

## Key Lessons
- **NTP sync is critical for Kubernetes** — ETCD, JWT validation, and TLS all depend on accurate clocks
- **Node conditions** — check `kubectl describe node` for clock-related conditions
- **Maximum skew tolerance** — Kubernetes tolerates up to 5 minutes of clock drift
- **Cloud providers** handle NTP automatically — on bare metal you must configure it
