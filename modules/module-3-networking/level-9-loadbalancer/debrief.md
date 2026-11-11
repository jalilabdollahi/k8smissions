## What was broken

`storefront-lb` was a `LoadBalancer` Service with `loadBalancerClass: example.com/internal-lb`. Nothing in this cluster implements that class, so `status.loadBalancer` stayed empty and EXTERNAL-IP showed `<pending>` for three days. The pods and the selector were fine; the Service was waiting for a controller that does not exist.

## The evidence

`kubectl describe svc` listed no events: not a failure, just silence. A real cloud controller (or MetalLB) would log "EnsuringLoadBalancer". The explicit `loadBalancerClass` is the tell that a specific implementation was expected to claim it. Nodes carry no cloud provider ID either, which is why kind never provisions anything.

## Why Kubernetes behaves this way

The `LoadBalancer` type is an extension point: the API server stores the object, and an external controller reconciles it and writes the address into status. Without that controller, nothing ever changes the object. A LoadBalancer Service normally also allocates node ports as the traffic path for the balancer; here `allocateLoadBalancerNodePorts: false` removed even that, so there was no entry point at all.

## The fix

Make it a `NodePort` Service. The API server refuses the type change while `loadBalancerClass` and `allocateLoadBalancerNodePorts` remain, because both are valid only for LoadBalancer, so the patch clears them as it changes the type. Each worker then answers on the node port.

## In production

On a cloud, keep the LoadBalancer type and let the provider do its job. On bare metal install MetalLB or a similar implementation; for a fixed port, set `nodePort` explicitly (see level 2). Never leave a Service pending silently: alert on empty `status.loadBalancer`.

## Commands worth remembering

- `kubectl get svc -o wide`
- `kubectl describe svc <name>`
- `kubectl explain svc.spec.type`
- `kubectl get nodes -o wide` for node InternalIPs
