# Common Mistakes — Registry Gone

## ❌ Assuming all pods are affected
Pods already running with cached images continue to work. Only new pod starts fail.

## ❌ Ignoring imagePullPolicy
Always means every pod restart hits the registry — IfNotPresent would have let cached images serve.
