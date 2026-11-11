## Common mistakes

- **Waiting for a Pending pod to explain itself.** There is none: the DaemonSet never created a pod for the tainted node. The signal is `DESIRED 2` against three nodes.
- **Removing the taint from the control plane node.** It goes against the cluster's policy for everything else and is restored between levels. Make the workload tolerate it.
- **Using `kubectl label` or a `nodeSelector`.** Selecting the node does not lift the taint; the pod still needs a toleration.
- **Writing a toleration for the wrong key or effect.** It must match the node's taint (check the exact key and `NoSchedule` in `describe node`), or the pod is not created.
