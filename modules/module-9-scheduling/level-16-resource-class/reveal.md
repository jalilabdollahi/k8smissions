## What went wrong

The ResourceClaim references `non-existent-fpga-class` — a ResourceClass that was never created. Without a matching ResourceClass, the DRA controller cannot find a driver to handle the allocation request. The pod stays Pending because its ResourceClaim is unbound.

## Fix

Create the missing ResourceClass:
```yaml
apiVersion: resource.k8s.io/v1alpha2
kind: ResourceClass
metadata:
  name: fpga-class
driverName: fpga.example.com
```

Then update the ResourceClaim to reference it:
```yaml
spec:
  resourceClassName: fpga-class
```

## Why this matters

Dynamic Resource Allocation (DRA) is the next-generation replacement for device plugins (introduced in Kubernetes 1.26). The resource model: `ResourceClass` defines the type of resource and which driver manages it; `ResourceClaim` is a pod's request for a specific instance of that class; the DRA driver allocates and tracks individual device assignments. The three-object chain (ResourceClass → ResourceClaim → Pod) must be complete before the scheduler can place the pod. DRA enables more flexible structured parameters than the simple count-based model of device plugins.