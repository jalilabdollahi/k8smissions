## Deleting the pods or the StatefulSet

New pods start NotReady and wait for the same records. Nothing changes until the Service publishes them.

## Removing or loosening the readiness probe

Pods turn Ready, but they do not have their peers, and `/peers` reports fewer than three members. The probe is how the cluster knows the quorum formed; keep it.

## Adding a ClusterIP or pod-specific Services

A Service with a ClusterIP load-balances to Ready pods only and does not give the nodes each other's addresses. The discovery name is already the headless Service; the missing part is which addresses it publishes.
