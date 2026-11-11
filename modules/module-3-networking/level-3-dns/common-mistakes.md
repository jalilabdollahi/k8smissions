## Setting dnsPolicy to Default

`Default` is the unlucky name: it makes the pod inherit the node's resolver, which doesn't know `ledger-db` either. The value you want is the one that puts cluster DNS first.

## Editing the pods directly

DNS settings are immutable on a running pod, so `kubectl edit pod` is rejected. Change the Deployment template and let the rollout replace the pods.

## Using the Service's IP address

Hard-coding the ClusterIP makes the symptom go away for a while, but the name is the contract; the IP changes if the Service is recreated.
