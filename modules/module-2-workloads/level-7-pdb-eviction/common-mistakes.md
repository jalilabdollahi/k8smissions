## Using `--force` or `--disable-eviction`

`--force` only affects pods without a controller; it does not bypass the PDB. `--disable-eviction` does, by deleting pods directly, but then both replicas can vanish at once and the ledger goes down. The point of the budget is to prevent that.

## Deleting the PDB

The drain would pass, and the next drain would happen with no protection at all. The validator requires the PDB to exist and to keep a real budget.

## Forgetting to uncordon

A drain cordons the node. After maintenance (or after a failed drain) run `kubectl uncordon <node>` or the node stays unschedulable.
