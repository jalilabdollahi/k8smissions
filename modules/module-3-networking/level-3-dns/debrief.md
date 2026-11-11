## What was broken

The Deployment's pod template said `dnsPolicy: None` and gave a `dnsConfig` with only `8.8.8.8`. A pod built that way has exactly that one nameserver and no search domains, so `ledger-db` is looked up on a public resolver that has never heard of it.

## The evidence

`/etc/resolv.conf` inside a `reporter` pod listed `nameserver 8.8.8.8` and no `search default.svc.cluster.local ...` line, while the `probe` pod showed the cluster DNS address and search path. The pods were Running and Ready, so nothing in `get pods` pointed at DNS.

## Why Kubernetes behaves this way

The kubelet writes `resolv.conf` from `dnsPolicy`. `ClusterFirst` (the default) uses cluster DNS and the namespace search list. `Default` copies the node's resolver, which doesn't know cluster names either. `None` ignores both and uses only `dnsConfig`. The DNS fields are part of the pod spec and can't be edited on a live pod, so the fix goes through the Deployment and a rollout.

## The fix

Set `dnsPolicy: ClusterFirst` and remove the `dnsConfig` override. `dnsPolicy: Default` looks like a reset but fails for the same reason.

## In production

If a pod needs extra resolvers or `ndots` tuning, keep `ClusterFirst` and add options through `dnsConfig`; options and searches are merged with the cluster ones.

## Commands worth remembering

- `kubectl exec <pod> -- cat /etc/resolv.conf`
- `kubectl explain pod.spec.dnsConfig`
- `kubectl get pod <pod> -o jsonpath='{.spec.dnsPolicy}'`
