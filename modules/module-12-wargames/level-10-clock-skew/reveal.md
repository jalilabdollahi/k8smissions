## What went wrong

NTP sync stopped on one node, allowing its clock to drift 600 seconds (10 minutes) ahead. Kubernetes tolerates up to 5 minutes of clock skew (`--node-monitor-grace-period`). At 10 minutes, JWT token validation fails: the `iat` (issued-at) or `exp` (expiry) claims appear invalid because different cluster components disagree on what time it is.

## Fix

On the affected node:
```bash
sudo systemctl restart systemd-timesyncd
# or: sudo ntpdate pool.ntp.org
timedatectl status  # verify sync
```

Then update the ConfigMap:
```yaml
data:
  ntp_sync: 'true'
  skew_seconds: '0'
  status: ok
```

## Why this matters

Distributed systems depend on synchronized clocks for:
- **JWT validation**: `iat`, `exp`, and `nbf` claims are timestamps
- **TLS certificate validation**: cert validity windows use wall clock time
- **Kubernetes lease expiry**: leader election uses time-based lease TTLs
- **Log correlation**: debugging is impossible when logs have inconsistent timestamps

Prevent clock drift:
1. **Monitor skew**: `node_timex_offset_seconds` in Prometheus/node-exporter, alert on `|skew| > 1s`
2. **Ensure NTP/chrony**: confirm `timedatectl status` shows `System clock synchronized: yes` on all nodes
3. **Cloud VMs**: most hypervisors sync guest clocks via VMware tools, Amazon time sync, or GCP metadata — verify these are running