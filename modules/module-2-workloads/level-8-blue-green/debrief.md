## What was broken

Both versions of the shop were running, but Service `shop` selected `app=shop, version=blue`. That label only exists on the blue pods, so the cutover to green had not happened. A natural first attempt, replacing `blue` with `green` in the `version` key, selects nothing: the green pods are labelled `release=green` and have no `version` label.

## The evidence

`get svc -o yaml` showed the selector, `get pods --show-labels` showed the labels each Deployment stamps on its pods, and `get endpoints` showed three IPs that were the blue pods. Reading the three outputs side by side gives the answer.

## Why Kubernetes behaves this way

A Service has no knowledge of Deployments; it just selects pods whose labels are a superset of its selector. Blue-green with plain Services is therefore a label switch: change the selector and the endpoints controller swaps the backend set within a second or two, with no pod restarted.

## The fix

Patch the selector to `release: green` and null out `version`. A merge patch keeps keys you do not mention, so leaving `version=blue` in place would still match nothing. Keeping `shop-blue` running means rollback is the same one-line patch in reverse.

## In production

Make the selector key the same on both sides (for example `track: blue|green`) so the switch is a value change, and run smoke tests against the idle colour through its own Service before cutting over. Scale blue down only after the soak period.

## Commands worth remembering

- `kubectl get pods --show-labels`
- `kubectl get endpoints <svc>`
- `kubectl patch service <svc> --type=merge -p '{"spec":{"selector":{"key":null}}}'`
