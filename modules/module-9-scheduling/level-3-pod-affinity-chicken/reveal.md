1. The events say `didn't match pod affinity rules` for both tiers; the Deployments show web requires `tier=cache` pods and cache requires `tier=web` pods on the same node.
2. Required pod affinity is checked against pods that already run, so each side waits for the other forever.
3. Remove the affinity from the cache Deployment; it is the tier that can be placed on its own (its `nodeSelector` already pins it to the cache pool):
   `kubectl -n k8smissions patch deploy reports-cache --type=json -p '[{"op":"remove","path":"/spec/template/spec/affinity"}]'`
4. Cache pods start, the web pods' affinity is satisfied and they land on the same node. Keep the web rule: dropping it from web would let those pods spread onto the other worker.
