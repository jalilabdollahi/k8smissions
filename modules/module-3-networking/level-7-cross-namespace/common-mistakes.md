## Stopping after the name resolves

`inventory.warehouse` resolving is only half the path. The calls still time out because the policy in `warehouse` drops traffic from a namespace without the right label.

## Deleting the NetworkPolicy in warehouse

`storefront` reports ok, but every namespace, including `contractors`, can now reach the inventory. The warehouse team asked for isolation and the level checks it.

## Matching the policy to a pod label

A `namespaceSelector` looks at namespace labels, not pod labels. Labelling the storefront pods does nothing for a rule that selects namespaces.
