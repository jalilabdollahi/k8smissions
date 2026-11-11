## What was broken

Two things kept three transcoders from getting their cards. The Deployment requested `example.com/fpga`, but the nodes advertise `example.com/fpgas`, so no node could ever satisfy it. After the name was fixed, there were only two free cards: a forgotten bring-up pod, `fpga-smoketest`, held the third one.

## The evidence

The first error is in `describe pod`: `Insufficient example.com/fpga`. The scheduler compares resource names as exact strings, and it counts a name no node has as zero everywhere. Once the name was right, `describe pod` still said `Insufficient example.com/fpgas`, but this time the node had the resource. The difference showed in `kubectl describe node`: `Allocated resources` listed `example.com/fpgas 1 (100%)` on a node whose only workload was the smoke test.

## Why Kubernetes behaves this way

Extended resources are plain integers owned by the device plugin. Kubernetes cannot overcommit them, so requests must equal limits (the API server rejects a Deployment that sets one without the other), and every running pod keeps its units until it is gone, finished or not. A pod sleeping at the end of a test script still counts.

## The fix

Correct the name to `example.com/fpgas` in requests and limits, then remove the stale test pod after checking who owns it. The cards are 2 and 1, so no node can take more pods than it has cards.

## In production

Real device plugins advertise health per device; a pod stuck holding a unit is a common source of "Insufficient nvidia.com/gpu". Label pods with an owner and a TTL, and let Jobs finish instead of sleeping.

## Commands worth remembering

- `kubectl describe node <node> | grep -A10 'Allocated resources'`
- `kubectl get pods -A -o custom-columns='NS:.metadata.namespace,POD:.metadata.name,GPU:.spec.containers[*].resources.requests'`
- `kubectl get nodes -o jsonpath='{.items[*].status.allocatable}'`
