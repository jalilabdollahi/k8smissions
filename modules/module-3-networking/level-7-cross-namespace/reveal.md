Two independent faults, one after the other: the short name does not resolve across namespaces, and the warehouse policy admits only namespaces labelled `team=storefront`.

1. `kubectl -n k8smissions set env deployment/storefront INVENTORY_URL=http://inventory.warehouse.svc.cluster.local:8080` makes the name resolve (an ExternalName Service called `inventory` in `k8smissions` works too).
2. `kubectl -n warehouse describe networkpolicy` shows the `namespaceSelector` `team=storefront`; `kubectl label namespace k8smissions team=storefront` satisfies it.
3. Other namespaces stay blocked, so the warehouse isolation is kept.
