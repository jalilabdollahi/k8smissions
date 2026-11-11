#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

# the Backup API: no subresources section, so status is an ordinary part of the object
apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.backup.acme.io
spec:
  group: backup.acme.io
  scope: Namespaced
  names: {kind: Backup, plural: backups, singular: backup}
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              target: {type: string}
              retention: {type: string}
          status:
            type: object
            properties:
              phase: {type: string}
              lastSlaCheck: {type: string}
Y
wait_crd backups.backup.acme.io
for row in "orders-db orders" "ledger-db ledger" "audit-db audit"; do
  set -- $row
  kubectl -n "$NS" apply -f - >/dev/null <<Y
apiVersion: backup.acme.io/v1
kind: Backup
metadata: {name: $1}
spec: {target: "$2", retention: 30d}
status: {lastSlaCheck: "2026-01-01T00:00:00Z"}
Y
done
