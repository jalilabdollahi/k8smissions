# Common Mistakes — Custom Resource Request

## Mistake 1: Using resource in requests instead of limits

**Wrong approach:** resources: requests: company.io/fpga: 1 — extended resources must be in limits only

**Correct approach:** Extended resources only go in resources.limits, not requests
