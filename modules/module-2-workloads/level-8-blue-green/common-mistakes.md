## Changing `blue` to `green` in the old key

The green pods have no `version` label, so `version=green` matches nothing and the Service has an empty endpoint list: every request fails. Check `get pods --show-labels` before writing the selector.

## Patching without removing the old key

`kubectl patch` merges maps. Adding `release: green` while `version: blue` stays means a pod must carry both labels, which no pod does. Set the old key to `null` in the same patch.

## Deleting the blue Deployment

Traffic would reach green, but the whole point of blue-green is the instant rollback. The validator requires `shop-blue` to keep its three Ready pods.
