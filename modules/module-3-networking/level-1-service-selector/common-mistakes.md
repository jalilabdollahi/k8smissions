## Restarting the `cart` pods

The `cart` pods are fine. Restarting them changes nothing, because the wrong response comes from the other Deployment, which the Service still selects.

## Changing the labels on the `cart` Deployment's pods

The Deployment selector is immutable and the pods already match it. Changing the Service selector is a one-line, safe change; touching the workload risks an unwanted rollout.

## Checking one curl and declaring victory

With one wrong pod in four, a single request succeeds about 75% of the time. Use many requests, or look at the endpoint list, before deciding the Service is right.
