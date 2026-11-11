kubectl -n k8smissions logs job/queue-publisher --tail=3
kubectl -n k8smissions logs deploy/queue-operator --tail=3
kubectl -n k8smissions get secret
# 1. the webhook serves a certificate without names: switch to the reissued one
kubectl -n k8smissions patch deploy queue-webhook --type=json -p '[{"op":"replace","path":"/spec/template/spec/volumes/2/secret/secretName","value":"queue-webhook-tls-san"}]'
kubectl -n k8smissions rollout status deploy/queue-webhook --timeout=90s
# 2. the operator may not touch leases
kubectl -n k8smissions patch role queue-operator --type=json -p '[{"op":"add","path":"/rules/-","value":{"apiGroups":["coordination.k8s.io"],"resources":["leases"],"verbs":["get","create","update"]}}]'
# 3. the schema drops spec.deadLetter
kubectl patch crd queues.queue.acme.io --type=json -p '[{"op":"add","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/deadLetter","value":{"type":"object","properties":{"enabled":{"type":"boolean"},"maxRetries":{"type":"integer"}}}}]'
# orders was created while the field was dropped: apply the manifest again
kubectl -n k8smissions wait --for=condition=complete job/queue-publisher --timeout=90s
kubectl -n k8smissions get cm queue-requests -o jsonpath='{.data.orders\.json}' | kubectl apply -f -
kubectl -n k8smissions get queue orders -o yaml
