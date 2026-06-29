## What went wrong

The device plugin advertises `company.io/fpga` as an allocatable resource on each node. The pod requests `my.company/fpga` — a different name. The scheduler searches for nodes with `my.company/fpga` capacity, finds zero, and keeps the pod Pending.

## Fix

```yaml
resources:
  limits:
    company.io/fpga: '1'
```

## Why this matters

Extended resources (also called device plugin resources) follow the format `<vendor-domain>/<resource-name>`. They must:
1. Use a domain prefix with a `/` separator (e.g., `nvidia.com/gpu`, `intel.com/ioatdma`)
2. Be declared under `limits` only (not `requests` — the scheduler treats limits = requests for extended resources)
3. Use whole numbers (no millicores equivalent for GPUs)
4. Match exactly the string registered by the device plugin DaemonSet

Verify available extended resources with `kubectl describe node | grep -v 'kubernetes.io'` to filter out built-in resources.