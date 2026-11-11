#!/bin/bash
. ../_fixtures/lib.sh
lab_ns
install_webhook_server
tls_secret quota-guard-tls good

# Registered before the server exists: it only applies to pods labelled guarded=true.
apply_managed <<Y
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: quota-guard
webhooks:
- name: quota.platform.acme.io
  clientConfig:
    service: {name: quota-guard, namespace: $NS, path: /validate, port: 443}
    caBundle: $(cabundle ca-a)
  rules:
  - {apiGroups: [""], apiVersions: [v1], operations: [CREATE], resources: [pods]}
  namespaceSelector:
    matchLabels: {k8smissions/lab: "true"}
  objectSelector:
    matchLabels: {guarded: "true"}
  failurePolicy: Fail
  sideEffects: None
  admissionReviewVersions: [v1]
  timeoutSeconds: 30
Y
