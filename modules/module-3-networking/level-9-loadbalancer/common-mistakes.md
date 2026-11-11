## `kubectl edit` and change only `type`

The API server rejects it: `loadBalancerClass may only be used when type is LoadBalancer`, and the same for `allocateLoadBalancerNodePorts`. Clear both fields in the same change.

## Waiting longer or deleting the Service

A pending LoadBalancer on a cluster without a controller stays pending. Deleting and recreating the same YAML gives the same result.

## Using `kubectl port-forward`

It works from your laptop while the command runs, but it is not an entry point for partners and the probe pod cannot use it. The check goes through the node ports.

## Scaling or restarting the pods

The pods are healthy; restarting them does not touch Service status.
