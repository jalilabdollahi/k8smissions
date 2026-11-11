## What was broken

Three independent faults stacked on the same request. The webhook's serving certificate had no subject alternative name, so the API server refused to talk to it and every Queue creation failed. The operator's Role lacked `leases`, and its code treated the 403 as "no election needed", so both replicas reconciled. The CRD schema did not declare `spec.deadLetter`, so the dead-letter setting was pruned from every stored Queue.

## The evidence

The `queue-publisher` log quoted `x509: certificate is not valid for any names, but wanted to match queue-webhook.k8smissions.svc`. The operator log said `lease unavailable (403) ... continuing without election`, `kubectl get lease` was empty, and `status.lastWriter` flipped between the two pod names. Finally `kubectl get queue orders -o yaml` showed a spec without `deadLetter` although the manifest had it, and `kubectl explain queue.spec` did not list it.

## Why Kubernetes behaved this way

Go's TLS client, which the API server uses, matches the Service's DNS name against the certificate's SANs only; a certificate with just a Common Name has no names at all. The third fault only appears after the first, because the object has to be admitted before it can be pruned, and pruning is silent for clients that do not ask for strict field validation: kubectl's default `--validate=strict` would have rejected the field, a Job posting JSON does not. The second fault is a design bug in the controller: failing open on an authorization error turns a missing permission into split brain.

## In production

Issue webhook certificates with cert-manager and a SAN for `<svc>.<ns>.svc`. Fail closed in controllers when election is unavailable, and alert on controllers with no lease holder. Review CRD schemas against what clients send (`kubectl apply --validate=strict` in CI). Fix incidents in the order users hit them, and re-test after each fix.

## Worth remembering

- `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>`
- `kubectl explain <kind>.spec`, and `kubectl create --dry-run=server -o yaml` to see what the API server keeps.
- `kubectl get lease -o custom-columns=NAME:.metadata.name,HOLDER:.spec.holderIdentity`
