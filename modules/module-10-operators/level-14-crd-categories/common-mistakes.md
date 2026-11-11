## Replacing the versions array with a merge patch

`kubectl patch crd --type=merge` with `versions: [...]` replaces the whole list, schema included; with the schema gone the status fields are pruned and the batches lose their state. A JSON patch that adds a single path touches nothing else.

## Pointing a printer column at the wrong path

A column whose `jsonPath` does not exist (`.status.status`) is created and shows an empty cell. Compare each cell with `kubectl get invoicebatch <name> -o yaml`.

## Believing the old output

If your terminal still shows NAME and AGE after the patch, the discovery cache is stale, not the CRD. `kubectl api-resources` refreshes it, or use `--cache-dir=$(mktemp -d)` for a clean view.
