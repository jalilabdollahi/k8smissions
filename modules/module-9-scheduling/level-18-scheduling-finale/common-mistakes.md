## Stopping at the first fix

Labelling the second worker makes the frontend spread out and the first symptom vanishes, but the cart and the agent are still short of a pod. Each Deployment has its own cause. Check every pod with `get pods -o wide` before stopping.

## Tolerating the control plane or dropping rules

Allowing pods on the control-plane node, or deleting the anti-affinity and spread rules, would start every pod and would also remove the guarantees the team relies on. The checks require worker nodes, one cart per node and an even frontend split.

## Deleting `statsd-debug` without looking

It is somebody's capture, with an owner and a note in its annotations. Delete it, but read them first: in a real incident you would tell the owner. Changing the agents to a different hostPort also breaks whatever sends metrics to 8125.
