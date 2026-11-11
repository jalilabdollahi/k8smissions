## What was broken

Three scheduling faults, each hiding behind a different message. `shop-frontend` spread over a `zone` label that only one worker had, with `minDomains: 2`, so after one pod there was never a legal place for the next. `shop-cart` kept itself apart from every pod labelled `app=shop`, which includes the frontend. And a forgotten `statsd-debug` pod held hostPort 8125 on one worker, leaving only one node for two agents.

## The evidence

Frontend events named the topology spread constraint and the nodes that did not match it. Cart events said `didn't match pod anti-affinity rules`, on a node that had no cart pod at all: the pod that matched was a frontend. Agent events said `didn't have free ports for the requested pod ports`, and `kubectl get pods -A -o wide` plus the pod's annotations identified the stray holder. Fixing frontend first changes the cart picture, which is why the faults have to be read one at a time.

## Why Kubernetes behaves this way

Every filter reports on its own, and a pod that fails on one reason is never tested for the others. Spread counts are per topology domain, and a node without the key is not a domain. Anti-affinity matches every pod in scope whatever its purpose. hostPort claims a port on the whole node, so two pods asking for it can never meet there.

## The fix

Label the second worker with its zone, narrow the cart selector to `tier=cart`, and delete the stray pod after checking its owner. Each pod is then placed by the scheduler (the cart edit rolls the Deployment).

## In production

Label nodes through the cloud provider so zones always exist, prefer `kubernetes.io/hostname` or `topology.kubernetes.io/zone` over home-made keys, avoid hostPort in favour of a DaemonSet plus a Service, and put an owner and an expiry on debugging pods.

## Commands worth remembering

- `kubectl get nodes -L zone`
- `kubectl describe pod <pod> | grep -A3 Events`
- `kubectl get pods -A -o wide --show-labels`
