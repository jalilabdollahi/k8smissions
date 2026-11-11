Three separate faults:

1. **Webhook certificate without names.** `queue-webhook` serves a certificate with no subject alternative name, so the API server refuses it: `x509: certificate is not valid for any names, but wanted to match queue-webhook.k8smissions.svc`. The platform team's reissued certificate is in Secret `queue-webhook-tls-san`; point the Deployment at it (the pod restarts and loads it):

```bash
kubectl -n k8smissions patch deploy queue-webhook --type=json -p '[{"op":"replace","path":"/spec/template/spec/volumes/2/secret/secretName","value":"queue-webhook-tls-san"}]'
```

2. **No permission on leases.** The operator's Role has no rule for `coordination.k8s.io/leases`; the code logs the 403 and falls back to "no election", so both replicas lead and fight over `status.lastWriter`. Add the rule (the pods retry by themselves, no restart needed):

```bash
kubectl -n k8smissions patch role queue-operator --type=json -p '[{"op":"add","path":"/rules/-","value":{"apiGroups":["coordination.k8s.io"],"resources":["leases"],"verbs":["get","create","update"]}}]'
```

3. **Schema drops `spec.deadLetter`.** The CRD does not declare the field, so the API server prunes it from every Queue written, and the operator never sees a dead-letter setting. Add it to the schema, then write `orders` again, since the stored object has lost the field:

```bash
kubectl patch crd queues.queue.acme.io --type=json -p '[{"op":"add","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/deadLetter","value":{"type":"object","properties":{"enabled":{"type":"boolean"},"maxRetries":{"type":"integer"}}}}]'
kubectl -n k8smissions get cm queue-requests -o jsonpath='{.data.orders\.json}' | kubectl apply -f -
```
