## What was broken

The namespace had a default-deny ingress policy and a strict policy for `payments-db`, yet `batch-exporter` and `debug-shell` could connect. A third policy, `allow-ns-ingress`, left over from an old migration, selected `payments-db` too and admitted every pod in the namespace.

## Evidence

`kubectl get networkpolicy` lists three policies, and `describe` shows which pods each one selects and which sources it allows. Only reading all the policies that select the destination reveals the loose one.

## Why Kubernetes behaved this way

NetworkPolicy has no deny rules and no priority. Once a pod is selected by an ingress policy it is isolated, and the set of allowed sources is the union of the `ingress` rules of every policy that selects it. Adding a stricter policy can never remove access granted by another one; the only way to tighten is to delete or narrow the permissive rule.

## The fix

Delete `allow-ns-ingress` (or edit it to match only `payments-api`). The default-deny policy and the strict policy stay, and `payments-api` reaches the database through DNS and the Service as before.

## In production

Review all policies that select a workload, not just the new one: `kubectl get netpol -o wide` or tools that show the effective policy. Name policies after what they allow, annotate owners, and avoid `podSelector: {}` in `from` for sensitive workloads. Test from real pods, as the auditor did: a policy that looks right in YAML is only proven by a blocked connection.

## Commands worth remembering

- `kubectl get networkpolicy -o wide`
- `kubectl describe networkpolicy <name>`
- `kubectl exec <pod> -- curl -s --max-time 3 http://<service>:<port>`
