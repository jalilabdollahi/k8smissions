## What was broken

Two independent faults hid behind one lockdown. The egress default-deny dropped `invoice`'s DNS queries, so `ledger-db` did not even resolve (`bad address`). And once DNS worked, `allow-db` still matched no one: it selected destination pods with `role=db`, while the database pods are labelled `app=ledger-db`, so the connection timed out.

## The evidence

The log line `bad address 'ledger-db'` is a resolver failure, not a refused connection. `kubectl describe networkpolicy` showed that the only egress rule was for `role=db` on 8080, with nothing for port 53. After the lookup was fixed the symptom changed from an instant error to a timeout, the signature of a dropped packet, and `get pods --show-labels` showed the label mismatch.

## Why Kubernetes behaves this way

Egress policies are allow lists too. With `Egress` in `policyTypes`, only listed destinations are reachable, and cluster DNS is just another destination: a pod in `kube-system`. Policy rules match pods, not Service names, and they see the backend pod after the Service has translated its address, so the rule names the database pods' labels and port.

## The fix

Add an allow rule for CoreDNS (namespace and pod label together, UDP and TCP 53), and correct the label in `allow-db`. Both selectors must be in the same `to` entry to be ANDed; separate entries would be ORed and allow every pod in `kube-system`.

## In production

Ship a DNS-egress policy with every egress default-deny, and test it from the pod, not from your laptop. Prefer label selectors over CIDRs, since pod IPs change.

## Commands worth remembering

- `kubectl describe networkpolicy -n <ns>`
- `kubectl exec <pod> -- nslookup <svc>`
- `kubectl get pods --show-labels -n kube-system -l k8s-app=kube-dns`
