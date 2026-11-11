#!/bin/bash
. ../_fixtures/lib.sh
lab_ns
install_kapi
install_webhook_server

# the certificate the webhook serves today (no subject alternative names) and the platform team's reissue
tls_secret queue-webhook-tls nosan
tls_secret queue-webhook-tls-san good

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: queues.queue.acme.io
spec:
  group: queue.acme.io
  scope: Namespaced
  names: {kind: Queue, plural: queues, singular: queue}
  versions:
  - name: v1
    served: true
    storage: true
    subresources:
      status: {}
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              partitions: {type: integer, minimum: 1, maximum: 64}
              retentionDays: {type: integer, minimum: 1}
          status:
            type: object
            properties:
              phase: {type: string}
              observedGeneration: {type: integer}
              lastWriter: {type: string}
Y
wait_crd queues.queue.acme.io

apply_managed <<Y
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: queue-guard
webhooks:
- name: guard.queue.acme.io
  clientConfig:
    service: {name: queue-webhook, namespace: $NS, path: /validate, port: 443}
    caBundle: $(cabundle ca-a)
  rules:
  - {apiGroups: [queue.acme.io], apiVersions: [v1], operations: [CREATE, UPDATE], resources: [queues]}
  namespaceSelector:
    matchLabels: {k8smissions/lab: "true"}
  failurePolicy: Fail
  sideEffects: None
  admissionReviewVersions: [v1]
  timeoutSeconds: 5
Y
