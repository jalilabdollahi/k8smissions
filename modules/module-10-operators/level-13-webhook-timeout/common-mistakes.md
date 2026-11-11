## Lowering timeoutSeconds

With `timeoutSeconds: 5` the call to the webhook is cut off after 5 seconds and, since the policy is `Fail`, the API server refuses the pod: the compliant check now fails with `context deadline exceeded`. Latency was never about the timeout value.

## Setting failurePolicy: Ignore

Admission becomes fast because a timed-out webhook is skipped, but the over-quota pod is then admitted, and the validator checks that the quota still bites. It also must keep failing closed.

## Deleting or bypassing the webhook

Without `quota-guard` the pods are quick and the quota is gone. The policy is the product here; only the delay in `asset-inventory` is a bug.
