#!/bin/bash
# the controller's admission webhook must be serving before the Ingress is applied
kubectl -n ingress-nginx wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=180s
