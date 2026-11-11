**Deleting the budgets.** The drain goes through, but the budgets are what keep orders-api from losing all its pods in one maintenance step. The validator checks that both still exist, and that orders-api still keeps at least two of its three pods up.

**Using `--disable-eviction` or `--force` on the drain.** Those flags delete pods without asking the budget, which is the same as having no budget, with a real chance of a customer-facing outage.

**Fixing only orders-api.** The first drain then moves forward and gets stuck again on orders-cache, whose single pod can never be evicted under `minAvailable: 1`. Both budgets need attention, and they need different fixes.

**Relaxing the API budget too far.** `maxUnavailable: 3` or `minAvailable: 0` lets a drain take every API pod at once. The budget must still keep at least two pods serving.
