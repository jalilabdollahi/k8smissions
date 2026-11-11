## What was broken

The manifest for `orders-api` was applied while the teammate's kubectl context pointed at namespace `orders-staging`. The Deployment, Service and ConfigMap were created there. `orders-web` in `k8smissions` was configured to call the bare name `http://orders-api`, which only resolves to a Service in its own namespace.

## The evidence

`kubectl get pods` returned only `orders-web` and the probe pod, with no error: an empty list is not a failure in Kubernetes. The web pod's response body said `upstream error` with a name resolution failure. `kubectl get deploy,svc -A | grep orders` finally showed where the backend had gone.

## Why Kubernetes behaved this way

Almost every object belongs to a namespace, and kubectl silently uses the namespace of the current context (or `default`). Cluster DNS gives a Service `<svc>.<ns>.svc.cluster.local`, and the pod's resolver search path adds only the pod's own namespace to short names. So `orders-api` and `orders-api.orders-staging` are different names for different places.

## The fix

Either call the Service with its namespace in the name, or recreate the backend in the right namespace. When you copy objects you must copy their ConfigMaps and Secrets too, or the pod cannot start.

## In production

Put `-n` in scripts, or use `kubectl config set-context --current --namespace=<ns>` and keep the context name in your prompt. Prefer one app per namespace and cross-namespace calls with explicit names. Staging code pointing at staging is fine; production traffic depending on a staging Service is not.

## Commands worth remembering

- `kubectl get all -A | grep <name>`
- `kubectl config view --minify -o jsonpath='{..namespace}'`
- `kubectl get deploy <name> -n <ns> -o yaml`
