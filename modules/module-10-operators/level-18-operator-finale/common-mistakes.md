## Stopping after the first fix

Once the certificate is right the Job succeeds and `orders` exists, which feels like the end. But the operator has two leaders and `orders` has no dead-letter queue. The validator checks each fault and the final outcome.

## Fixing the schema and not rewriting `orders`

Adding `deadLetter` to the CRD does not bring back a value that was pruned when the object was stored. The stored `orders` has to be written again (re-apply the manifest in `queue-requests`).

## Granting the operator cluster-admin

It fixes the lease 403 and hides the next permission error, but the validator checks that the operator still cannot read secrets or delete nodes. Add the one rule it needs: `leases`.

## Disabling the webhook or setting failurePolicy: Ignore

Queues are admitted again, but a `retentionDays: 90` Queue is no longer rejected. Fix the certificate instead.
