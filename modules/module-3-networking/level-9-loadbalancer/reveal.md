1. `kubectl describe svc storefront-lb` shows no events: no controller owns the class `example.com/internal-lb`, and kind has no cloud provider, so `<pending>` will never resolve.
2. Switch the Service to a type the cluster can serve by itself, clearing the two fields that are only valid for LoadBalancer (the API rejects the type change otherwise):

   `kubectl -n k8smissions patch svc storefront-lb -p '{"spec":{"type":"NodePort","loadBalancerClass":null,"allocateLoadBalancerNodePorts":null}}'`

3. `kubectl get svc storefront-lb` now shows a node port; every worker answers on `<node InternalIP>:<that port>`.
