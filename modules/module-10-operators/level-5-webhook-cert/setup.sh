#!/bin/bash
. ../_fixtures/lib.sh
lab_ns
install_webhook_server

# the certificate the server runs with today, and the one the platform team reissued (key, cert and its CA)
tls_secret policy-guard-tls expired
kubectl -n "$NS" create secret generic policy-guard-tls-reissued \
  --from-file=tls.crt="$FIX/certs/good/tls.crt" --from-file=tls.key="$FIX/certs/good/tls.key" \
  --from-file=ca.crt="$FIX/certs/ca-a/ca.crt" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# the webhook was registered with the CA of the previous platform issuer
apply_managed <<Y
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: policy-guard
webhooks:
- name: guard.policy.acme.io
  clientConfig:
    service: {name: policy-guard, namespace: $NS, path: /validate, port: 443}
    caBundle: $(cabundle ca-b)
  rules:
  - {apiGroups: [""], apiVersions: [v1], operations: [CREATE], resources: [pods]}
  namespaceSelector:
    matchLabels: {k8smissions/lab: "true"}
  objectSelector:
    matchLabels: {guarded: "true"}
  failurePolicy: Fail
  sideEffects: None
  admissionReviewVersions: [v1]
  timeoutSeconds: 5
Y
