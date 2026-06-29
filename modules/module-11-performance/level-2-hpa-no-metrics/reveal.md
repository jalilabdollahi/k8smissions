## What went wrong

Without `behavior.scaleDown`, the HPA uses the default policy: scale down as quickly as needed with no stabilization window. This causes thrashing — the HPA removes all extra replicas the moment metrics drop, only to scale them back up when load returns seconds later. New pod startup latency during each scale-up causes user-visible errors.

## Fix

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
    - type: Percent
      value: 10
      periodSeconds: 60
```

## Why this matters

The `stabilizationWindowSeconds` tells the HPA to look at the maximum desired replica count over the past N seconds and use that as the scale-down target — avoiding immediate drops on transient metric dips. The `policies` list adds rate limiting: in this case, maximum 10% of replicas removed per 60-second window. Scale-up should remain aggressive (fast response to load) while scale-down should be conservative (no saw-tooth). You can configure `behavior.scaleUp` separately to control burst behavior.