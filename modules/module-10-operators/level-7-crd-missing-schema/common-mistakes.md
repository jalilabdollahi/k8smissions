## A schema with only the fields you care about

Declaring `replicas` and `tier` and nothing else is the natural first draft, and it is a trap: `owner` and `costCenter` are unknown to the schema, so they are pruned. `kubectl get workload search-indexer -o yaml` shows them gone. Declare them, or preserve unknown fields on `spec`.

## Validating only one of the bad values

Fixing `replicas` and forgetting `tier` (or the other way round) leaves the API half open; the checks cover a negative number, a string for a number, and an unknown tier.

## Applying a schema without looking at live objects

The apply succeeds and nothing warns you. The loss only shows when you read the objects again, so make the comparison a habit.
