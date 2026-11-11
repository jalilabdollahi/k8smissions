## What was broken

`webapp-operator` was healthy and watching the wrong place. Its `WATCH_NAMESPACE` came from a ConfigMap and said `staging`, a namespace that exists and holds no WebApps. A list that returns nothing is not an error, so the operator did exactly nothing and logged nothing.

## The evidence

The silence itself. A controller that is busy logs what it creates; one that logs nothing either has no work or is looking elsewhere. `kubectl get webapps -A` showed where the work was, and the operator's environment (`kubectl get deploy -o yaml`, then the ConfigMap behind `valueFrom`) showed where it was looking.

## Why Kubernetes behaved this way

Environment variables, including those that come from a ConfigMap through `configMapKeyRef`, are resolved when the container is created and are fixed for its life. Editing the ConfigMap changes nothing for running pods (volume-mounted ConfigMaps are different: those files do update, but only an application that re-reads them benefits). The controller side of it is the usual shape of every operator: list the objects in scope, compare with the world, create what is missing, write status. Scope is part of that, and a wrong scope is a silent failure.

## The fix

Correct the value, then restart the pods (`kubectl rollout restart`) so the new environment is read.

## In production

Operators usually log their scope at startup, expose a metric for the objects they watch, and reload configuration on change; check for those before concluding "it is idle". Tools like Reloader or a checksum annotation on the pod template automate the restart after a ConfigMap change.

## Worth remembering

- `kubectl rollout restart deployment/<name>`
- `kubectl exec <pod> -- env` shows what a process really sees
- `kubectl get <crd> -A` finds the work an operator should be doing
