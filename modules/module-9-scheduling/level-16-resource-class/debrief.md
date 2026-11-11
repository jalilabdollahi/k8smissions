## What was broken

Three things have to match for a DRA allocation, and two did not. The DeviceClass `gpu.example.com` did not exist at all, and once it did, the claim template's own CEL selector looked for the attribute `model` under the domain `gpu.lab.example.com`, while the driver publishes under `gpu.lab.example.net`.

## The evidence

The first event named the missing DeviceClass. After creating it, the pod stayed Pending with an allocation failure and no further detail, so the comparison had to be made by reading the objects: `get resourceslice -o yaml` shows driver `gpu.lab.example.net`, and the template's expression uses a different domain. In CEL, a missing attribute simply makes the selector fail, so it is a silent mismatch.

## Why Kubernetes behaves this way

The scheduler's DynamicResources plugin turns each claim into a search over the published ResourceSlices: a device qualifies only if it satisfies the class selectors and the request selectors. Attributes are namespaced by the driver's domain, so a typo in the domain selects nothing. A ResourceClaimTemplate is immutable and creates a claim per pod when the pod is created, so a fixed template only helps pods created afterwards.

## The fix

Create the class with a selector for the real driver, replace the template with the correct attribute domain, and recreate the pod so it gets a fresh claim. The scheduler then allocates a GPU on the node it picks and records it in the claim's `status.allocation`.

## In production

A real driver publishes the slices and the kubelet plugin prepares the device; here there is no plugin, so the pod stays in ContainerCreating after allocation. DeviceClass selectors are how admins hide hardware details: users name a class, not a vendor attribute.

## Commands worth remembering

- `kubectl get deviceclass,resourceslice,resourceclaim -A`
- `kubectl describe resourceclaim <claim>`
- `kubectl explain resourceclaimtemplate.spec.spec.devices.requests`
