Two independent causes sit in `shop-prod`'s `spec.source`:

1. `path: overlays/dev`: the production Application renders the dev overlay (1 replica, debug, no limits).
2. `kustomize.replicas: [{name: shop, count: 1}]`: an inline override that forces 1 replica on top of any overlay, so correcting the path alone still leaves 1 replica.

Fix both: `kubectl -n argocd patch app shop-prod --type json -p '[{"op":"replace","path":"/spec/source/path","value":"overlays/prod"},{"op":"remove","path":"/spec/source/kustomize"}]'`. With automated sync the change rolls out on its own (a hard refresh speeds it up).
